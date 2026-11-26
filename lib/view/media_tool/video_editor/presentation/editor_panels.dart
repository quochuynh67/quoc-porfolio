import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../screen/widget/media_ui.dart';
import '../application/template_store.dart';
import '../application/video_breakdown_service.dart';
import '../application/video_editor_controller.dart';
import '../domain/editor_catalog.dart';
import '../domain/editor_template.dart';
import '../domain/video_editor_project.dart';
import '../domain/shader_catalog.dart';
import 'editor_transitions.dart';
import 'shader_browser.dart';
import 'editor_visuals.dart';

enum EditorTool {
  media,
  text,
  stickers,
  transitions,
  filters,
  templates,
  edit,
  analyze,
}

extension EditorToolMeta on EditorTool {
  String get label => switch (this) {
        EditorTool.media => 'Media',
        EditorTool.text => 'Text',
        EditorTool.stickers => 'Stickers',
        EditorTool.transitions => 'Transitions',
        EditorTool.filters => 'Filters',
        EditorTool.templates => 'Templates',
        EditorTool.edit => 'Edit',
        EditorTool.analyze => 'Analyze',
      };

  IconData get icon => switch (this) {
        EditorTool.media => Icons.perm_media_outlined,
        EditorTool.text => Icons.title_rounded,
        EditorTool.stickers => Icons.emoji_emotions_outlined,
        EditorTool.transitions => Icons.auto_awesome_motion_outlined,
        EditorTool.filters => Icons.color_lens_outlined,
        EditorTool.templates => Icons.dashboard_customize_outlined,
        EditorTool.edit => Icons.tune_rounded,
        EditorTool.analyze => Icons.fact_check_outlined,
      };
}

class EditorImportActions {
  const EditorImportActions({
    required this.pickVideo,
    required this.pickImage,
    required this.pickAudio,
    required this.importSprite,
    required this.importFxVideo,
    required this.importOverlayVideo,
    required this.saveProjectTemplate,
    required this.saveTextTemplate,
    required this.importTemplateJson,
  });
  final VoidCallback pickVideo;
  final VoidCallback pickImage;
  final VoidCallback pickAudio;
  final VoidCallback importSprite;
  final VoidCallback importFxVideo;
  final VoidCallback importOverlayVideo;
  final VoidCallback saveProjectTemplate;
  final VoidCallback saveTextTemplate;
  final VoidCallback importTemplateJson;
}

/// Content of the active tool. Sized by its parent; scrolls internally.
class EditorToolPanel extends StatelessWidget {
  const EditorToolPanel({
    super.key,
    required this.tool,
    required this.controller,
    required this.store,
    required this.actions,
  });

  final EditorTool tool;
  final VideoEditorController controller;
  final TemplateStore store;
  final EditorImportActions actions;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, store]),
      builder: (context, _) => switch (tool) {
        EditorTool.media =>
          _MediaPanel(controller: controller, actions: actions),
        EditorTool.text =>
          _TextPanel(controller: controller, store: store, actions: actions),
        EditorTool.stickers =>
          _StickerPanel(controller: controller, actions: actions),
        EditorTool.transitions =>
          _TransitionPanel(controller: controller, actions: actions),
        EditorTool.filters => _FilterPanel(controller: controller),
        EditorTool.templates => _TemplatePanel(
            controller: controller, store: store, actions: actions),
        EditorTool.edit => _EditPanel(controller: controller, actions: actions),
        EditorTool.analyze => _AnalyzePanel(controller: controller),
      },
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      );
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mediaPanelBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final Iterable<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in categories)
          ChoiceChip(
            label: Text(name, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            selected: selected == name,
            onSelected: (_) => onSelected(name),
          ),
      ],
    );
  }
}

Widget _slider(
  String label,
  double value,
  double min,
  double max,
  ValueChanged<double> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}

String _sec(Duration d) => (d.inMilliseconds / 1000).toStringAsFixed(1);

// ----------------------------------------------------------------- media

class _MediaPanel extends StatelessWidget {
  const _MediaPanel({required this.controller, required this.actions});
  final VideoEditorController controller;
  final EditorImportActions actions;

