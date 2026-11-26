import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/editor_catalog.dart';
import '../domain/editor_template.dart';
import '../domain/video_editor_project.dart';
import '../domain/ids.dart';

/// Describes a transition that is currently playing at the playhead.
class ActiveTransition {
  const ActiveTransition({
    required this.type,
    required this.outgoing,
    required this.incoming,
    required this.progress,
  });

  final EditorTransition type;
  final EditorClip outgoing;
  final EditorClip incoming;

  /// 0..1, linear (curves are applied by the renderer).
  final double progress;
}

class VideoEditorController extends ChangeNotifier {
  VideoEditorProject _project = const VideoEditorProject();
  final List<VideoEditorProject> _undoStack = [];
  final List<VideoEditorProject> _redoStack = [];
  final ValueNotifier<Duration> positionListenable =
      ValueNotifier(Duration.zero);
  String? _selectedClipId;
  String? _selectedOverlayId;
  bool _isPlaying = false;
  DateTime? _lastTick;
  String? _coalesceKey;
  DateTime? _coalesceAt;

  Duration get _position => positionListenable.value;
  set _position(Duration value) => positionListenable.value = value;

  /// Fires on structural changes *and* every playhead movement.
  late final Listenable frameListenable =
      Listenable.merge([this, positionListenable]);

  @override
  void dispose() {
    positionListenable.dispose();
    super.dispose();
  }

  VideoEditorProject get project => _project;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  String? get selectedClipId => _selectedClipId;
  String? get selectedOverlayId => _selectedOverlayId;

  EditorClip? get selectedClip {
    for (final clip in _project.clips) {
      if (clip.id == _selectedClipId) return clip;
    }
    return null;
  }

  EditorOverlay? get selectedOverlay {
    for (final overlay in _project.overlays) {
      if (overlay.id == _selectedOverlayId) return overlay;
    }
    return null;
  }

  int get activeClipIndex {
    var cursor = Duration.zero;
    for (var i = 0; i < _project.clips.length; i++) {
      final end = cursor + _project.clips[i].duration;
      if (_position >= cursor && _position < end) return i;
      cursor = end;
    }
    return _project.clips.isEmpty ? -1 : _project.clips.length - 1;
  }

  EditorClip? get activeClip {
    final index = activeClipIndex;
    return index < 0 ? null : _project.clips[index];
  }

  Duration clipStart(int index) {
    var cursor = Duration.zero;
    for (var i = 0; i < index && i < _project.clips.length; i++) {
      cursor += _project.clips[i].duration;
    }
    return cursor;
  }

  Duration get activeClipStart => clipStart(math.max(0, activeClipIndex));

  Duration get activeClipPosition => _position - activeClipStart;

  /// The transition into the active clip, if the playhead is inside it.
  ActiveTransition? get activeTransition {
    final index = activeClipIndex;
    if (index <= 0) return null;
    final incoming = _project.clips[index];
    if (incoming.transition == EditorTransition.none) return null;
    final outgoing = _project.clips[index - 1];
    final window = transitionWindow(index);
    if (window <= Duration.zero) return null;
    final local = activeClipPosition;
    if (local >= window) return null;
    return ActiveTransition(
      type: incoming.transition,
      outgoing: outgoing,
      incoming: incoming,
      progress: local.inMicroseconds / window.inMicroseconds,
    );
  }

  /// Effective transition length for the clip at [index].
  Duration transitionWindow(int index) {
    if (index <= 0 || index >= _project.clips.length) return Duration.zero;
    final clip = _project.clips[index];
    final cap = Duration(microseconds: clip.duration.inMicroseconds ~/ 2);
    return clip.transitionDuration < cap ? clip.transitionDuration : cap;
  }

  Iterable<EditorOverlay> get activeOverlays => _project.overlays.where(
        (item) => _position >= item.start && _position <= item.end,
      );

  // ---------------------------------------------------------------- media

  void addClip({
    required String name,
    required EditorAssetType type,
    required Uint8List bytes,
  }) {
    final newClipStart = _project.duration;
    final clip = EditorClip(
      id: 'clip_${nextStamp()}',
      name: name,
      type: type,
      bytes: bytes,
    );
    _commit(_project.copyWith(clips: [..._project.clips, clip]));
    _selectedClipId = clip.id;
    _selectedOverlayId = null;
    _isPlaying = false;
    final index = _project.clips.length - 1;
    _position = newClipStart + transitionWindow(index);
    notifyListeners();
  }

