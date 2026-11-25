import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'video_source.dart';

VideoSource createVideoSource(Uint8List bytes, bool hasVideo) =>
    _WebVideoSource(bytes, hasVideo);

class _WebVideoSource implements VideoSource {
  _WebVideoSource(this._bytes, this._hasVideo);

  final Uint8List _bytes;
  final bool _hasVideo;
  web.HTMLVideoElement? _video;
  String? _url;
  double _lastGrabbed = -1;
  bool _forceNext = true;
  bool _disposed = false;
  bool _grabbing = false;

  @override
  Future<void> init() async {
    final mime = sniffMime(_bytes, audio: !_hasVideo);
    final blob = web.Blob(
      [_bytes.toJS].toJS,
      web.BlobPropertyBag(type: mime),
    );
    _url = web.URL.createObjectURL(blob);
    final video = web.document.createElement('video') as web.HTMLVideoElement;
    video
      ..preload = 'auto'
      ..src = _url!
      ..setAttribute('playsinline', 'true');
    video.muted = false;
    _video = video;

    final ready = Completer<void>();
    void done(web.Event _) {
      if (!ready.isCompleted) ready.complete();
    }

    void failed(web.Event _) {
      if (!ready.isCompleted) {
        ready.completeError(StateError('Could not decode media'));
      }
    }

    video.addEventListener('loadeddata', done.toJS);
    video.addEventListener('error', failed.toJS);
    video.addEventListener('seeked', ((web.Event _) => _forceNext = true).toJS);
    video.load();
    await ready.future.timeout(const Duration(seconds: 20));
  }

  @override
  bool get ready => (_video?.readyState ?? 0) >= 2;

  @override
  Duration get duration {
    final d = _video?.duration ?? 0;
    return d.isNaN || d.isInfinite
        ? Duration.zero
        : Duration(microseconds: (d * 1e6).round());
  }

  @override
  Duration get position =>
      Duration(microseconds: ((_video?.currentTime ?? 0) * 1e6).round());

  @override
  bool get playing => _video != null && !_video!.paused && !_video!.ended;

  @override
  void seek(Duration time) {
    final v = _video;
    if (v == null) return;
    final target = time.inMicroseconds / 1e6;
    if ((v.currentTime - target).abs() < .02) return;
    v.currentTime = target;
  }

  @override
  void play() {
    final v = _video;
    if (v == null || playing) return;
    v.play().toDart.catchError((_) => null);
  }

  @override
  void pause() {
    final v = _video;
    if (v == null || v.paused) return;
    v.pause();
    _forceNext = true;
  }

  @override
  void setVolume(double volume) => _video?.volume = volume.clamp(0.0, 1.0);

  @override
  void setSpeed(double speed) => _video?.playbackRate = speed;

  @override
  void setLoop(bool loop) => _video?.loop = loop;

  @override
  Future<ui.Image?> grabFrame({bool force = false}) async {
    final v = _video;
    if (v == null || _disposed || _grabbing || !_hasVideo) return null;
    if (v.readyState < 2 || v.videoWidth == 0) return null;
    final t = v.currentTime;
    if (!force && !_forceNext && (t - _lastGrabbed).abs() < 1e-3) return null;
    _grabbing = true;
    try {
      _lastGrabbed = t;
      _forceNext = false;
      return await ui_web.createImageFromTextureSource(
        v as JSAny,
        width: v.videoWidth,
        height: v.videoHeight,
        transferOwnership: false,
      );
    } catch (_) {
      return null;
    } finally {
      _grabbing = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final v = _video;
    if (v != null) {
      v.pause();
      v.removeAttribute('src');
      v.load();
    }
    if (_url != null) web.URL.revokeObjectURL(_url!);
    _video = null;
  }
}