  @override
  Widget build(BuildContext context) {
    final clips = controller.project.clips;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _PanelTitle('Import'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: actions.pickVideo,
              icon: const Icon(Icons.video_library_outlined, size: 18),
              label: const Text('Video'),
            ),
            OutlinedButton.icon(
              onPressed: actions.pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Image'),
            ),
            OutlinedButton.icon(
              onPressed: actions.pickAudio,
              icon: const Icon(Icons.music_note_rounded, size: 18),
              label: const Text('Music'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PanelTitle('Timeline clips (${clips.length})'),
        if (clips.isEmpty)
          const _HintBox(
            icon: Icons.video_library_outlined,
            text: 'Import a video or image to start your story.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 110,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .85,
            ),
            itemCount: clips.length,
            itemBuilder: (context, index) {
              final clip = clips[index];
              final selected = controller.selectedClipId == clip.id;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => controller.selectClip(clip.id),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242A3C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Colors.cyanAccent : mediaPanelBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox.expand(child: ClipVisual(clip: clip)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          '${index + 1}. ${clip.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (controller.project.audioTracks.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _PanelTitle('Music'),
          for (final track in controller.project.audioTracks)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => controller.removeAudio(track.id),
                    ),
                  ],
                ),
                _slider(
                  'Volume ${(track.volume * 100).round()}%',
                  track.volume,
                  0,
                  1,
                  (v) => controller.setAudioVolume(track.id, v),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ text

class _TextPanel extends StatefulWidget {
  const _TextPanel({
    required this.controller,
    required this.store,
    required this.actions,
  });
  final VideoEditorController controller;
  final TemplateStore store;
  final EditorImportActions actions;

  @override
  State<_TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<_TextPanel> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final mine = widget.store
        .byKind(EditorTemplateKind.text)
        .where((t) => !t.builtin)
        .toList();
    final items = textTemplates
        .where((t) => _category == 'All' || t.category == _category)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelTitle('Text templates (${textTemplates.length + mine.length})'),
        _CategoryChips(
          categories: [...textCategories, 'Mine'],
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 12),
        if (_category == 'Mine') ...[
          if (mine.isEmpty)
            const _HintBox(
              icon: Icons.bookmark_add_outlined,
              text: 'Select a text on the timeline, open Edit and tap '
                  '"Save as template" to reuse its style and animation.',
            )
          else
            for (final t in mine)
              Card(
                color: const Color(0xFF242A3C),
                child: ListTile(
                  dense: true,
                  title: Text(t.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Builder(builder: (context) {
                          final o = overlayFromJson(t.data, id: 'p');
                          return o == null
                              ? const SizedBox()
                              : EditorTextView(
                                  text: o.label, style: o.style, scale: .6);
                        }),
                      ),
                    ),
                  ),
                  onTap: () => widget.controller.addTextFromTemplate(t),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Copy JSON',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        onPressed: () => _copy(context, t),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        onPressed: () => widget.store.remove(t.id),
                      ),
                    ],
                  ),
                ),
              ),
        ] else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 90,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final template = items[index];
              final animated = template.enter != OverlayEnter.none ||
                  template.loop != OverlayLoop.none;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => widget.controller.addText(template),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B3552), Color(0xFF1B2133)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mediaPanelBorder),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: EditorTextView(
                              text: template.sample,
                              style: template.style,
                              scale: .62,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(template.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 9)),
                          ),
                          if (animated)
                            const Icon(Icons.motion_photos_on_rounded,
                                size: 12, color: Colors.amberAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, EditorTemplate t) async {
    await Clipboard.setData(ClipboardData(text: t.encode()));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Template JSON copied')));
    }
  }
}

// -------------------------------------------------------------- stickers

class _StickerPanel extends StatefulWidget {
  const _StickerPanel({required this.controller, required this.actions});
  final VideoEditorController controller;
  final EditorImportActions actions;