  void addAudio(String name, Uint8List bytes) {
    _commit(_project.copyWith(audioTracks: [
      ..._project.audioTracks,
      EditorAudioTrack(
        id: 'audio_${nextStamp()}',
        name: name,
        bytes: bytes,
      ),
    ]));
  }

  // ------------------------------------------------------------- overlays

  void addText(EditorTextTemplate template) {
    _addOverlay(
      EditorOverlayType.text,
      template.sample,
      style: template.style,
      enter: template.enter,
      exit: template.exit,
      loop: template.loop,
    );
  }

  /// Adds a text built from a saved user template.
  void addTextFromTemplate(EditorTemplate template) {
    final j = template.data;
    final o = overlayFromJson(j, id: 'x');
    if (o == null) return;
    _addOverlay(
      EditorOverlayType.text,
      o.label,
      style: o.style,
      enter: o.enter,
      exit: o.exit,
      loop: o.loop,
      scale: o.scale,
      position: o.position,
    );
  }

  void addSticker(EditorSticker sticker) {
    _addOverlay(
      EditorOverlayType.sticker,
      sticker.emoji,
      position: const Offset(.5, .5),
      enter: OverlayEnter.pop,
    );
  }

  void addSprite(SpriteSpec sprite) {
    _addOverlay(
      EditorOverlayType.sprite,
      sprite.name,
      position: const Offset(.5, .5),
      sprite: sprite,
      length: sprite.loopDuration * 2 < const Duration(seconds: 2)
          ? const Duration(seconds: 2)
          : sprite.loopDuration * 2,
      scale: 1.6,
    );
  }

  void addParticles(String id) {
    _addOverlay(
      EditorOverlayType.particles,
      id,
      position: const Offset(.5, .5),
      scale: 2.4,
      length: const Duration(seconds: 5),
    );
  }

  void addVideoOverlay(String name, Uint8List bytes) {
    _addOverlay(
      EditorOverlayType.video,
      name,
      position: const Offset(.5, .5),
      video: bytes,
      scale: 2.4,
      length: const Duration(seconds: 4),
    );
  }

  void _addOverlay(
    EditorOverlayType type,
    String label, {
    EditorTextStyle style = const EditorTextStyle(),
    Offset position = const Offset(.5, .3),
    OverlayEnter enter = OverlayEnter.none,
    OverlayExit exit = OverlayExit.none,
    OverlayLoop loop = OverlayLoop.none,
    SpriteSpec? sprite,
    Uint8List? video,
    Duration length = const Duration(seconds: 4),
    double scale = 1,
  }) {
    final total = _project.duration;
    // Keep the new overlay inside the visible timeline.
    var start = _position;
    if (total > Duration.zero && start >= total) {
      start = total - const Duration(seconds: 1);
      if (start < Duration.zero) start = Duration.zero;
    }
    if (total > Duration.zero && start + length > total) {
      length = total - start;
      if (length < const Duration(milliseconds: 800)) {
        length = const Duration(milliseconds: 800);
      }
    }
    final overlay = EditorOverlay(
      id: 'overlay_${nextStamp()}',
      type: type,
      label: label,
      start: start,
      duration: length,
      position: position,
      scale: scale,
      style: style,
      enter: enter,
      exit: exit,
      loop: loop,
      sprite: sprite,
      video: video,
    );
    _commit(_project.copyWith(overlays: [..._project.overlays, overlay]));
    _selectedOverlayId = overlay.id;
    _selectedClipId = null;
    _position = start;
    notifyListeners();
  }

  void updateSelectedOverlay({
    String? label,
    Offset? position,
    double? scale,
    double? rotation,
    Duration? start,
    Duration? duration,
    EditorTextStyle? style,
    OverlayEnter? enter,
    OverlayExit? exit,
    OverlayLoop? loop,
  }) {
    final id = _selectedOverlayId;
    if (id == null) return;
    final next = _project.copyWith(
      overlays: _project.overlays
          .map((item) => item.id == id
              ? item.copyWith(
                  label: label,
                  position: position,
                  scale: scale,
                  rotation: rotation,
                  start: start,
                  duration: duration,
                  style: style,
                  enter: enter,
                  exit: exit,
                  loop: loop,
                )
              : item)
          .toList(),
    );
    _commit(next, coalesce: 'overlay:$id');
  }

