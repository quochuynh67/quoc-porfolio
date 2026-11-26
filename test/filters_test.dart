import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/filter_catalog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/editor_visuals.dart';

void main() {
  test('filter ids are unique and categories are known', () {
    final ids = filterPresets.map((p) => p.id).toSet();
    expect(ids.length, filterPresets.length);
    expect(filterPresets.length, greaterThan(60));
    for (final p in filterPresets) {
      expect(filterCategories.contains(p.category), isTrue, reason: p.id);
      expect(p.matrix.length, 20, reason: p.id);
      expect(p.matrix.every((v) => v.isFinite), isTrue, reason: p.id);
    }
  });

  test('LUT looks bake a valid .cube and fit a sane matrix', () {
    final p = filterPresetById('lut_tealorange');
    expect(p.isLut, isTrue);
    final cube = bakeCube(p.name, p.look!, size: 5);
    expect(cube, contains('LUT_3D_SIZE 5'));
    expect(cube.trim().split('\n').length, 4 + 125);
    // Identity intensity 0 leaves colours untouched.
    final id = bakeCube('x', p.look!, intensity: 0, size: 3).split('\n');
    expect(id[4], '0.00000 0.00000 0.00000');
  });

  test('intensity blends a preset towards identity', () {
    const half = EditorFilter(preset: 'vivid', intensity: .5);
    final m = presetMatrix(half);
    expect(m[0], closeTo((1 + 1.25) / 2, 1e-9));
  });
}
