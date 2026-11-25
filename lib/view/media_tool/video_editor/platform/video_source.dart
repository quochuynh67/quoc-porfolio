import 'dart:typed_data';
import 'dart:ui' as ui;

import 'video_source_stub.dart'
    if (dart.library.js_interop) 'video_source_web.dart' as impl;

/// A decoded media element whose frames can be pulled into the Flutter
/// canvas (so filters, transitions and blends apply to real video).
abstract class VideoSource {
  /// [hasVideo] false creates an audio-only source.
  factory VideoSource.create(Uint8List bytes, {bool hasVideo = true}) =>
      impl.createVideoSource(bytes, hasVideo);

  Future<void> init();
  bool get ready;
  Duration get duration;
  Duration get position;
  bool get playing;
  void seek(Duration time);
  void play();
  void pause();
  void setVolume(double volume);
  void setSpeed(double speed);
  void setLoop(bool loop);

  /// Pulls the current frame, or null when nothing changed since the last
  /// call (or no frame is available yet).
  Future<ui.Image?> grabFrame({bool force = false});
  void dispose();
}

/// Detects a container from magic bytes to choose the right MIME type.
String sniffMime(Uint8List b, {bool audio = false}) {
  if (b.length > 4 && b[0] == 0x1A && b[1] == 0x45 && b[2] == 0xDF) {
    return audio ? 'audio/webm' : 'video/webm';
  }
  if (b.length > 12 && b[4] == 0x66 && b[5] == 0x74 && b[6] == 0x79) {
    final brand = String.fromCharCodes(b.sublist(8, 12));
    if (brand.startsWith('qt')) return 'video/quicktime';
    return audio ? 'audio/mp4' : 'video/mp4';
  }
  if (b.length > 3 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
    return 'audio/mpeg';
  }
  if (b.length > 12 && b[0] == 0x52 && b[1] == 0x49) return 'audio/wav';
  if (b.length > 2 && b[0] == 0xFF && (b[1] & 0xE0) == 0xE0) {
    return 'audio/mpeg';
  }
  return audio ? 'audio/mpeg' : 'video/mp4';
}