  @override
  State<_StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<_StickerPanel> {
  static const _sprites = 'Sprites';
  static const _particles = 'Particles';
  static const _video = 'WebM';
  String _category = stickerCategories.keys.first;

  @override
  Widget build(BuildContext context) {
    final names = [..._stickerKeys, _sprites, _particles, _video];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _PanelTitle('Stickers & effects'),
        _CategoryChips(
          categories: names,
          selected: _category,
          onSelected: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 12),
        if (_category == _sprites)
          _spriteGrid()
        else if (_category == _particles)
          _particleGrid()
        else if (_category == _video)
          _videoOverlay()
        else
          _emojiGrid(),
      ],
    );
  }

  Iterable<String> get _stickerKeys => stickerCategories.keys;

  Widget _emojiGrid() {
    final items = stickerCategories[_category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 78,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final sticker = items[index];
            return _tile(
              tooltip: sticker.name,
              onTap: () => widget.controller.addSticker(sticker),
              child: EditorStickerView(emoji: sticker.emoji, size: 56),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text('Stickers load from the Noto Emoji / Twemoji CDNs.',
            style: TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }

  Widget _tile({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mediaPanelBorder),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _spriteGrid() {
    final all = [...builtinSprites, ...widget.controller.userSprites];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 90,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: all.length,
          itemBuilder: (context, i) => _tile(
            tooltip: all[i].name,
            onTap: () => widget.controller.addSprite(all[i]),
            child: SpriteView(spec: all[i]),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.actions.importSprite,
          icon: const Icon(Icons.grid_on_rounded, size: 18),
          label: const Text('Import sprite sheet'),
        ),
        const SizedBox(height: 8),
        const Text(
            'Sprite sheets: a PNG grid of frames. Built-ins come from the '
            'Phaser examples repository on GitHub.',
            style: TextStyle(color: Colors.white30, fontSize: 10, height: 1.4)),
      ],
    );
  }

  Widget _particleGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: particleStickers.length,
      itemBuilder: (context, i) {
        final entry = particleStickers.entries.elementAt(i);
        return Tooltip(
          message: entry.value,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.controller.addParticles(entry.key),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF0C0F18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mediaPanelBorder),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ParticleView(kind: entry.key),
                  Positioned(
                    left: 8,
                    bottom: 6,
                    child: Text(entry.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _videoOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HintBox(
          icon: Icons.movie_filter_outlined,
          text: 'Import a WebM / MP4 effect (fire, light leaks, confetti '
              'on a black background). It is added as an overlay and '
              'composited with screen blend.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.actions.importOverlayVideo,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Import WebM / MP4 overlay'),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- transitions

class _TransitionPanel extends StatelessWidget {
  const _TransitionPanel({required this.controller, required this.actions});
  final VideoEditorController controller;
  final EditorImportActions actions;

  @override
  Widget build(BuildContext context) {
    final clip = controller.selectedClip;
    final clips = controller.project.clips;
    final index = clip == null ? -1 : clips.indexWhere((c) => c.id == clip.id);
    final canApply = clip != null && index > 0;
    final basics = EditorTransition.values
        .where((t) => t != EditorTransition.fx && !t.isShader)
        .toList();
    final featured = [
      for (final id in featuredShaderIds)
        if (shaderById(id) != null) shaderById(id)!,
    ];
    final fxPacks = [
      for (final s in builtinSprites.take(3))
        EditorFx(id: 'builtin_${s.name}', name: s.name, sprite: s),
      for (final s in controller.userSprites)
        EditorFx(id: 'sprite_${s.cacheKey}', name: s.name, sprite: s),
      ...controller.fxLibrary,
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelTitle(
          'Transitions',
          trailing: clips.length > 1
              ? TextButton(
                  onPressed: clip == null
                      ? null
                      : () => controller.applyTransitionToAll(clip.transition,
                          shaderId: clip.shaderId),
                  child: const Text('Apply to all',
                      style: TextStyle(fontSize: 11)),
                )
              : null,
        ),
        _HintBox(
          icon: canApply ? Icons.touch_app_rounded : Icons.info_outline,
          text: clips.length < 2
              ? 'Add at least two clips, then pick a transition.'
              : canApply
                  ? 'Applies to the cut into "${clip.name}". Tap a style to preview it.'
                  : 'Select the 2nd or later clip on the timeline (or tap the '
                      '● marker between clips) to set the transition into it.',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 96,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .78,
          ),
          itemCount: basics.length,
          itemBuilder: (context, i) {
            final type = basics[i];
            final selected = canApply && clip.transition == type;
            return _TransitionTile(
              label: type.label,
              selected: selected,
              enabled: canApply,
              onTap: () => controller.updateSelectedTransition(type),
              thumb: TransitionThumb(type: type),
            );
          },
        ),
        _Label('SHADERS · ${shaderCatalog.length} (gl-transitions + flags)'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: featured.length,
          itemBuilder: (context, i) {
            final info = featured[i];
            return ShaderTile(
              info: info,
              selected: canApply &&
                  clip.transition == EditorTransition.shader &&
                  clip.shaderId == info.id,
              enabled: canApply,
              onTap: () => controller.updateSelectedTransition(
                  EditorTransition.shader,
                  shaderId: info.id),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final id = await showShaderBrowser(
              context,
              selectedId: canApply && clip.transition == EditorTransition.shader
                  ? clip.shaderId
                  : null,
              enabled: canApply,
            );
            if (id != null) {
              controller.updateSelectedTransition(EditorTransition.shader,
                  shaderId: id);
            }
          },
          icon: const Icon(Icons.travel_explore_rounded, size: 18),
          label: Text('Browse all ${shaderCatalog.length} shaders'),
        ),
        const _Label('EFFECT PACKS (sprite & WebM)'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 96,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .78,
          ),
          itemCount: fxPacks.length,
          itemBuilder: (context, i) {
            final fx = fxPacks[i];
            final selected = canApply &&
                clip.transition == EditorTransition.fx &&
                clip.fx?.id == fx.id;
            return _TransitionTile(
              label: fx.name,
              selected: selected,
              enabled: canApply,
              onTap: () => controller.setSelectedClipFx(fx),
              thumb: fx.video != null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFF1B2133)),
                      child: Center(
                          child: Icon(Icons.movie_filter_rounded,
                              color: Colors.amberAccent)))
                  : TransitionThumb(type: EditorTransition.fx, fx: fx),
            );
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: actions.importFxVideo,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('WebM / MP4'),
            ),
            OutlinedButton.icon(
              onPressed: actions.importSprite,
              icon: const Icon(Icons.grid_on_rounded, size: 18),
              label: const Text('Sprite sheet'),
            ),
          ],
        ),
        if (canApply && clip.transition != EditorTransition.none) ...[
          const SizedBox(height: 16),
          _slider(
            'Duration ${_sec(clip.transitionDuration)}s',
            clip.transitionDuration.inMilliseconds.toDouble(),
            200,
            2000,
            (value) => controller.updateSelectedTransition(
              clip.transition,
              duration: Duration(milliseconds: value.round()),
            ),
          ),
        ],
      ],
    );
  }
}

