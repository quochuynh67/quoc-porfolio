import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../screen/widget/media_ui.dart';
import '../application/template_store.dart';
import '../application/video_editor_controller.dart';
import '../domain/editor_template.dart';
import '../domain/video_editor_project.dart';
import 'editor_panels.dart';
import 'editor_preview.dart';
import 'editor_visuals.dart';
import 'export_dialog.dart';
import 'editor_timeline.dart';

class VideoEditorStudioScreen extends StatefulWidget {
  const VideoEditorStudioScreen({super.key, this.controller, this.store});

  /// Injectable for tests; the screen owns them otherwise.
  final VideoEditorController? controller;
  final TemplateStore? store;

  @override
  State<VideoEditorStudioScreen> createState() =>
      _VideoEditorStudioScreenState();
}

class _VideoEditorStudioScreenState extends State<VideoEditorStudioScreen> {
  late final VideoEditorController _controller;
  late final bool _ownsController;
  late final TemplateStore _store;
  late final bool _ownsStore;
  Timer? _playbackTimer;
  EditorTool _tool = EditorTool.media;
  String? _lastClipId;
  String? _lastOverlayId;

  late final EditorImportActions _actions = EditorImportActions(
    pickVideo: () => _pickClips(FileType.video, EditorAssetType.video),
    pickImage: () => _pickClips(FileType.image, EditorAssetType.image),
    pickAudio: _pickAudio,
    importSprite: _importSprite,
    importFxVideo: () => _pickVideoBytes((name, bytes) {
      _controller.addFxVideo(name, bytes);
      _showMessage('"$name" added to Transitions → Effect packs.');
      _selectTool(EditorTool.transitions);
    }),
    importOverlayVideo: () => _pickVideoBytes(_controller.addVideoOverlay),
    saveProjectTemplate: _saveProjectTemplate,
    saveTextTemplate: _saveTextTemplate,
    importTemplateJson: _importTemplateJson,
  );

