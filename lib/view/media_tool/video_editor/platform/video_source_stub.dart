import 'dart:typed_data';
import 'dart:ui' as ui;

import 'video_source.dart';

VideoSource createVideoSource(Uint8List bytes, bool hasVideo) =>
    _StubVideoSource();

/// Non-web platforms (and tests): playback is unavailable.
class _StubVideoSource implements VideoSource {
  @override
  Future<void> init() async => throw UnsupportedError('Web only');
  @override
  bool get ready => false;
  @override
  Duration get duration => Duration.zero;
  @override
  Duration get position => Duration.zero;
  @override
  bool get playing => false;
  @override
  void seek(Duration time) {}
  @override
  void play() {}
  @override
  void pause() {}
  @override
  void setVolume(double volume) {}
  @override
  void setSpeed(double speed) {}
  @override
  void setLoop(bool loop) {}
  @override
  Future<ui.Image?> grabFrame({bool force = false}) async => null;
  @override
  void dispose() {}
}
