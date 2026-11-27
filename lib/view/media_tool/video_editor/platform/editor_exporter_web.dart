import 'dart:async';
import 'dart:typed_data';

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

import '../../ffmpeg_manager.dart';
import '../../file_utils.dart';
import '../application/export_plan.dart';
import '../domain/video_editor_project.dart';
import 'editor_exporter.dart';

EditorExporter createExporter() => _WebExporter();

class _WebExporter implements EditorExporter {
  bool _cancelled = false;

  @override
  bool get supported => true;

  @override
  void cancel() {
    _cancelled = true;
    _discardCore();
  }

  /// A failed FFmpeg run leaves the wasm runtime dead (later runs throw
  /// "Cannot read properties of null (reading 'apply')"), so drop it and let
  /// the next export load a fresh core.
  void _discardCore() {
    final mgr = FfmpegManager.instance;
    try {
      mgr.ffmpeg?.exit();
    } catch (_) {}
    mgr.reset();
  }

  @override
  bool download(Uint8List bytes, String fileName) =>
      FileUtils.downloadBytesInWeb(bytes, fileName, mimeType: 'video/mp4');

  Future<void> _load(FfmpegManager mgr) {
    if (mgr.isLoaded) return Future.value();
    final done = Completer<void>();
    mgr.loadFFmpeg(
      () {
        if (!done.isCompleted) done.complete();
      },
      setLog: true,
      onFailed: (e) {
        if (!done.isCompleted) done.completeError(e);
      },
    );
    return done.future;
  }

  @override
  Future<ExportOutcome> run(
    ExportRequest request,
    ExportProgress onProgress, {
    ExportLog? onLog,
  }) async {
    _cancelled = false;
    final mgr = FfmpegManager.instance;
    final log = <String>[];
    final fallbacks = <String>[];
    var activeLabel = '';
    var activeStart = 0.0;
    var activeSpan = 0.0;
    double? activeDuration;
    var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
    // The single-thread core terminates its runtime after every command, so
    // each command runs on a freshly loaded core. Files live in this store and
    // are copied in/out around each command.
    final store = <String, Uint8List>{};

    Future<String?> exec(List<String> args) async {
      try {
        _discardCore();
        await _load(mgr);
        final ff = mgr.ffmpeg!;
        ff.setLogger((l) {
          // ignore: avoid_print
          print('[ffmpeg] ${l.message}');
          onLog?.call(l.message);
          log.add(l.message);
          if (log.length > 400) log.removeRange(0, 100);
          final now = DateTime.now();
          if (activeDuration != null &&
              activeDuration > 0 &&
              now.difference(lastProgressAt) >=
                  const Duration(milliseconds: 180)) {
            final rendered = _ffmpegTime(l.message);
            if (rendered != null) {
              final within = (rendered / activeDuration).clamp(0.0, .94);
              onProgress(
                '$activeLabel · ${_clock(rendered)} / '
                '${_clock(activeDuration)}',
                activeStart + activeSpan * within,
              );
              lastProgressAt = now;
            }
          }
        });
        for (final n in _neededFiles(args, store)) {
          ff.writeFile(n, store[n]!);
        }
        String? error;
        final ok = await mgr.runCommand(args, onFailed: (e) => error = e);
        if (!ok) return error ?? 'FFmpeg failed';
        final out = args.last;
        if (out != '-' && out.contains('.')) {
          try {
            store[out] = Uint8List.fromList(ff.readFile(out));
          } catch (e) {
            return 'No output "$out" was produced ($e)';
          }
        }
        return null;
      } catch (e) {
        return e.toString();
      }
    }

    try {
      onProgress('Loading FFmpeg…', 0);

      // Probe which video clips carry an audio stream.
      final hasAudio = <String, bool>{};
      final clips = request.project.clips;
      for (var i = 0; i < clips.length; i++) {
        final c = clips[i];
        if (c.type != EditorAssetType.video) continue;
        final name = sourceName(c, i);
        store[name] = c.bytes;
        log.clear();
        onProgress('Inspecting ${c.name}…', 0);
        await exec(['-i', name, '-frames:v', '1', '-f', 'null', '-']);
        hasAudio[c.id] = log.any((l) => l.contains('Audio:'));
      }
      log.clear();

      final plan = buildExportPlan(ExportRequest(
        project: request.project,
        shortSide: request.shortSide,
        imagePngs: request.imagePngs,
        sequences: request.sequences,
        hasAudio: hasAudio,
        includeMusic: request.includeMusic,
      ));
      store.addAll(plan.inputs);

      final total = plan.steps.length;
      for (var i = 0; i < total; i++) {
        final step = plan.steps[i];
        if (_cancelled) {
          return const ExportOutcome.failure('Export cancelled.', []);
        }
        activeLabel = step.label;
        activeStart = i / total;
        activeSpan = 1 / total;
        activeDuration = _outputDuration(step.args);
        lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
        onProgress(step.label, activeStart);
        var error = await exec(step.args);
        if (error != null && step.fallbackArgs != null && !_cancelled) {
          fallbacks.add(step.label);
          final first = error;
          error = await exec(step.fallbackArgs!);
          if (error != null) error = '$error (first attempt: $first)';
        }
        if (_cancelled) {
          return const ExportOutcome.failure('Export cancelled.', []);
        }
        if (error != null) {
          _discardCore();
          return ExportOutcome.failure(
              'FFmpeg failed at "${step.label}": $error',
              log.length > 40 ? log.sublist(log.length - 40) : List.of(log),
              plan.warnings);
        }
      }
      onProgress('Reading result…', .98);
      final bytes = store[plan.output];
      _discardCore();
      if (bytes == null || bytes.isEmpty) {
        return ExportOutcome.failure('The exported file is empty.', log);
      }
      onProgress('Done', 1);
      return ExportOutcome.success(bytes, [
        ...plan.warnings,
        for (final label in fallbacks)
          '"$label" failed with its colour grade, so it was rendered '
              'without the filter.',
      ]);
    } catch (e) {
      _discardCore();
      return ExportOutcome.failure(
          e.toString(), log.length > 14 ? log.sublist(log.length - 14) : log);
    }
  }