  @override
  void initState() {
    super.initState();
    _ownsStore = widget.store == null;
    _store = widget.store ?? TemplateStore();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? VideoEditorController();
    _controller.addListener(_onControllerChanged);
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _controller.tick(),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  /// Jump to the Edit tab when the user selects something, except while they
  /// are in a tool that works on that selection already.
  void _onControllerChanged() {
    final clipId = _controller.selectedClipId;
    final overlayId = _controller.selectedOverlayId;
    final changed = (clipId != null && clipId != _lastClipId) ||
        (overlayId != null && overlayId != _lastOverlayId);
    _lastClipId = clipId;
    _lastOverlayId = overlayId;
    if (!changed || !mounted) return;

    final overlay = _controller.selectedOverlay;
    final keep = _tool == EditorTool.transitions ||
        (_tool == EditorTool.stickers &&
            overlay?.type == EditorOverlayType.sticker) ||
        _tool == EditorTool.edit;
    if (!keep) setState(() => _tool = EditorTool.edit);
  }

  void _selectTool(EditorTool tool) => setState(() => _tool = tool);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 700;
        final toolbar = _Toolbar(
          controller: _controller,
          actions: _actions,
          compact: width < 900,
          showTitle: width >= 520,
          onExport: _showExportPlan,
        );
        return Column(
          children: [
            toolbar,
            Expanded(
              child: compact
                  ? _buildCompact(constraints)
                  : _buildWide(constraints, width),
            ),
          ],
        );
      },
    );
  }

  Widget _toolPanel() => EditorToolPanel(
        tool: _tool,
        controller: _controller,
        store: _store,
        actions: _actions,
      );

  Widget _panelSurface(Widget child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: mediaPanelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediaPanelBorder),
        ),
        child: child,
      );

  Widget _buildWide(BoxConstraints constraints, double width) {
    final panelWidth = width >= 1100 ? 320.0 : 270.0;
    final tight = constraints.maxHeight < 640;
    const timelineHeight = 270.0;

    final top = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ToolRail(selected: _tool, onSelected: _selectTool),
        const SizedBox(width: 10),
        SizedBox(width: panelWidth, child: _panelSurface(_toolPanel())),
        const SizedBox(width: 10),
        Expanded(child: EditorPreview(controller: _controller)),
      ],
    );
    final timeline = EditorTimeline(
      controller: _controller,
      onTransitionTap: () => _selectTool(EditorTool.transitions),
    );

    if (tight) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(height: 460, child: top),
          const SizedBox(height: 10),
          SizedBox(height: timelineHeight, child: timeline),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Expanded(child: top),
          const SizedBox(height: 10),
          SizedBox(height: timelineHeight, child: timeline),
        ],
      ),
    );
  }

  Widget _buildCompact(BoxConstraints constraints) {
    final previewHeight =
        (constraints.maxHeight * .6).clamp(300.0, 460.0).toDouble();
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SizedBox(
            height: previewHeight,
            child: EditorPreview(controller: _controller)),
        const SizedBox(height: 10),
        SizedBox(
          height: 270,
          child: EditorTimeline(
            controller: _controller,
            onTransitionTap: () => _selectTool(EditorTool.transitions),
          ),
        ),
        const SizedBox(height: 10),
        _ToolStrip(selected: _tool, onSelected: _selectTool),
        const SizedBox(height: 8),
        SizedBox(height: 320, child: _panelSurface(_toolPanel())),
      ],
    );
  }

  // ----------------------------------------------------------- importing

  Future<void> _pickVideoBytes(
      void Function(String, Uint8List) onPicked) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webm', 'mp4', 'mov'],
        withData: true,
      );
      final file =
          result == null || result.files.isEmpty ? null : result.files.first;
      final bytes = file?.bytes;
      if (file == null || bytes == null || bytes.isEmpty) return;
      onPicked(file.name, bytes);
    } catch (error) {
      if (mounted) _showMessage('Import failed: $error', isError: true);
    }
  }

  Future<void> _importSprite() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file =
          result == null || result.files.isEmpty ? null : result.files.first;
      final bytes = file?.bytes;
      if (file == null || bytes == null || !mounted) return;
      final image = await decodeImageFromList(bytes);
      if (!mounted) return;
      final spec = await showDialog<SpriteSpec>(
        context: context,
        builder: (context) => _SpriteDialog(
          name: file.name,
          bytes: bytes,
          width: image.width,
          height: image.height,
        ),
      );
      if (spec == null) return;
      _controller.addUserSprite(spec);
      _showMessage('Sprite added. Find it in Stickers → Sprites.');
      _selectTool(EditorTool.stickers);
    } catch (error) {
      if (mounted) _showMessage('Import failed: $error', isError: true);
    }
  }

  Future<String?> _askName(String title, String initial) {
    final field = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, field.text),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _saveProjectTemplate() async {
    final name =
        (await _askName('Save project as template', 'My vlog'))?.trim();
    if (name == null || name.isEmpty) return;
    _store.add(EditorTemplate.fromProject(name, _controller.project));
    _showMessage('Template "$name" saved.');
  }

  Future<void> _saveTextTemplate() async {
    final overlay = _controller.selectedOverlay;
    if (overlay == null || overlay.type != EditorOverlayType.text) return;
    final name = (await _askName('Save text template', overlay.label))?.trim();
    if (name == null || name.isEmpty) return;
    _store.add(EditorTemplate.fromText(name, overlay));
    _showMessage('Saved. Find it under Text → Mine.');
  }

  Future<void> _importTemplateJson() async {
    final field = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import template'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: field,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
                hintText: 'Paste template JSON (from "Copy JSON")'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, field.text),
              child: const Text('Import')),
        ],
      ),
    );
    if (json == null || json.trim().isEmpty) return;
    final ok = _store.importJson(json);
    _showMessage(ok ? 'Template imported.' : 'That is not a valid template.',
        isError: !ok);
  }

  Future<void> _pickClips(FileType type, EditorAssetType assetType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      var imported = 0;
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        _controller.addClip(name: file.name, type: assetType, bytes: bytes);
        imported++;
      }
      if (imported == 0 && mounted) {
        _showMessage('Could not read the selected file.', isError: true);
      }
    } catch (error) {
      if (mounted) _showMessage('Import failed: $error', isError: true);
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
        withData: true,
      );
      final file =
          result == null || result.files.isEmpty ? null : result.files.first;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
      _controller.addAudio(file.name, bytes);
    } catch (error) {
      if (mounted) _showMessage('Import failed: $error', isError: true);
    }
  }

  void _showExportPlan() {
    final project = _controller.project;
    if (project.clips.isEmpty) {
      _showMessage('Add at least one clip before export.');
      return;
    }
    _controller.seek(_controller.position);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExportDialog(project: project),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.actions,
    required this.onExport,
    required this.compact,
    required this.showTitle,
  });

  final VideoEditorController controller;
  final EditorImportActions actions;
  final VoidCallback onExport;
  final bool compact;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFF111522),
          border: Border(bottom: BorderSide(color: mediaPanelBorder)),
        ),
        child: Row(
          children: [
            const Icon(Icons.video_camera_back_rounded,
                color: Colors.indigoAccent),
            if (showTitle) ...[
              const SizedBox(width: 8),
              const Text('Quốc Media Tools',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Undo',
              visualDensity: VisualDensity.compact,
              onPressed: controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Redo',
              visualDensity: VisualDensity.compact,
              onPressed: controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo_rounded),
            ),
            const Spacer(),
            if (!compact) ...[
              OutlinedButton.icon(
                onPressed: actions.pickVideo,
                icon: const Icon(Icons.video_library_outlined, size: 18),
                label: const Text('Video'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: actions.pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Image'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: actions.pickAudio,
                icon: const Icon(Icons.music_note_rounded, size: 18),
                label: const Text('Music'),
              ),
            ] else
              PopupMenuButton<VoidCallback>(
                tooltip: 'Import',
                icon: const Icon(Icons.add_circle_outline_rounded),
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: actions.pickVideo,
                    child: const ListTile(
                      dense: true,
                      leading: Icon(Icons.video_library_outlined),
                      title: Text('Video'),
                    ),
                  ),
                  PopupMenuItem(
                    value: actions.pickImage,
                    child: const ListTile(
                      dense: true,
                      leading: Icon(Icons.add_photo_alternate_outlined),
                      title: Text('Image'),
                    ),
                  ),
                  PopupMenuItem(
                    value: actions.pickAudio,
                    child: const ListTile(
                      dense: true,
                      leading: Icon(Icons.music_note_rounded),
                      title: Text('Music'),
                    ),
                  ),
                ],
              ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.selected, required this.onSelected});
  final EditorTool selected;
  final ValueChanged<EditorTool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mediaPanelBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final tool in EditorTool.values)
              _ToolButton(
                tool: tool,
                selected: tool == selected,
                onTap: () => onSelected(tool),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.selected,
    required this.onTap,
    this.horizontal = false,
  });

  final EditorTool tool;
  final bool selected;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.indigoAccent : Colors.white70;
    final icon = Icon(tool.icon, color: color, size: 22);
    final label = Text(tool.label,
        maxLines: 1,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400));
    return Padding(
      padding: EdgeInsets.only(
          bottom: horizontal ? 0 : 6, right: horizontal ? 6 : 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: horizontal ? 72 : 62,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.indigoAccent.withValues(alpha: .16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [icon, const SizedBox(height: 4), label],
          ),
        ),
      ),
    );
  }
}

