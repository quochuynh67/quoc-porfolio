import 'dart:typed_data';

import 'package:flutter/material.dart';

enum EditorAssetType { video, image, audio }

enum EditorOverlayType { text, sticker, sprite, particles, video }

/// Enter / exit animation of an overlay.
enum OverlayEnter {
  none,
  fade,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  pop,
  zoom,
  spin,
  bounce,
  blur,
  typewriter,
  letterRise,
}

enum OverlayExit { none, fade, slideDown, slideUp, zoom, pop }

/// Continuous animation while the overlay is on screen.
enum OverlayLoop { none, pulse, float, shake, swing, wave, glitch, blink, spin }

extension OverlayAnimMeta on Enum {
  String get label {
    final n = name;
    return switch (n) {
      'none' => 'None',
      'fade' => 'Fade',
      'slideUp' => 'Slide up',
      'slideDown' => 'Slide down',
      'slideLeft' => 'Slide left',
      'slideRight' => 'Slide right',
      'pop' => 'Pop',
      'zoom' => 'Zoom',
      'spin' => 'Spin',
      'bounce' => 'Bounce',
      'blur' => 'Blur in',
      'typewriter' => 'Typewriter',
      'letterRise' => 'Letter rise',
      'pulse' => 'Pulse',
      'float' => 'Float',
      'shake' => 'Shake',
      'swing' => 'Swing',
      'wave' => 'Wave',
      'glitch' => 'Glitch',
      'blink' => 'Blink',
      _ => n,
    };
  }
}

/// A sprite sheet: [cols] x [rows] grid, first [frames] cells are played.
@immutable
class SpriteSpec {
  const SpriteSpec({
    this.url,
    this.bytes,
    required this.cols,
    required this.rows,
    int? frames,
    this.fps = 14,
    this.name = 'Sprite',
  }) : frames = frames ?? cols * rows;

  final String? url;
  final Uint8List? bytes;
  final int cols;
  final int rows;
  final int frames;
  final double fps;
  final String name;

  String get cacheKey => url ?? 'mem:${identityHashCode(bytes)}';

  Duration get loopDuration =>
      Duration(milliseconds: (frames / fps * 1000).round());
}

enum EditorTransition {
  none,
  fade,
  dipBlack,
  slideLeft,
  slideRight,
  slideUp,
  pushLeft,
  zoomIn,
  zoomOut,
  wipe,
  spin,
  blur,
  flash,
  glitch,
  circle,
  blinds,
  pixelate,

  /// Dip transition with an effect pack (sprite sheet or WebM/MP4 overlay)
  /// drawn on top; see [EditorClip.fx].
  fx,
}

/// Effect pack drawn on top of a transition: a sprite sheet or a video
/// (WebM/MP4 on a black background, composited with screen blend).
@immutable
class EditorFx {
  const EditorFx({
    required this.id,
    required this.name,
    this.sprite,
    this.video,
  });
  final String id;
  final String name;
  final SpriteSpec? sprite;
  final Uint8List? video;
}

extension EditorTransitionMeta on EditorTransition {
  String get label => switch (this) {
        EditorTransition.none => 'Cut',
        EditorTransition.fade => 'Cross fade',
        EditorTransition.dipBlack => 'Dip to black',
        EditorTransition.slideLeft => 'Slide left',
        EditorTransition.slideRight => 'Slide right',
        EditorTransition.slideUp => 'Slide up',
        EditorTransition.pushLeft => 'Push',
        EditorTransition.zoomIn => 'Zoom in',
        EditorTransition.zoomOut => 'Zoom out',
        EditorTransition.wipe => 'Wipe',
        EditorTransition.spin => 'Spin',
        EditorTransition.blur => 'Blur',
        EditorTransition.flash => 'Flash',
        EditorTransition.glitch => 'Glitch',
        EditorTransition.circle => 'Circle reveal',
        EditorTransition.blinds => 'Blinds',
        EditorTransition.pixelate => 'Mosaic',
        EditorTransition.fx => 'FX pack',
      };

  IconData get icon => switch (this) {
        EditorTransition.none => Icons.content_cut_rounded,
        EditorTransition.fade => Icons.blur_on_rounded,
        EditorTransition.dipBlack => Icons.brightness_2_rounded,
        EditorTransition.slideLeft => Icons.arrow_back_rounded,
        EditorTransition.slideRight => Icons.arrow_forward_rounded,
        EditorTransition.slideUp => Icons.arrow_upward_rounded,
        EditorTransition.pushLeft => Icons.swap_horiz_rounded,
        EditorTransition.zoomIn => Icons.zoom_in_rounded,
        EditorTransition.zoomOut => Icons.zoom_out_rounded,
        EditorTransition.wipe => Icons.view_sidebar_rounded,
        EditorTransition.spin => Icons.autorenew_rounded,
        EditorTransition.blur => Icons.lens_blur_rounded,
        EditorTransition.flash => Icons.flash_on_rounded,
        EditorTransition.glitch => Icons.broken_image_rounded,
        EditorTransition.circle => Icons.radio_button_unchecked_rounded,
        EditorTransition.blinds => Icons.view_week_rounded,
        EditorTransition.pixelate => Icons.grid_view_rounded,
        EditorTransition.fx => Icons.movie_filter_rounded,
      };
}

/// Colour grading applied to a clip.
@immutable
class EditorFilter {
  const EditorFilter({
    this.preset = 'none',
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
  });

  final String preset;

  /// All adjustments are -1..1 (0 = unchanged).
  final double brightness;
  final double contrast;
  final double saturation;

  bool get isIdentity =>
      preset == 'none' && brightness == 0 && contrast == 0 && saturation == 0;

  EditorFilter copyWith({
    String? preset,
    double? brightness,
    double? contrast,
    double? saturation,
  }) =>
      EditorFilter(
        preset: preset ?? this.preset,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
      );
}