  double? _outputDuration(List<String> args) {
    for (var i = args.length - 2; i >= 0; i--) {
      if (args[i] == '-t') return double.tryParse(args[i + 1]);
    }
    return null;
  }

  double? _ffmpegTime(String line) {
    final match = RegExp(r'time=(\d+):(\d+):(\d+(?:\.\d+)?)').firstMatch(line);
    if (match == null) return null;
    return int.parse(match.group(1)!) * 3600 +
        int.parse(match.group(2)!) * 60 +
        double.parse(match.group(3)!);
  }

  String _clock(double seconds) {
    final whole = seconds.floor();
    final minutes = whole ~/ 60;
    final rest = whole % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  /// Files from [store] a command reads: exact names, `%04d` sequences, and
  /// files listed in a concat list.
  List<String> _neededFiles(List<String> args, Map<String, Uint8List> store) {
    final needed = <String>{};
    for (final a in args) {
      if (a.contains('.cube')) {
        needed.addAll(
            store.keys.where((k) => k.endsWith('.cube') && a.contains(k)));
      }
      if (store.containsKey(a)) {
        needed.add(a);
        if (a.endsWith('.txt')) {
          final text = String.fromCharCodes(store[a]!);
          for (final m in RegExp(r"file '([^']+)'").allMatches(text)) {
            if (store.containsKey(m.group(1))) needed.add(m.group(1)!);
          }
        }
      } else if (a.contains('%0')) {
        final m = RegExp(r'%0(\d+)d').firstMatch(a);
        if (m == null) continue;
        final re = RegExp(
            '^${RegExp.escape(a.substring(0, m.start))}\\d{${m.group(1)}}'
            '${RegExp.escape(a.substring(m.end))}\$');
        needed.addAll(store.keys.where(re.hasMatch));
      }
    }
    return needed.toList();
  }
}