/// Horizontal tool selector for narrow layouts.
class _ToolStrip extends StatelessWidget {
  const _ToolStrip({required this.selected, required this.onSelected});
  final EditorTool selected;
  final ValueChanged<EditorTool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111522),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mediaPanelBorder),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tool in EditorTool.values)
            _ToolButton(
              tool: tool,
              selected: tool == selected,
              horizontal: true,
              onTap: () => onSelected(tool),
            ),
        ],
      ),
    );
  }
}

class _SpriteDialog extends StatefulWidget {
  const _SpriteDialog({
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
  });
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;

  @override
  State<_SpriteDialog> createState() => _SpriteDialogState();
}

class _SpriteDialogState extends State<_SpriteDialog> {
  int _cols = 4;
  int _rows = 4;
  int? _frames;
  double _fps = 12;

  SpriteSpec get _spec => SpriteSpec(
        bytes: widget.bytes,
        cols: _cols,
        rows: _rows,
        frames: (_frames ?? _cols * _rows).clamp(1, _cols * _rows),
        fps: _fps,
        name: widget.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
      );

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value'),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: value < 32 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cell =
        '${(widget.width / _cols).round()}×${(widget.height / _rows).round()}';
    return AlertDialog(
      title: const Text('Sprite sheet'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SpriteView(spec: _spec, size: 110),
              ),
              const SizedBox(height: 12),
              _stepper(
                  'Columns',
                  _cols,
                  (v) => setState(() {
                        _cols = v;
                        _frames = null;
                      })),
              _stepper(
                  'Rows',
                  _rows,
                  (v) => setState(() {
                        _rows = v;
                        _frames = null;
                      })),
              _stepper('Frames', _frames ?? _cols * _rows,
                  (v) => setState(() => _frames = v)),
              Text(
                  'FPS ${_fps.round()}  •  sheet ${widget.width}×${widget.height}  •  cell $cell',
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
              Slider(
                value: _fps,
                min: 2,
                max: 30,
                onChanged: (v) => setState(() => _fps = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _spec),
            child: const Text('Add sprite')),
      ],
    );
  }
}
