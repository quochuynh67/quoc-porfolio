// ignore_for_file: deprecated_member_use
import 'dart:convert';

import 'package:flutter/material.dart';

import 'editor_catalog.dart';
import 'video_editor_project.dart';
import 'ids.dart';

enum EditorTemplateKind { text, project }

/// A reusable preset: either one styled / animated text, or the "recipe" of a
/// whole vlog (canvas, overlays, per-shot transitions and grading) without the
/// user's media.
@immutable
class EditorTemplate {
  const EditorTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.data,
    this.builtin = false,
  });

  final String id;
  final String name;
  final EditorTemplateKind kind;
  final Map<String, dynamic> data;
  final bool builtin;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'kind': kind.name, 'data': data};

  String encode() => jsonEncode(toJson());

  static EditorTemplate? tryDecode(String source) {
    try {
      final map = jsonDecode(source);
      if (map is! Map<String, dynamic>) return null;
      final kind = EditorTemplateKind.values
          .firstWhere((k) => k.name == map['kind'], orElse: () => throw 0);
      return EditorTemplate(
        id: map['id'] as String,
        name: map['name'] as String,
        kind: kind,
        data: Map<String, dynamic>.from(map['data'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------ factories

  static EditorTemplate fromText(String name, EditorOverlay overlay) =>
      EditorTemplate(
        id: 'user_${nextStamp()}',
        name: name,
        kind: EditorTemplateKind.text,
        data: overlayToJson(overlay),
      );

  static EditorTemplate fromProject(String name, VideoEditorProject project) {
    return EditorTemplate(
      id: 'user_${nextStamp()}',
      name: name,
      kind: EditorTemplateKind.project,
      data: {
        'aspect': project.aspectRatio,
        'fitContain': project.fitContain,
        'overlays': [
          for (final o in project.overlays)
            if (o.type != EditorOverlayType.video) overlayToJson(o),
        ],
        'clips': [
          for (final c in project.clips)
            {
              'transition': c.transition.name,
              if (c.shaderId != null) 'shader': c.shaderId,
              'transitionMs': c.transitionDuration.inMilliseconds,
              'filter': filterToJson(c.filter),
            },
        ],
      },
    );
  }
}

// ----------------------------------------------------------- JSON helpers

Map<String, dynamic> styleToJson(EditorTextStyle s) => {
      'font': s.fontFamily,
      'size': s.fontSize,
      'weight': s.weight,
      'color': s.color.value,
      if (s.background != null) 'bg': s.background!.value,
      if (s.stroke != null) 'stroke': s.stroke!.value,
      'strokeW': s.strokeWidth,
      if (s.glow != null) 'glow': s.glow!.value,
      'shadow': s.shadow,
      'spacing': s.letterSpacing,
      'upper': s.uppercase,
      'italic': s.italic,
      if (s.gradient != null)
        'gradient': [for (final c in s.gradient!) c.value],
      'radius': s.radius,
    };

EditorTextStyle styleFromJson(Map<String, dynamic> j) => EditorTextStyle(
      fontFamily: (j['font'] ?? 'Montserrat') as String,
      fontSize: ((j['size'] ?? 28) as num).toDouble(),
      weight: ((j['weight'] ?? 800) as num).toInt(),
      color: Color((j['color'] ?? 0xFFFFFFFF) as int),
      background: j['bg'] == null ? null : Color(j['bg'] as int),
      stroke: j['stroke'] == null ? null : Color(j['stroke'] as int),
      strokeWidth: ((j['strokeW'] ?? 0) as num).toDouble(),
      glow: j['glow'] == null ? null : Color(j['glow'] as int),
      shadow: (j['shadow'] ?? true) as bool,
      letterSpacing: ((j['spacing'] ?? 0) as num).toDouble(),
      uppercase: (j['upper'] ?? false) as bool,
      italic: (j['italic'] ?? false) as bool,
      gradient: j['gradient'] == null
          ? null
          : [for (final c in j['gradient'] as List) Color(c as int)],
      radius: ((j['radius'] ?? 10) as num).toDouble(),
    );

Map<String, dynamic> filterToJson(EditorFilter f) => {
      'preset': f.preset,
      'b': f.brightness,
      'c': f.contrast,
      's': f.saturation,
      if (f.intensity != 1) 'i': f.intensity,
    };

EditorFilter filterFromJson(Map<String, dynamic>? j) => j == null
    ? const EditorFilter()
    : EditorFilter(
        preset: (j['preset'] ?? 'none') as String,
        brightness: ((j['b'] ?? 0) as num).toDouble(),
        contrast: ((j['c'] ?? 0) as num).toDouble(),
        saturation: ((j['s'] ?? 0) as num).toDouble(),
        intensity: ((j['i'] ?? 1) as num).toDouble(),
      );

Map<String, dynamic> overlayToJson(EditorOverlay o) => {
      'type': o.type.name,
      'label': o.label,
      'startMs': o.start.inMilliseconds,
      'durMs': o.duration.inMilliseconds,
      'x': o.position.dx,
      'y': o.position.dy,
      'scale': o.scale,
      'rot': o.rotation,
      'style': styleToJson(o.style),
      'enter': o.enter.name,
      'exit': o.exit.name,
      'loop': o.loop.name,
      if (o.sprite?.url != null) 'sprite': o.sprite!.name,
    };

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Rebuilds an overlay from a template. [startShift] is added to its start.
EditorOverlay? overlayFromJson(
  Map<String, dynamic> j, {
  required String id,
  Duration startShift = Duration.zero,
}) {
  final type =
      _byName(EditorOverlayType.values, j['type'], EditorOverlayType.text);
  SpriteSpec? sprite;
  if (type == EditorOverlayType.sprite) {
    for (final s in builtinSprites) {
      if (s.name == j['sprite']) sprite = s;
    }
    if (sprite == null) return null;
  }
  if (type == EditorOverlayType.video) return null;
  return EditorOverlay(
    id: id,
    type: type,
    label: (j['label'] ?? '') as String,
    start: Duration(milliseconds: ((j['startMs'] ?? 0) as num).toInt()) +
        startShift,
    duration: Duration(milliseconds: ((j['durMs'] ?? 3000) as num).toInt()),
    position: Offset(
        ((j['x'] ?? .5) as num).toDouble(), ((j['y'] ?? .3) as num).toDouble()),
    scale: ((j['scale'] ?? 1) as num).toDouble(),
    rotation: ((j['rot'] ?? 0) as num).toDouble(),
    style: styleFromJson(Map<String, dynamic>.from((j['style'] ?? {}) as Map)),
    enter: _byName(OverlayEnter.values, j['enter'], OverlayEnter.none),
    exit: _byName(OverlayExit.values, j['exit'], OverlayExit.none),
    loop: _byName(OverlayLoop.values, j['loop'], OverlayLoop.none),
    sprite: sprite,
  );
}

EditorTransition transitionFromName(Object? name) =>
    _byName(EditorTransition.values, name, EditorTransition.fade);

// ------------------------------------------------------ built-in recipes

EditorOverlay _o(
  EditorOverlayType type,
  String label, {
  int start = 0,
  int dur = 3000,
  Offset at = const Offset(.5, .3),
  double scale = 1,
  EditorTextStyle style = const EditorTextStyle(),
  OverlayEnter enter = OverlayEnter.none,
  OverlayExit exit = OverlayExit.none,
  OverlayLoop loop = OverlayLoop.none,
  SpriteSpec? sprite,
}) =>
    EditorOverlay(
      id: 'tpl',
      type: type,
      label: label,
      start: Duration(milliseconds: start),
      duration: Duration(milliseconds: dur),
      position: at,
      scale: scale,
      style: style,
      enter: enter,
      exit: exit,
      loop: loop,
      sprite: sprite,
    );

EditorTemplate _recipe(
  String id,
  String name,
  double aspect,
  List<EditorOverlay> overlays,
  EditorTransition transition,
  int transitionMs,
  String filter,
) {
  return EditorTemplate(
    id: id,
    name: name,
    kind: EditorTemplateKind.project,
    builtin: true,
    data: {
      'aspect': aspect,
      'fitContain': false,
      'overlays': [for (final o in overlays) overlayToJson(o)],
      // Applied to every clip; extra clips repeat the last entry.
      'clips': [
        {
          'transition': transition.name,
          'transitionMs': transitionMs,
          'filter': filterToJson(EditorFilter(preset: filter)),
        }
      ],
    },
  );
}

EditorTextTemplate _t(String id) => textTemplates.firstWhere((t) => t.id == id,
    orElse: () => textTemplates.first);

List<EditorTemplate> buildBuiltinTemplates() {
  EditorOverlay fromT(String id, String text,
      {int start = 0,
      int dur = 3000,
      Offset at = const Offset(.5, .3),
      double scale = 1}) {
    final t = _t(id);
    return _o(EditorOverlayType.text, text,
        start: start,
        dur: dur,
        at: at,
        scale: scale,
        style: t.style,
        enter: t.enter,
        exit: t.exit,
        loop: t.loop);
  }

  return [
    _recipe(
      'tpl_travel',
      'Travel vlog intro',
      9 / 16,
      [
        fromT('anim-letter-rise', 'MY TRAVEL VLOG',
            start: 300, dur: 3200, at: const Offset(.5, .32)),
        fromT('anim-slide-title', 'Day 01',
            start: 900, dur: 2600, at: const Offset(.5, .42), scale: .8),
        _o(EditorOverlayType.sticker, '✈️',
            start: 600,
            dur: 3000,
            at: const Offset(.5, .58),
            scale: 1.3,
            enter: OverlayEnter.pop,
            loop: OverlayLoop.float),
      ],
      EditorTransition.slideLeft,
      600,
      'warm',
    ),
    _recipe(
      'tpl_tiktok',
      'TikTok hook',
      9 / 16,
      [
        fromT('anim-shake', 'WAIT FOR IT',
            start: 0, dur: 2500, at: const Offset(.5, .25)),
        _o(EditorOverlayType.particles, 'sparkles',
            start: 0, dur: 4000, at: const Offset(.5, .5), scale: 2),
        fromT('anim-pop', 'WOW!',
            start: 2500, dur: 2000, at: const Offset(.5, .6)),
      ],
      EditorTransition.glitch,
      500,
      'vivid',
    ),
    _recipe(
      'tpl_cinema',
      'Cinematic title',
      21 / 9,
      [
        fromT('anim-blur-in', 'The Journey',
            start: 500, dur: 4000, at: const Offset(.5, .5), scale: 1.2),
      ],
      EditorTransition.dipBlack,
      1200,
      'drama',
    ),
    _recipe(
      'tpl_birthday',
      'Birthday party',
      1,
      [
        fromT('anim-bounce', 'Happy Birthday!',
            start: 300, dur: 3500, at: const Offset(.5, .25), scale: 1.2),
        _o(EditorOverlayType.particles, 'confetti',
            start: 0, dur: 5000, at: const Offset(.5, .5), scale: 2),
        _o(EditorOverlayType.sticker, '🎂',
            start: 800,
            dur: 3000,
            at: const Offset(.5, .65),
            scale: 1.5,
            enter: OverlayEnter.pop,
            loop: OverlayLoop.pulse),
      ],
      EditorTransition.zoomIn,
      700,
      'vivid',
    ),
    _recipe(
      'tpl_quote',
      'Quote story',
      4 / 5,
      [
        fromT('anim-typewriter', 'Less is more.',
            start: 400, dur: 4000, at: const Offset(.5, .5), scale: 1.2),
      ],
      EditorTransition.fade,
      900,
      'fade',
    ),
    _recipe(
      'tpl_music',
      'Beat drop',
      9 / 16,
      [
        fromT('anim-neon-blink', 'DROP IT',
            start: 0, dur: 3000, at: const Offset(.5, .3)),
        _o(EditorOverlayType.sprite, 'Explosion',
            start: 1500,
            dur: 1300,
            at: const Offset(.5, .5),
            scale: 3,
            sprite: builtinSprites.first),
      ],
      EditorTransition.flash,
      400,
      'drama',
    ),
  ];
}
