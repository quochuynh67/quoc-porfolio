int _last = 0;

/// Strictly increasing id stamp. On the web `DateTime.microsecondsSinceEpoch`
/// only has millisecond resolution, so items added in the same millisecond
/// (e.g. several photos picked at once) would otherwise share an id.
int nextStamp() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _last = now > _last ? now : _last + 1;
  return _last;
}
