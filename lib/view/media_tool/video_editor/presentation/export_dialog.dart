import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/export_plan.dart';
import '../domain/video_editor_project.dart';
import '../platform/editor_exporter.dart';
import 'export_prep.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key, required this.project});
  final VideoEditorProject project;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

enum _Phase { options, running, done, failed }

class _ExportDialogState extends State<ExportDialog> {
  final EditorExporter _exporter = EditorExporter();
  _Phase _phase = _Phase.options;
  int _shortSide = 720;
  bool _music = true;
  String _label = '';
  String _logLine = '';
  double _fraction = 0;
  bool _cancelled = false;
  Timer? _ticker;
  final Stopwatch _clock = Stopwatch();
  DateTime _lastOutput = DateTime.now();
  ExportOutcome? _outcome;

  VideoEditorProject get _project => widget.project;

  List<String> get _heads {
    final notes = <String>[];
    if (_project.overlays.any((o) => o.type == EditorOverlayType.sticker)) {
      notes.add('Sticker artwork is rasterized while its position, scale and '
          'animation stay synchronized with the preview.');
    }
    if (_project.overlays.any((o) => o.type == EditorOverlayType.video)) {
      notes.add('Video overlays are sampled at 20 fps and composited into '
          'the final canvas.');
    }
    final frames = _project.overlays.fold<int>(
        0, (a, o) => a + (o.duration.inMilliseconds * 20 / 1000).ceil());
    if (frames > 600) {
      notes.add('Many animated overlays: rendering will take a while.');
    }
    if (_project.clips.skip(1).any((c) => c.transition.isShader)) {
      notes.add('GL transitions are pre-rendered with the same GPU shader as '
          'the preview, then encoded into the video.');
    }
    return notes;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clock
      ..reset()
      ..start();
    _lastOutput = DateTime.now();
    _ticker?.cancel();
    // Repaint twice a second so elapsed time and FFmpeg output stay live.
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _phase == _Phase.running) setState(() {});
    });
  }

  Future<void> _start() async {
    _startClock();
    setState(() {
      _phase = _Phase.running;
      _label = 'Preparing…';
      _logLine = '';
      _fraction = 0;
      _cancelled = false;
    });
    try {
      final imagePngs = <String, Uint8List>{};
      for (final c in _project.clips) {
        if (c.type == EditorAssetType.image) {
          imagePngs[c.id] = await imageToPng(c.bytes);
        }
      }
      if (!mounted) return;
      final sequences = await renderSequences(
        context,
        _project,
        _shortSide,
        isCancelled: () => _cancelled,
        onProgress: (label, fraction) {
          if (mounted) {
            setState(() {
              _label = label;
              _fraction = fraction * .35;
            });
          }
        },
      );
      if (!mounted || _cancelled) return;
      final outcome = await _exporter.run(
        ExportRequest(
          project: _project,
          shortSide: _shortSide,
          imagePngs: imagePngs,
          sequences: sequences,
          includeMusic: _music,
        ),
        (label, fraction) {
          if (mounted) {
            setState(() {
              _label = label;
              _fraction = .35 + fraction * .65;
            });
          }
        },
        onLog: (line) {
          if (mounted && line.trim().isNotEmpty) {
            _logLine = line.trim();
            _lastOutput = DateTime.now();
          }
        },
      );
      _ticker?.cancel();
      _clock.stop();
      if (!mounted || _cancelled) return;
      if (outcome.ok) _exporter.download(outcome.bytes!, 'vlog.mp4');
      setState(() {
        _outcome = outcome;
        _phase = outcome.ok ? _Phase.done : _Phase.failed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _outcome = ExportOutcome.failure(e.toString(), const []);
        _phase = _Phase.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final (w, h) = exportSize(_project.aspectRatio, _shortSide);
    final seconds = _project.duration.inSeconds;
    final compact = MediaQuery.sizeOf(context).width < 620;
    return PopScope(
      canPop: _phase != _Phase.running,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(compact ? 12 : 24),
        child: Container(
          width: 680,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height - (compact ? 24 : 48),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(compact ? 20 : 26),
            border: Border.all(color: const Color(0xFF263348)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 48,
                offset: Offset(0, 24),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(compact),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 26,
                    20,
                    compact ? 16 : 26,
                    22,
                  ),
                  child: _body(w, h, seconds),
                ),
              ),
              _footer(compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    final (title, subtitle, icon, color) = switch (_phase) {
      _Phase.options => (
          'Export video',
          'Review your project and choose output quality',
          Icons.ios_share_rounded,
          const Color(0xFF67E8F9),
        ),
      _Phase.running => (
          'Creating your video',
          'Keep this tab open — every layer is rendered locally',
          Icons.movie_filter_rounded,
          const Color(0xFFA78BFA),
        ),
      _Phase.done => (
          'Export complete',
          'Your video was rendered and downloaded successfully',
          Icons.check_circle_rounded,
          const Color(0xFF34D399),
        ),
      _Phase.failed => (
          'Export needs attention',
          'Review the error, then retry with the suggested settings',
          Icons.error_outline_rounded,
          const Color(0xFFFB7185),
        ),
    };
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 26, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF172033), Color(0xFF111827)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF263348))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: .35)),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 18 : 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_phase != _Phase.running)
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  Widget _footer(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 26,
        vertical: 15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1220),
        border: Border(top: BorderSide(color: Color(0xFF263348))),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: _actions(),
      ),
    );
  }

  String _status() {
    final e = _clock.elapsed;
    final mm = e.inMinutes.toString().padLeft(2, '0');
    final ss = (e.inSeconds % 60).toString().padLeft(2, '0');
    final quiet = DateTime.now().difference(_lastOutput).inSeconds;
    final hint = quiet > 45
        ? ' • no FFmpeg output for ${quiet}s — it may be stuck, try Cancel + 480p'
        : '';
    return 'Elapsed $mm:$ss$hint';
  }

  Widget _panel({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF172033),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A3950)),
        ),
        child: child,
      );

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF67E8F9), size: 20),
            const SizedBox(height: 7),
            Text(value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ],
        ),
      );

  Widget _capability(IconData icon, String label, int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFA5B4FC), size: 14),
            const SizedBox(width: 6),
            Text('$label $count',
                style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  int get _activeStep {
    if (_fraction < .08) return 0;
    if (_fraction < .35) return 1;
    if (_fraction < .95) return 2;
    return 3;
  }

  Widget _steps() {
    const labels = ['Prepare', 'Render layers', 'Encode', 'Finalize'];
    const icons = [
      Icons.inventory_2_outlined,
      Icons.layers_outlined,
      Icons.memory_rounded,
      Icons.download_done_rounded,
    ];
    final active = _activeStep;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < active
                        ? const Color(0xFF10B981)
                        : i == active
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF273449),
                    border: Border.all(
                      color: i <= active
                          ? Colors.white24
                          : const Color(0xFF3B4960),
                    ),
                  ),
                  child: Icon(
                    i < active ? Icons.check_rounded : icons[i],
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: i <= active ? Colors.white : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: i == active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 25),
                color: i < active
                    ? const Color(0xFF10B981)
                    : const Color(0xFF334155),
              ),
            ),
        ],
      ],
    );
  }

  Widget _body(int w, int h, int seconds) {
    switch (_phase) {
      case _Phase.options:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panel(
              child: Row(
                children: [
                  _stat(Icons.movie_outlined, '${_project.clips.length}',
                      'Clips'),
                  const SizedBox(
                      height: 48,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(Icons.schedule_rounded, '$seconds s', 'Duration'),
                  const SizedBox(
                      height: 48,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(Icons.high_quality_rounded, '$w×$h', 'Output'),
                  const SizedBox(
                      height: 48,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(Icons.video_file_outlined, 'H.264', 'MP4'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('OUTPUT QUALITY',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 480, label: Text('480p · Draft')),
                  ButtonSegment(value: 720, label: Text('720p · HD')),
                  ButtonSegment(value: 1080, label: Text('1080p · Full HD')),
                ],
                selected: {_shortSide},
                onSelectionChanged: (s) => setState(() => _shortSide = s.first),
              ),
            ),
            const SizedBox(height: 16),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.layers_rounded,
                          color: Color(0xFFA78BFA), size: 19),
                      SizedBox(width: 8),
                      Text('Included in this export',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _capability(Icons.auto_awesome_motion_rounded,
                          'Transitions', _project.clips.length - 1),
                      _capability(
                          Icons.title_rounded,
                          'Text',
                          _project.overlays
                              .where((o) => o.type == EditorOverlayType.text)
                              .length),
                      _capability(
                          Icons.emoji_emotions_outlined,
                          'Stickers',
                          _project.overlays
                              .where((o) => o.type == EditorOverlayType.sticker)
                              .length),
                      _capability(
                          Icons.animation_rounded,
                          'Effects',
                          _project.overlays
                              .where((o) =>
                                  o.type != EditorOverlayType.text &&
                                  o.type != EditorOverlayType.sticker)
                              .length),
                      _capability(Icons.music_note_rounded, 'Audio',
                          _project.audioTracks.length),
                    ],
                  ),
                  if (_heads.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final note in _heads)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 15, color: Color(0xFF34D399)),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(note,
                                  style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 11,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (_project.audioTracks.isNotEmpty)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeTrackColor: const Color(0xFF7C3AED),
                title: const Text('Include music tracks',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                subtitle: const Text('Mix imported audio with clip sound',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                value: _music,
                onChanged: (v) => setState(() => _music = v),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF082F49),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0E7490)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: Color(0xFF67E8F9), size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Private browser export. Your media stays on this device. '
                      'For a quick proof, choose 480p; use 720p or 1080p for delivery.',
                      style: TextStyle(
                          color: Color(0xFFCFFAFE), fontSize: 11, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _Phase.running:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _steps(),
            const SizedBox(height: 24),
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${(_fraction * 100).clamp(0, 100).round()}%',
                        style: const TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 14,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 9,
                      value: _fraction <= 0 ? null : _fraction,
                      backgroundColor: const Color(0xFF273449),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Text(_status(),
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11)),
                      const Spacer(),
                      Text('$w×$h · H.264',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (_logLine.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF080D17),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_logLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: Color(0xFF64748B))),
              ),
            ],
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF94A3B8), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transitions, text, stickers and animated overlays are '
                    'being composed before FFmpeg encodes the final MP4.',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        );
      case _Phase.done:
        final mb = (_outcome!.bytes!.length / 1048576).toStringAsFixed(1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF064E3B),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF6EE7B7), size: 42),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('vlog.mp4 is ready',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 5),
            const Center(
              child: Text('The download started automatically',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
            const SizedBox(height: 20),
            _panel(
              child: Row(
                children: [
                  _stat(Icons.aspect_ratio_rounded, '$w×$h', 'Resolution'),
                  const SizedBox(
                      height: 45,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(Icons.data_usage_rounded, '$mb MB', 'File size'),
                  const SizedBox(
                      height: 45,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(
                      Icons.timer_outlined,
                      _clock.elapsed.inSeconds < 60
                          ? '${_clock.elapsed.inSeconds}s'
                          : '${_clock.elapsed.inMinutes}m ${_clock.elapsed.inSeconds % 60}s',
                      'Render time'),
                  const SizedBox(
                      height: 45,
                      child: VerticalDivider(color: Color(0xFF334155))),
                  _stat(Icons.verified_rounded, 'MP4', 'Format'),
                ],
              ),
            ),
            for (final note in _outcome!.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(note,
                          style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 11,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _Phase.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(_outcome?.error ?? 'Export failed')),
            ]),
            if (_outcome != null && _outcome!.log.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(
                      text: '${_outcome!.error}\n${_outcome!.log.join('\n')}')),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy log', style: TextStyle(fontSize: 11)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black38,
                child: SelectableText(
                  _outcome!.log.join('\n'),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.white60),
                ),
              ),
            ],
          ],
        );
    }
  }

  List<Widget> _actions() {
    switch (_phase) {
      case _Phase.options:
        return [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: _exporter.supported ? _start : null,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Start export'),
          ),
        ];
      case _Phase.running:
        return [
          TextButton(
            onPressed: () {
              _cancelled = true;
              _exporter.cancel();
              setState(() => _phase = _Phase.options);
            },
            child: const Text('Cancel export'),
          ),
        ];
      case _Phase.done:
        return [
          TextButton(
            onPressed: () => _exporter.download(_outcome!.bytes!, 'vlog.mp4'),
            child: const Text('Download another copy'),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ];
      case _Phase.failed:
        return [
          TextButton(
              onPressed: () => setState(() => _phase = _Phase.options),
              child: const Text('Back')),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ];
    }
  }
}
