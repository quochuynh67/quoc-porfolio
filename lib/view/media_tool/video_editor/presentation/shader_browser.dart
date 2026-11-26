import 'package:flutter/material.dart';

import '../../screen/widget/media_ui.dart';
import '../domain/shader_catalog.dart';
import '../domain/video_editor_project.dart';
import 'editor_transitions.dart';

/// Searchable gallery of every GPU shader transition (gl-transitions and the
/// flag curtains). Resolves with the chosen shader id.
Future<String?> showShaderBrowser(
  BuildContext context, {
  required String? selectedId,
  required bool enabled,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ShaderBrowser(selectedId: selectedId, enabled: enabled),
  );
}

class _ShaderBrowser extends StatefulWidget {
  const _ShaderBrowser({required this.selectedId, required this.enabled});
  final String? selectedId;
  final bool enabled;

  @override
  State<_ShaderBrowser> createState() => _ShaderBrowserState();
}

class _ShaderBrowserState extends State<_ShaderBrowser> {
  String _query = '';
  String? _category; // null = all

  List<ShaderInfo> get _items {
    final q = _query.trim().toLowerCase();
    return [
      for (final s in shaderCatalog)
        if ((_category == null || s.category == _category) &&
            (q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.tags.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q)))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Dialog(
      backgroundColor: mediaPanelColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Shader transitions · ${shaderCatalog.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search  (vietnam, flag, wipe, 3d, glitch…)',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in [null, ...shaderCategories])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(c ?? 'All',
                              style: const TextStyle(fontSize: 11)),
                          selected: _category == c,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.enabled)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Select the 2nd or later clip on the timeline to apply a '
                    'transition.',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No transitions match.',
                            style: TextStyle(color: Colors.white54)))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => ShaderTile(
                          info: items[i],
                          selected: items[i].id == widget.selectedId,
                          enabled: widget.enabled,
                          onTap: () => Navigator.pop(context, items[i].id),
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hover a tile and move the pointer up and down to scrub the transition. Shaders come from gl-transitions.com '
                '(MIT); the flag curtains are original. Export uses the closest '
                'FFmpeg transition.',
                style: TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gallery tile for a shader; the thumbnail animates while hovered/selected.
class ShaderTile extends StatefulWidget {
  const ShaderTile({
    super.key,
    required this.info,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ShaderInfo info;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<ShaderTile> createState() => _ShaderTileState();
}

class _ShaderTileState extends State<ShaderTile> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: widget.enabled ? widget.onTap : null,
      child: Opacity(
        opacity: widget.enabled ? 1 : .6,
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
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: TransitionThumb(
                      type: EditorTransition.shader,
                      shaderId: widget.info.id,
                      animate: selected,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.info.name,
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
