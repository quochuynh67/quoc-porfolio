import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  double _fraction = 0;
  ExportOutcome? _outcome;

  VideoEditorProject get _project => widget.project;

  List<String> get _heads {
    final notes = <String>[];
    for (final o in _project.overlays.where((o) => !isExportableOverlay(o))) {
      notes.add('${o.type.name} "${o.label}" is skipped (only text and '
          'emoji stickers are rendered).');
    }
    if (_project.clips.any((c) => c.transition == EditorTransition.fx)) {
      notes.add('Sprite / WebM effect packs in transitions become a flash.');
    }
    if (_project.overlays.any((o) =>
        isExportableOverlay(o) &&
        (o.enter != OverlayEnter.none ||
            o.exit != OverlayExit.none ||
            o.loop != OverlayLoop.none))) {
      notes.add('Text / sticker animations are exported as static overlays.');
    }
    return notes;
  }

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.running;
      _label = 'Preparing overlays…';
      _fraction = 0;
    });
    try {
      final imagePngs = <String, Uint8List>{};
      for (final c in _project.clips) {
        if (c.type == EditorAssetType.image) {
          imagePngs[c.id] = await imageToPng(c.bytes);
        }
      }
      if (!mounted) return;
      final overlayPngs =
          await renderOverlayPngs(context, _project, _shortSide);
      if (!mounted) return;
      final outcome = await _exporter.run(
        ExportRequest(
          project: _project,
          shortSide: _shortSide,
          imagePngs: imagePngs,
          overlayPngs: overlayPngs,
          includeMusic: _music,
        ),
        (label, fraction) {
          if (mounted) {
            setState(() {
              _label = label;
              _fraction = fraction;
            });
          }
        },
      );
      if (!mounted) return;
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
    return PopScope(
      canPop: _phase != _Phase.running,
      child: AlertDialog(
        title: const Text('Export video'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(child: _body(w, h, seconds)),
        ),
        actions: _actions(),
      ),
    );
  }

  Widget _body(int w, int h, int seconds) {
    switch (_phase) {
      case _Phase.options:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_project.clips.length} clips • ${seconds}s • MP4 (H.264)',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            const Text('Quality', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 480, label: Text('480p')),
                ButtonSegment(value: 720, label: Text('720p')),
                ButtonSegment(value: 1080, label: Text('1080p')),
              ],
              selected: {_shortSide},
              onSelectionChanged: (s) => setState(() => _shortSide = s.first),
            ),
            const SizedBox(height: 6),
            Text('Output ${w}×$h',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            if (_project.audioTracks.isNotEmpty)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title:
                    const Text('Include music', style: TextStyle(fontSize: 13)),
                value: _music,
                onChanged: (v) => setState(() => _music = v),
              ),
            const SizedBox(height: 10),
            Text(
              'Rendering runs inside your browser with FFmpeg WebAssembly, so '
              'it is slow: roughly 1–3 minutes per 30 s at 720p. Keep this tab '
              'open. Use 480p for a quick test.',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11, height: 1.4),
            ),
            for (final note in _heads)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(note,
                            style: const TextStyle(
                                color: Colors.amberAccent, fontSize: 11))),
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
            Text(_label),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _fraction <= 0 ? null : _fraction),
            const SizedBox(height: 10),
            const Text('Do not close this tab while exporting.',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        );
      case _Phase.done:
        final mb = (_outcome!.bytes!.length / 1048576).toStringAsFixed(1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('vlog.mp4 • $mb MB downloaded'),
            ]),
            for (final note in _outcome!.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(note,
                    style: const TextStyle(
                        color: Colors.amberAccent, fontSize: 11)),
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
              const SizedBox(height: 10),
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
            icon: const Icon(Icons.movie_creation_outlined, size: 18),
            label: const Text('Render'),
          ),
        ];
      case _Phase.running:
        return const [];
      case _Phase.done:
        return [
          TextButton(
            onPressed: () => _exporter.download(_outcome!.bytes!, 'vlog.mp4'),
            child: const Text('Download again'),
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
