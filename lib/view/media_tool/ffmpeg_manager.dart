import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:js' as js;

class FfmpegManager {
  static const String ffmpegVersion = '0.11.6';
  static const String _ffmpegCoreAsset = 'assets/ffmpeg/ffmpeg-core.js';
  static const String _ffmpegCoreSingleThreadCdn =
      'https://unpkg.com/@ffmpeg/core-st@0.11.0/dist/ffmpeg-core.js';
  static const String unsupportedEnvironmentMessage =
      'FFmpeg WebAssembly requires SharedArrayBuffer and cross-origin isolation (COOP/COEP).';

  FFmpeg? ffmpeg = createFFmpeg(
    CreateFFmpegParam(
      log: true,
      corePath: _ffmpegCoreSingleThreadCdn,
    ),
  );

  final progress = ValueNotifier<String?>(null);
  final statistics = ValueNotifier<String?>(null);
  final status = ValueNotifier<String?>(null);
  final cmd = ValueNotifier<String?>(null);

  bool isLoaded = false;

  bool get isWebFfmpegSupported {
    return true;
  }

  bool get canUseMultiThreadCore {
    if (!kIsWeb) return true;
    final hasSharedArrayBuffer = js.context.hasProperty('SharedArrayBuffer');
    final isCrossOriginIsolated = js.context['crossOriginIsolated'] == true;
    return hasSharedArrayBuffer && isCrossOriginIsolated;
  }

  String get webSupportDetails {
    if (!kIsWeb) return 'non-web platform';
    final hasSharedArrayBuffer = js.context.hasProperty('SharedArrayBuffer');
    final isCrossOriginIsolated = js.context['crossOriginIsolated'] == true;
    return 'SharedArrayBuffer=$hasSharedArrayBuffer, crossOriginIsolated=$isCrossOriginIsolated';
  }

  String get resolvedCorePath {
    if (!kIsWeb) return Uri.base.resolve(_ffmpegCoreAsset).toString();
    if (canUseMultiThreadCore) {
      return Uri.base.resolve(_ffmpegCoreAsset).toString();
    }
    // Fallback for iframe/non-isolated environments where SharedArrayBuffer is unavailable.
    return _ffmpegCoreSingleThreadCdn;
  }

  Future<void> loadFFmpeg(VoidCallback onInitialized, {bool setLog = true, Function(String)? onFailed}) async {
    try{
      if(ffmpeg?.isLoaded() ?? false) {
        js.context.callMethod('logger', [
          'FFmpegManager already loaded'
        ]);
        checkLoaded();
        onInitialized.call();
        return;
      }
      js.context.callMethod('logger', [
        'FFmpegManager start 1'
      ]);
      if (!canUseMultiThreadCore) {
        js.context.callMethod('logger', [
          'FFmpegManager non-isolated environment detected ($webSupportDetails). Falling back to single-thread core.'
        ]);
      }
      ffmpeg = createFFmpeg(
        CreateFFmpegParam(
          log: true,
          corePath: resolvedCorePath,
        ),
      );
      js.context.callMethod('logger', [
        'FFmpegManager loading ffmpeg core from $resolvedCorePath'
      ]);

      if(setLog) {
        ffmpeg?.setProgress(_onProgressHandler);
        ffmpeg?.setLogger(_onLogHandler);
      }
      js.context.callMethod('logger', [
        'FFmpegManager start 2'
      ]);
      await ffmpeg?.load();
      js.context.callMethod('logger', [
        'FFmpegManager await ffmpeg.load()'
      ]);
      checkLoaded();
      onInitialized.call();
    } catch(e) {
      onFailed?.call(e.toString());
      js.context.callMethod('logger', [
        'FFmpegManager catch error when init $e'
      ]);
    }
  }

  void checkLoaded() {
    isLoaded = ffmpeg?.isLoaded() ?? false;
    js.context.callMethod('logger', [
      'FFmpegManager checkLoaded isLoaded $isLoaded'
    ]);
  }

  void _onProgressHandler(ProgressParam progress) {
    final isDone = progress.ratio >= 1;

    this.progress.value = isDone ? null : '${((progress.ratio.isNaN ? 0 : progress.ratio) * 100).ceil()}% - ${progress.time}s';

    if (isDone) {
      statistics.value = null;
    }
  }

  static final regex = RegExp(
    r'frame\s*=\s*(\d+)\s+fps\s*=\s*(\d+(?:\.\d+)?)\s+q\s*=\s*([\d.-]+)\s+L?size\s*=\s*(\d+)\w*\s+time\s*=\s*([\d:\.]+)\s+bitrate\s*=\s*([\d.]+)\s*(\w+)/s\s+speed\s*=\s*([\d.]+)x',
  );

  Future<void> runCommand(List<String> command, {Function(String)? onFailed}) async {
    if (!isLoaded) {
      js.context.callMethod('logger', [
        'FFmpegManager runCommand isLoaded is false'
      ]);
      onFailed?.call('FFmpeg is not loaded yet');
      return;
    }
    try {
      cmd.value = command.join(' ');
      status.value = ProcessingStatus.started.name;
      js.context.callMethod('logger', [
        'FFmpegManager runCommand $command'
      ]);
      await ffmpeg?.run(command);
      status.value = ProcessingStatus.completed.name;
      js.context.callMethod('logger', [
        'FFmpegManager runCommand completed'
      ]);
    } catch (e) {
      status.value = ProcessingStatus.completed.name;
      js.context.callMethod('logger', [
        'FFmpegManager runCommand error: $e'
      ]);
      onFailed?.call(e.toString());
    }
  }

  void _onLogHandler(LoggerParam logger) {
    if (logger.type == 'fferr') {
      final match = regex.firstMatch(logger.message);

      if (match != null) {
        // indicates the number of frames that have been processed so far.
        final frame = match.group(1);
        // is the current frame rate
        final fps = match.group(2);
        // stands for quality 0.0 indicating lossless compression, other values indicating that there is some lossy compression happening
        final q = match.group(3);
        // indicates the size of the output file so far
        final size = match.group(4);
        // is the time that has elapsed since the beginning of the conversion
        final time = match.group(5);
        // is the current output bitrate
        final bitrate = match.group(6);
        // for instance: 'kbits/s'
        final bitrateUnit = match.group(7);
        // is the speed at which the conversion is happening, relative to real-time
        final speed = match.group(8);
        statistics.value = '\n[PROGRESS]: frame: $frame, fps: $fps, q: $q, size: $size, time: $time, bitrate: $bitrate$bitrateUnit, speed: $speed';
      }
    }
  }

  void dispose() {
    progress.dispose();
    statistics.dispose();
  }

  static final FfmpegManager instance = FfmpegManager._internal();

  factory FfmpegManager() {
    return instance;
  }

  FfmpegManager._internal();
}

 enum ProcessingStatus {
   started,
   saving,
   downloading,
   completed
}