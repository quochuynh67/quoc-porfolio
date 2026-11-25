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
    final written = <String>{};
    try {
      onProgress('Loading FFmpeg…', 0);
      await _load(mgr);
      final ff = mgr.ffmpeg!;
      ff.setLogger((l) {
        onLog?.call(l.message);
        log.add(l.message);
        if (log.length > 400) log.removeRange(0, 100);
      });

      // Probe which video clips carry an audio stream.
      final hasAudio = <String, bool>{};
      final clips = request.project.clips;
      for (var i = 0; i < clips.length; i++) {
        final c = clips[i];
        if (c.type != EditorAssetType.video) continue;
        final name = sourceName(c, i);
        ff.writeFile(name, c.bytes);
        written.add(name);
        log.clear();
        onProgress('Inspecting ${c.name}…', 0);
        await mgr.runCommand(['-i', name, '-frames:v', '1', '-f', 'null', '-']);
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
      for (final e in plan.inputs.entries) {
        ff.writeFile(e.key, e.value);
        written.add(e.key);
      }

      final total = plan.steps.length;
      for (var i = 0; i < total; i++) {
        final step = plan.steps[i];
        if (_cancelled) {
          return const ExportOutcome.failure('Export cancelled.', []);
        }
        onProgress(step.label, i / total);
        var ok = await mgr.runCommand(step.args);
        if (!ok && step.fallbackArgs != null) {
          ok = await mgr.runCommand(step.fallbackArgs!);
        }
        if (_cancelled) {
          return const ExportOutcome.failure('Export cancelled.', []);
        }
        if (!ok) {
          return ExportOutcome.failure(
              'FFmpeg failed at "${step.label}".',
              log.length > 14 ? log.sublist(log.length - 14) : log,
              plan.warnings);
        }
        // Track generated files so they can be freed afterwards.
        for (final a in step.args) {
          if (a.endsWith('.mp4') || a.endsWith('.png')) written.add(a);
        }
      }
      onProgress('Reading result…', .98);
      final bytes = Uint8List.fromList(ff.readFile(plan.output));
      if (bytes.isEmpty) {
        return ExportOutcome.failure('The exported file is empty.', log);
      }
      for (final f in written) {
        if (f == plan.output) continue;
        try {
          ff.unlink(f);
        } catch (_) {}
      }
      try {
        ff.unlink(plan.output);
      } catch (_) {}
      onProgress('Done', 1);
      return ExportOutcome.success(bytes, plan.warnings);
    } catch (e) {
      return ExportOutcome.failure(
          e.toString(), log.length > 14 ? log.sublist(log.length - 14) : log);
    }
  }
}