@immutable
class EditorClip {
  const EditorClip({
    required this.id,
    required this.name,
    required this.type,
    required this.bytes,
    this.duration = const Duration(seconds: 5),
    this.transition = EditorTransition.fade,
    this.transitionDuration = const Duration(milliseconds: 800),
    this.fx,
    this.trimStart = Duration.zero,
    this.sourceDuration,
    this.speed = 1,
    this.volume = 1,
    this.filter = const EditorFilter(),
  });

  final String id;
  final String name;
  final EditorAssetType type;
  final Uint8List bytes;

  /// Length on the timeline (already accounts for trim and speed).
  final Duration duration;

  /// Transition played when this clip starts (ignored for the first clip).
  final EditorTransition transition;
  final Duration transitionDuration;
  final EditorFx? fx;

  /// Offset into the source media where this clip starts (video only).
  final Duration trimStart;

  /// Full length of the source video, once known.
  final Duration? sourceDuration;
  final double speed;
  final double volume;
  final EditorFilter filter;

  /// Source time that corresponds to the end of this clip.
  Duration get trimEnd =>
      trimStart +
      Duration(microseconds: (duration.inMicroseconds * speed).round());

  EditorClip copyWith({
    String? id,
    String? name,
    Duration? duration,
    EditorTransition? transition,
    Duration? transitionDuration,
    Object? fx = _keep,
    Duration? trimStart,
    Duration? sourceDuration,
    double? speed,
    double? volume,
    EditorFilter? filter,
  }) {
    return EditorClip(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type,
      bytes: bytes,
      duration: duration ?? this.duration,
      transition: transition ?? this.transition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      fx: identical(fx, _keep) ? this.fx : fx as EditorFx?,
      trimStart: trimStart ?? this.trimStart,
      sourceDuration: sourceDuration ?? this.sourceDuration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      filter: filter ?? this.filter,
    );
  }
}

const Object _keep = Object();

/// Visual style of a text overlay. Rendered by `EditorTextView`.
@immutable
class EditorTextStyle {
  const EditorTextStyle({
    this.fontFamily = 'Montserrat',
    this.fontSize = 28,
    this.weight = 800,
    this.color = Colors.white,
    this.background,
    this.stroke,
    this.strokeWidth = 0,
    this.glow,
    this.shadow = true,
    this.letterSpacing = 0,
    this.uppercase = false,
    this.italic = false,
    this.gradient,
    this.radius = 10,
  });

  final String fontFamily;
  final double fontSize;
  final int weight;
  final Color color;
  final Color? background;
  final Color? stroke;
  final double strokeWidth;
  final Color? glow;
  final bool shadow;
  final double letterSpacing;
  final bool uppercase;
  final bool italic;
  final List<Color>? gradient;
  final double radius;
}

@immutable
class EditorOverlay {
  const EditorOverlay({
    required this.id,
    required this.type,
    required this.label,
    required this.start,
    required this.duration,
    this.position = const Offset(.5, .3),
    this.scale = 1,
    this.rotation = 0,
    this.style = const EditorTextStyle(),
    this.enter = OverlayEnter.none,
    this.exit = OverlayExit.none,
    this.loop = OverlayLoop.none,
    this.sprite,
    this.video,
  });

  final String id;
  final EditorOverlayType type;

  /// Text content, or the emoji for stickers.
  final String label;
  final Duration start;
  final Duration duration;
  final Offset position;
  final double scale;
  final double rotation;
  final EditorTextStyle style;
  final OverlayEnter enter;
  final OverlayExit exit;
  final OverlayLoop loop;

  /// For [EditorOverlayType.sprite].
  final SpriteSpec? sprite;

  /// For [EditorOverlayType.video] (WebM/MP4, screen blended).
  final Uint8List? video;

  Duration get end => start + duration;

  EditorOverlay copyWith({
    String? label,
    Duration? start,
    Duration? duration,
    Offset? position,
    double? scale,
    double? rotation,
    EditorTextStyle? style,
    OverlayEnter? enter,
    OverlayExit? exit,
    OverlayLoop? loop,
  }) {
    return EditorOverlay(
      id: id,
      type: type,
      label: label ?? this.label,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      style: style ?? this.style,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
      loop: loop ?? this.loop,
      sprite: sprite,
      video: video,
    );
  }
}

@immutable
class EditorAudioTrack {
  const EditorAudioTrack({
    required this.id,
    required this.name,
    required this.bytes,
    this.volume = .65,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final double volume;

  EditorAudioTrack copyWith({double? volume}) => EditorAudioTrack(
      id: id, name: name, bytes: bytes, volume: volume ?? this.volume);
}

@immutable
class VideoEditorProject {
  const VideoEditorProject({
    this.clips = const [],
    this.overlays = const [],
    this.audioTracks = const [],
    this.aspectRatio = 9 / 16,
    this.fitContain = false,
  });

  /// Show whole frame with bars (true) or fill the canvas (false).
  final bool fitContain;
  final List<EditorClip> clips;
  final List<EditorOverlay> overlays;
  final List<EditorAudioTrack> audioTracks;
  final double aspectRatio;

  Duration get duration => clips.fold(
        Duration.zero,
        (total, clip) => total + clip.duration,
      );

  VideoEditorProject copyWith({
    List<EditorClip>? clips,
    List<EditorOverlay>? overlays,
    List<EditorAudioTrack>? audioTracks,
    double? aspectRatio,
    bool? fitContain,
  }) {
    return VideoEditorProject(
      fitContain: fitContain ?? this.fitContain,
      clips: clips ?? this.clips,
      overlays: overlays ?? this.overlays,
      audioTracks: audioTracks ?? this.audioTracks,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }
}
