import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/editor_template.dart';

/// Built-in recipes plus the user's saved templates (persisted locally).
class TemplateStore extends ChangeNotifier {
  TemplateStore({bool persist = true}) : _persist = persist {
    if (persist) _load();
  }

  static const _key = 'video_editor_templates_v1';
  final bool _persist;
  final List<EditorTemplate> builtin = buildBuiltinTemplates();
  final List<EditorTemplate> _user = [];

  List<EditorTemplate> get user => List.unmodifiable(_user);

  Iterable<EditorTemplate> byKind(EditorTemplateKind kind) =>
      [...builtin, ..._user].where((t) => t.kind == kind);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final raw in prefs.getStringList(_key) ?? const <String>[]) {
        final t = EditorTemplate.tryDecode(raw);
        if (t != null) _user.add(t);
      }
      notifyListeners();
    } catch (_) {
      // Storage unavailable (private mode): templates just stay in memory.
    }
  }

  Future<void> _save() async {
    if (!_persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, [for (final t in _user) t.encode()]);
    } catch (_) {}
  }

  void add(EditorTemplate template) {
    _user.insert(0, template);
    notifyListeners();
    _save();
  }

  void rename(String id, String name) {
    final i = _user.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = _user[i];
    _user[i] = EditorTemplate(id: t.id, name: name, kind: t.kind, data: t.data);
    notifyListeners();
    _save();
  }

  void remove(String id) {
    _user.removeWhere((t) => t.id == id);
    notifyListeners();
    _save();
  }

  /// Imports a template shared as JSON. Returns false when invalid.
  bool importJson(String source) {
    final t = EditorTemplate.tryDecode(source.trim());
    if (t == null) return false;
    add(EditorTemplate(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: t.name,
      kind: t.kind,
      data: t.data,
    ));
    return true;
  }
}