  // ------------------------------------------------------------ selection

  void selectClip(String id) {
    _selectedClipId = id;
    _selectedOverlayId = null;
    notifyListeners();
  }

  void selectOverlay(String id) {
    _selectedOverlayId = id;
    _selectedClipId = null;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedClipId == null && _selectedOverlayId == null) return;
    _selectedClipId = null;
    _selectedOverlayId = null;
    notifyListeners();
  }

  // -------------------------------------------------------------- playback

  void seek(Duration value) {
    final max = _project.duration;
    _position = value < Duration.zero
        ? Duration.zero
        : value > max
            ? max
            : value;
  }

  void togglePlayback() {
    if (_project.duration == Duration.zero) return;
    if (_position >= _project.duration) _position = Duration.zero;
    _isPlaying = !_isPlaying;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void tick() {
    if (!_isPlaying) return;
    final now = DateTime.now();
    final delta = now.difference(_lastTick ?? now);
    _lastTick = now;
    final next = _position + delta;
    if (next >= _project.duration) {
      _position = _project.duration;
      _isPlaying = false;
      notifyListeners();
    } else {
      _position = next;
    }
  }

  // ------------------------------------------------------------- editing

  void updateAspectRatio(double ratio) {
    _commit(_project.copyWith(aspectRatio: ratio));
  }

  /// Duration of an image clip (undoable).
  void updateClipDuration(String id, Duration duration,
      {bool undoable = false}) {
    if (duration <= Duration.zero) return;
    final current = _clip(id);
    if (current == null ||
        (current.duration - duration).inMilliseconds.abs() < 100) {
      return;
    }
    final next = _mapClip(id, (c) => c.copyWith(duration: duration));
    if (undoable) {
      _commit(next, coalesce: 'clipdur:$id');
    } else {
      _project = next;
      notifyListeners();
    }
  }

  /// A video reported its real length: initialise the clip (not undoable).
  void setSourceDuration(String id, Duration source) {
    final clip = _clip(id);
    if (clip == null || source <= Duration.zero) return;
    if (clip.sourceDuration != null) return;
    _project = _mapClip(
      id,
      (c) => c.copyWith(
        sourceDuration: source,
        duration:
            Duration(microseconds: (source.inMicroseconds / c.speed).round()),
      ),
    );
    notifyListeners();
  }

  /// Trim a video clip by source-time in/out points.
  void trimSelectedClip({Duration? inPoint, Duration? outPoint}) {
    final id = _selectedClipId;
    final clip = id == null ? null : _clip(id);
    if (clip == null || clip.sourceDuration == null) return;
    const minLen = Duration(milliseconds: 400);
    var start = inPoint ?? clip.trimStart;
    var end = outPoint ?? clip.trimEnd;
    if (start < Duration.zero) start = Duration.zero;
    if (end > clip.sourceDuration!) end = clip.sourceDuration!;
    if (inPoint != null && end - start < minLen) start = end - minLen;
    if (outPoint != null && end - start < minLen) end = start + minLen;
    if (start < Duration.zero) start = Duration.zero;
    final length = Duration(
        microseconds: ((end - start).inMicroseconds / clip.speed).round());
    _commit(
      _mapClip(id!, (c) => c.copyWith(trimStart: start, duration: length)),
      coalesce: 'trim:$id',
    );
    if (_position > _project.duration) _position = _project.duration;
  }

  void setSelectedClipSpeed(double speed) {
    final id = _selectedClipId;
    final clip = id == null ? null : _clip(id);
    if (clip == null) return;
    final span = clip.duration.inMicroseconds * clip.speed;
    _commit(
      _mapClip(
        id!,
        (c) => c.copyWith(
          speed: speed,
          duration: Duration(microseconds: (span / speed).round()),
        ),
      ),
      coalesce: 'speed:$id',
    );
  }

  void setSelectedClipVolume(double volume) {
    final id = _selectedClipId;
    if (id == null) return;
    _commit(_mapClip(id, (c) => c.copyWith(volume: volume)),
        coalesce: 'vol:$id');
  }

  void setSelectedClipFilter(EditorFilter filter) {
    final id = _selectedClipId;
    if (id == null) return;
    _commit(_mapClip(id, (c) => c.copyWith(filter: filter)),
        coalesce: 'filter:$id');
  }

  void applyFilterToAll(EditorFilter filter) {
    _commit(_project.copyWith(
      clips: _project.clips.map((c) => c.copyWith(filter: filter)).toList(),
    ));
  }

  void setFitContain(bool value) {
    _commit(_project.copyWith(fitContain: value));
  }

  void setAudioVolume(String id, double volume) {
    _commit(
      _project.copyWith(
        audioTracks: _project.audioTracks
            .map((t) => t.id == id ? t.copyWith(volume: volume) : t)
            .toList(),
      ),
      coalesce: 'audiovol:$id',
    );
  }

  // ------------------------------------------------------ effect library

  final List<EditorFx> fxLibrary = [];
  final List<SpriteSpec> userSprites = [];

  void addFxVideo(String name, Uint8List bytes) {
    fxLibrary.add(EditorFx(id: 'fx_${nextStamp()}', name: name, video: bytes));
    notifyListeners();
  }

  void addUserSprite(SpriteSpec sprite) {
    userSprites.add(sprite);
    notifyListeners();
  }

  void setSelectedClipFx(EditorFx fx) {
    final id = _selectedClipId;
    if (id == null) return;
    _commit(_mapClip(
        id, (c) => c.copyWith(transition: EditorTransition.fx, fx: fx)));
    _previewTransition(id);
  }

  EditorClip? _clip(String id) {
    for (final clip in _project.clips) {
      if (clip.id == id) return clip;
    }
    return null;
  }

  VideoEditorProject _mapClip(
          String id, EditorClip Function(EditorClip) change) =>
      _project.copyWith(
        clips: _project.clips.map((c) => c.id == id ? change(c) : c).toList(),
      );

  // ------------------------------------------------------------ templates

  /// Applies a "whole vlog" recipe to the current project: canvas, grading
  /// and transitions per shot, plus its overlays at the playhead.
  void applyProjectTemplate(EditorTemplate template) {
    final d = template.data;
    final recipes = (d['clips'] as List?) ?? const [];
    var clips = _project.clips;
    if (recipes.isNotEmpty) {
      clips = [
        for (var i = 0; i < clips.length; i++)
          () {
            final r = Map<String, dynamic>.from(
                recipes[math.min(i, recipes.length - 1)] as Map);
            return clips[i].copyWith(
              transition: transitionFromName(r['transition']),
              transitionDuration: Duration(
                  milliseconds: ((r['transitionMs'] ?? 800) as num).toInt()),
              filter: filterFromJson(r['filter'] == null
                  ? null
                  : Map<String, dynamic>.from(r['filter'] as Map)),
            );
          }(),
      ];
    }
    final stamp = nextStamp();
    final added = <EditorOverlay>[];
    var n = 0;
    for (final raw in (d['overlays'] as List?) ?? const []) {
      final o = overlayFromJson(
        Map<String, dynamic>.from(raw as Map),
        id: 'overlay_${stamp}_${n++}',
      );
      if (o != null) added.add(o);
    }
    _commit(_project.copyWith(
      aspectRatio: ((d['aspect'] ?? _project.aspectRatio) as num).toDouble(),
      fitContain: (d['fitContain'] ?? _project.fitContain) as bool,
      clips: clips,
      overlays: [..._project.overlays, ...added],
    ));
    _position = Duration.zero;
    notifyListeners();
  }

  void updateSelectedTransition(
    EditorTransition transition, {
    Duration? duration,
  }) {
    final id = _selectedClipId;
    if (id == null) return;
    _commit(
      _project.copyWith(
        clips: _project.clips
            .map((clip) => clip.id == id
                ? clip.copyWith(
                    transition: transition,
                    transitionDuration: duration,
                  )
                : clip)
            .toList(),
      ),
      coalesce: duration != null ? 'transdur:$id' : null,
    );
    if (duration == null) _previewTransition(id);
  }

  void applyTransitionToAll(EditorTransition transition) {
    _commit(_project.copyWith(
      clips: _project.clips
          .map((clip) => clip.copyWith(transition: transition))
          .toList(),
    ));
  }

  /// Moves the playhead just before the transition so it can be previewed.
  void _previewTransition(String clipId) {
    final index = _project.clips.indexWhere((c) => c.id == clipId);
    if (index <= 0) return;
    final start = clipStart(index);
    final lead = const Duration(milliseconds: 600);
    _position = start > lead ? start - lead : Duration.zero;
    _isPlaying = true;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  /// Plays the selected overlay from just before its start.
  void previewSelectedOverlay() {
    final o = selectedOverlay;
    if (o == null) return;
    final lead = const Duration(milliseconds: 300);
    _position = o.start > lead ? o.start - lead : Duration.zero;
    _isPlaying = true;
    _lastTick = DateTime.now();
    notifyListeners();
  }

  void splitSelectedClip() {
    final id = _selectedClipId;
    if (id == null) return;
    var cursor = Duration.zero;
    final clips = <EditorClip>[];
    var didSplit = false;
    for (final clip in _project.clips) {
      if (clip.id != id) {
        clips.add(clip);
        cursor += clip.duration;
        continue;
      }
      final local = _position - cursor;
      final remaining = clip.duration - local;
      if (local.inMilliseconds < 300 || remaining.inMilliseconds < 300) {
        clips.add(clip);
      } else {
        final stamp = nextStamp();
        clips.add(clip.copyWith(
          id: '${clip.id}_a_$stamp',
          name: '${clip.name} A',
          duration: local,
        ));
        clips.add(clip.copyWith(
          id: '${clip.id}_b_$stamp',
          name: '${clip.name} B',
          duration: remaining,
          trimStart: clip.trimStart +
              Duration(
                  microseconds: (local.inMicroseconds * clip.speed).round()),
          transition: EditorTransition.none,
          fx: null,
        ));
        _selectedClipId = clips.last.id;
        didSplit = true;
      }
      cursor += clip.duration;
    }
    if (didSplit) _commit(_project.copyWith(clips: clips));
  }

  void moveSelectedClip(int delta) {
    final id = _selectedClipId;
    if (id == null) return;
    final index = _project.clips.indexWhere((c) => c.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= _project.clips.length) return;
    final clips = [..._project.clips];
    final clip = clips.removeAt(index);
    clips.insert(target, clip);
    _commit(_project.copyWith(clips: clips));
  }

  void removeSelection() {
    if (_selectedClipId != null) {
      _commit(_project.copyWith(
        clips:
            _project.clips.where((clip) => clip.id != _selectedClipId).toList(),
      ));
      _selectedClipId = null;
    } else if (_selectedOverlayId != null) {
      _commit(_project.copyWith(
        overlays: _project.overlays
            .where((item) => item.id != _selectedOverlayId)
            .toList(),
      ));
      _selectedOverlayId = null;
    }
    if (_position > _project.duration) _position = _project.duration;
    notifyListeners();
  }

  void removeAudio(String id) {
    _commit(_project.copyWith(
      audioTracks: _project.audioTracks.where((t) => t.id != id).toList(),
    ));
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_project);
    _project = _undoStack.removeLast();
    _coalesceKey = null;
    _sanitizeSelection();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_project);
    _project = _redoStack.removeLast();
    _coalesceKey = null;
    _sanitizeSelection();
    notifyListeners();
  }

  /// Pushes an undo step. Repeated edits sharing [coalesce] within a short
  /// window (slider drags, overlay dragging) collapse into a single step.
  void _commit(VideoEditorProject next, {String? coalesce}) {
    final now = DateTime.now();
    final merge = coalesce != null &&
        coalesce == _coalesceKey &&
        _coalesceAt != null &&
        now.difference(_coalesceAt!) < const Duration(milliseconds: 700);
    if (!merge) {
      _undoStack.add(_project);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    }
    _coalesceKey = coalesce;
    _coalesceAt = now;
    _redoStack.clear();
    _project = next;
    notifyListeners();
  }

  void _sanitizeSelection() {
    if (!_project.clips.any((clip) => clip.id == _selectedClipId)) {
      _selectedClipId = null;
    }
    if (!_project.overlays.any((item) => item.id == _selectedOverlayId)) {
      _selectedOverlayId = null;
    }
    if (_position > _project.duration) _position = _project.duration;
  }
}