class _TransitionTile extends StatelessWidget {
  const _TransitionTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.thumb,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget thumb;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : .55,
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.cyanAccent : Colors.white12,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: SizedBox.expand(child: thumb),
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? Colors.cyanAccent : Colors.white60,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- filters

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.controller});
  final VideoEditorController controller;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  String _category = 'All';

  VideoEditorController get controller => widget.controller;

  Future<void> _importCube() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cube'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      String? firstError;
      var added = 0;
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final error = controller.importCubeLut(
            file.name, String.fromCharCodes(bytes),
            apply: added == 0 && result.files.length == 1);
        if (error == null) {
          added++;
        } else {
          firstError ??= '${file.name}: $error';
        }
      }
      if (added > 0) setState(() => _category = categoryCustom);
      if (firstError != null) {
        messenger?.showSnackBar(
            SnackBar(content: Text('LUT import failed — $firstError')));
      }
    } catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text('LUT import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = controller.selectedClip;
    if (clip == null) {
      return ListView(
        padding: const EdgeInsets.all(14),
        children: const [
          _PanelTitle('Filters'),
          _HintBox(
            icon: Icons.touch_app_rounded,
            text: 'Select a clip on the timeline to colour-grade it.',
          ),
        ],
      );
    }
    final filter = clip.filter;
    final shown = [
      for (final p in [...filterPresets, ...customLuts])
        if (_category == 'All' || p.category == _category) p,
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelTitle(
          'Filters',
          trailing: TextButton(
            onPressed: () => controller.applyFilterToAll(filter),
            child: const Text('Apply to all', style: TextStyle(fontSize: 11)),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in ['All', ...filterCategories])
              ChoiceChip(
                label: Text(c, style: const TextStyle(fontSize: 11)),
                selected: _category == c,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _importCube,
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: const Text('Import LUT (.cube)'),
        ),
        if (_category == categoryCustom && customLuts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'No LUTs yet. Import a 3D .cube file (Resolve, Lightroom, '
                'Photoshop, free LUT packs…). LUTs stay for this session.',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 104,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .78,
          ),
          itemCount: shown.length,
          itemBuilder: (context, i) {
            final p = shown[i];
            final selected = filter.preset == p.id;
            final tile = InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => controller
                  .setSelectedClipFilter(filter.copyWith(preset: p.id)),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? Colors.cyanAccent : Colors.white12,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: SizedBox.expand(
                        child: FilteredClip(
                          filter: EditorFilter(preset: p.id),
                          child: clip.type == EditorAssetType.image
                              ? Image.memory(clip.bytes, fit: BoxFit.cover)
                              : Image.asset(
                                  'assets/images/transitions/demo_a.jpg',
                                  fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.name,
                      maxLines: 1,
                      style: TextStyle(
                          color: selected ? Colors.cyanAccent : Colors.white60,
                          fontSize: 10)),
                ],
              ),
            );
            if (p.category != categoryCustom) return tile;
            return Stack(
              children: [
                Positioned.fill(child: tile),
                Positioned(
                  top: 3,
                  right: 3,
                  child: GestureDetector(
                    onTap: () => controller.removeCustomLut(p.id),
                    child: const CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close_rounded,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (filterPresetById(filter.preset).isLut)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'LUT look: the preview is an approximation, the export applies '
                'the full 3D LUT (lut3d).',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        const SizedBox(height: 12),
        if (filter.preset != 'none')
          _slider(
            'Intensity ${(filter.intensity * 100).round()}%',
            filter.intensity,
            0,
            1,
            (v) =>
                controller.setSelectedClipFilter(filter.copyWith(intensity: v)),
          ),
        _slider(
          'Brightness ${(filter.brightness * 100).round()}',
          filter.brightness,
          -1,
          1,
          (v) =>
              controller.setSelectedClipFilter(filter.copyWith(brightness: v)),
        ),
        _slider(
          'Contrast ${(filter.contrast * 100).round()}',
          filter.contrast,
          -.8,
          1,
          (v) => controller.setSelectedClipFilter(filter.copyWith(contrast: v)),
        ),
        _slider(
          'Saturation ${(filter.saturation * 100).round()}',
          filter.saturation,
          -1,
          1,
          (v) =>
              controller.setSelectedClipFilter(filter.copyWith(saturation: v)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: filter.isIdentity
                ? null
                : () => controller.setSelectedClipFilter(const EditorFilter()),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- templates

class _TemplatePanel extends StatelessWidget {
  const _TemplatePanel({
    required this.controller,
    required this.store,
    required this.actions,
  });
  final VideoEditorController controller;
  final TemplateStore store;
  final EditorImportActions actions;

  @override
  Widget build(BuildContext context) {
    final projects = store.byKind(EditorTemplateKind.project).toList();
    final text = store.user.where((t) => t.kind == EditorTemplateKind.text);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelTitle(
          'Vlog templates',
          trailing: TextButton.icon(
            onPressed: actions.importTemplateJson,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Import', style: TextStyle(fontSize: 11)),
          ),
        ),
        const Text(
          'A template is the recipe of a vlog — canvas, text, stickers, '
          'transitions and colour grade — without your media. Apply it to any '
          'project.',
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: controller.project.clips.isEmpty &&
                  controller.project.overlays.isEmpty
              ? null
              : actions.saveProjectTemplate,
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Save project as template'),
        ),
        const SizedBox(height: 14),
        for (final t in projects) _projectCard(context, t),
        if (text.isNotEmpty) ...[
          const _Label('SAVED TEXT STYLES'),
          const Text('Find them under Text → Mine.',
              style: TextStyle(color: Colors.white30, fontSize: 11)),
        ],
      ],
    );
  }

  Widget _projectCard(BuildContext context, EditorTemplate t) {
    final d = t.data;
    final overlays = (d['overlays'] as List?)?.length ?? 0;
    final aspect = ((d['aspect'] ?? 9 / 16) as num).toDouble();
    final label = aspectPresets
        .firstWhere((p) => (p.$2 - aspect).abs() < .01,
            orElse: () => (aspect.toStringAsFixed(2), aspect))
        .$1;
    return Card(
      color: const Color(0xFF242A3C),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                if (t.builtin)
                  const Chip(
                    label: Text('Built-in', style: TextStyle(fontSize: 10)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$label • $overlays overlays',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    controller.applyProjectTemplate(t);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Applied "${t.name}"')),
                    );
                  },
                  child: const Text('Apply'),
                ),
                if (!t.builtin) ...[
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: t.encode()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Template JSON copied')),
                        );
                      }
                    },
                    child: const Text('Copy JSON'),
                  ),
                  TextButton(
                    onPressed: () => store.remove(t.id),
                    child: const Text('Delete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ edit

class _EditPanel extends StatelessWidget {
  const _EditPanel({required this.controller, required this.actions});
  final VideoEditorController controller;
  final EditorImportActions actions;

  @override
  Widget build(BuildContext context) {
    final clip = controller.selectedClip;
    final overlay = controller.selectedOverlay;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (clip != null)
          ..._clipControls(clip)
        else if (overlay != null)
          ..._overlayControls(overlay)
        else
          ..._canvasControls(),
      ],
    );
  }

  List<Widget> _canvasControls() {
    final p = controller.project;
    return [
      const _PanelTitle('Canvas'),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final (label, ratio) in aspectPresets)
            ChoiceChip(
              label: Text(label),
              selected: (p.aspectRatio - ratio).abs() < .01,
              onSelected: (_) => controller.updateAspectRatio(ratio),
            ),
        ],
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('Fit whole frame (no crop)',
            style: TextStyle(fontSize: 12)),
        value: p.fitContain,
        onChanged: controller.setFitContain,
      ),
      const SizedBox(height: 12),
      const _HintBox(
        icon: Icons.touch_app_rounded,
        text: 'Select a clip, text or sticker on the timeline to edit it.',
      ),
    ];
  }

  List<Widget> _clipControls(EditorClip clip) {
    final clips = controller.project.clips;
    final index = clips.indexWhere((c) => c.id == clip.id);
    final isImage = clip.type == EditorAssetType.image;
    final source = clip.sourceDuration;
    return [
      _PanelTitle(isImage ? 'Image clip' : 'Video clip'),
      Text(clip.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 10),
      if (isImage)
        _slider(
          'Duration ${_sec(clip.duration)}s',
          clip.duration.inMilliseconds / 1000,
          1,
          15,
          (v) => controller.updateClipDuration(
            clip.id,
            Duration(milliseconds: (v * 1000).round()),
            undoable: true,
          ),
        )
      else if (source != null) ...[
        Text(
          'Trim ${_sec(clip.trimStart)}s – ${_sec(clip.trimEnd)}s of ${_sec(source)}s',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        RangeSlider(
          values: RangeValues(
            (clip.trimStart.inMilliseconds / 1000)
                .clamp(0, source.inMilliseconds / 1000),
            (clip.trimEnd.inMilliseconds / 1000)
                .clamp(0, source.inMilliseconds / 1000),
          ),
          min: 0,
          max: source.inMilliseconds / 1000,
          onChanged: (values) => controller.trimSelectedClip(
            inPoint: Duration(milliseconds: (values.start * 1000).round()),
            outPoint: Duration(milliseconds: (values.end * 1000).round()),
          ),
        ),
        _slider(
          'Speed ${clip.speed.toStringAsFixed(2)}x',
          clip.speed,
          .25,
          4,
          controller.setSelectedClipSpeed,
        ),
        _slider(
          'Volume ${(clip.volume * 100).round()}%',
          clip.volume,
          0,
          1,
          controller.setSelectedClipVolume,
        ),
      ] else
        const Text('Loading video…',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: index > 0 ? () => controller.moveSelectedClip(-1) : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Earlier'),
          ),
          OutlinedButton.icon(
            onPressed: index < clips.length - 1
                ? () => controller.moveSelectedClip(1)
                : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Later'),
          ),
          OutlinedButton.icon(
            onPressed: controller.splitSelectedClip,
            icon: const Icon(Icons.content_cut_rounded, size: 16),
            label: const Text('Split'),
          ),
          OutlinedButton.icon(
            onPressed: controller.removeSelection,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        index > 0
            ? 'Transition in: ${clip.transition.isShader ? (shaderById(clip.shaderId)?.name ?? 'Shader') : clip.transition.label}. Open the Transitions tab to change it. '
                'Filter: ${filterPresets.firstWhere((p) => p.id == clip.filter.preset, orElse: () => filterPresets.first).name}.'
            : 'First clip — transitions apply from the 2nd clip on.',
        style:
            const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
      ),
    ];
  }

  Widget _animChips<T extends Enum>(
    List<T> values,
    T current,
    void Function(T) onSelected, {
    bool Function(T)? only,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final v in values)
          if (only == null || only(v))
            ChoiceChip(
              label: Text(v.label, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              selected: v == current,
              onSelected: (_) => onSelected(v),
            ),
      ],
    );
  }

  List<Widget> _overlayControls(EditorOverlay o) {
    final isText = o.type == EditorOverlayType.text;
    final total = controller.project.duration;
    final maxStart = total.inMilliseconds.toDouble();
    final title = switch (o.type) {
      EditorOverlayType.text => 'Text',
      EditorOverlayType.sticker => 'Sticker',
      EditorOverlayType.sprite => 'Sprite',
      EditorOverlayType.particles => 'Particles',
      EditorOverlayType.video => 'Video overlay',
    };
    return [
      _PanelTitle(title),
      if (isText)
        TextFormField(
          key: ValueKey(o.id),
          initialValue: o.label,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Content'),
          onChanged: (value) => controller.updateSelectedOverlay(label: value),
        )
      else
        Text(o.label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 4),
      _slider(
        'Scale ${(o.scale * 100).round()}%',
        o.scale,
        .3,
        4,
        (v) => controller.updateSelectedOverlay(scale: v),
      ),
      _slider(
        'Rotate ${(o.rotation * 57.2958).round()}°',
        o.rotation,
        -3.1416,
        3.1416,
        (v) => controller.updateSelectedOverlay(rotation: v),
      ),
      if (total > Duration.zero) ...[
        _slider(
          'Start ${_sec(o.start)}s',
          o.start.inMilliseconds.toDouble(),
          0,
          maxStart,
          (v) => controller.updateSelectedOverlay(
              start: Duration(milliseconds: v.round())),
        ),
        _slider(
          'Length ${_sec(o.duration)}s',
          o.duration.inMilliseconds.toDouble(),
          500,
          20000,
          (v) => controller.updateSelectedOverlay(
              duration: Duration(milliseconds: v.round())),
        ),
      ],
      if (o.type == EditorOverlayType.text ||
          o.type == EditorOverlayType.sticker ||
          o.type == EditorOverlayType.sprite) ...[
        const _Label('ENTER ANIMATION'),
        _animChips<OverlayEnter>(
          OverlayEnter.values,
          o.enter,
          (v) => controller.updateSelectedOverlay(enter: v),
          only: (v) =>
              isText ||
              (v != OverlayEnter.typewriter && v != OverlayEnter.letterRise),
        ),
        const _Label('EXIT ANIMATION'),
        _animChips<OverlayExit>(
          OverlayExit.values,
          o.exit,
          (v) => controller.updateSelectedOverlay(exit: v),
        ),
        const _Label('LOOP'),
        _animChips<OverlayLoop>(
          OverlayLoop.values,
          o.loop,
          (v) => controller.updateSelectedOverlay(loop: v),
          only: (v) =>
              isText || (v != OverlayLoop.wave && v != OverlayLoop.glitch),
        ),
      ],
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: controller.previewSelectedOverlay,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Preview'),
          ),
          if (isText)
            OutlinedButton.icon(
              onPressed: actions.saveTextTemplate,
              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
              label: const Text('Save as template'),
            ),
          OutlinedButton.icon(
            onPressed: controller.removeSelection,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
          ),
        ],
      ),
    ];
  }
}

// --------------------------------------------------------------- analyze

class _AnalyzePanel extends StatelessWidget {
  const _AnalyzePanel({required this.controller});
  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    final markdown =
        const VideoBreakdownService().buildVideoMarkdown(controller.project);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _PanelTitle(
          'Project breakdown',
          trailing: TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: markdown));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('VIDEO.md copied')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy', style: TextStyle(fontSize: 12)),
          ),
        ),
        const Text(
          'Generated from the timeline in the rea-video VIDEO.md layout: shots, '
          'transitions, overlays, sound, rhythm and a remake checklist.',
          style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0F18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mediaPanelBorder),
          ),
          child: SelectableText(
            markdown,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
