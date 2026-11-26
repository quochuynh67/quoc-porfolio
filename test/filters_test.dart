import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/application/video_editor_controller.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/filter_catalog.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/domain/video_editor_project.dart';
import 'package:flutter_portfolio/view/media_tool/video_editor/presentation/editor_visuals.dart';

void main() {
  cubeTests();
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

void cubeTests() {
  const identity = '''
# test
TITLE "Warm test"
LUT_3D_SIZE 2
0 0 0
1 0 0
0 1 0
1 1 0
0 0 1
1 0 1
0 1 1
1 1 1
''';

  test('parses a .cube and samples it trilinearly', () {
    final cube = CubeLut.parse(identity);
    expect(cube.title, 'Warm test');
    final o = cube.sample(.25, .5, .75);
    expect(o[0], closeTo(.25, 1e-9));
    expect(o[1], closeTo(.5, 1e-9));
    expect(o[2], closeTo(.75, 1e-9));
    // An identity LUT fits an identity matrix.
    final m = fitMatrixFn(cube.sample);
    for (var i = 0; i < 20; i++) {
      expect(m[i], closeTo(identityMatrix[i], 1e-6), reason: '$i');
    }
  });

  test('rejects bad .cube files with a message', () {
    expect(() => CubeLut.parse('LUT_1D_SIZE 4\n0 0 0'),
        throwsA(isA<FormatException>()));
    expect(() => CubeLut.parse('LUT_3D_SIZE 2\n0 0 0\n1 1 1'),
        throwsA(isA<FormatException>()));
  });

  test('intensity blends a .cube towards identity', () {
    final warm = identity
        .replaceAll('1 1 1', '1 1 1')
        .replaceFirst('0 0 0\n1 0 0', '0.2 0.2 0.2\n1 0 0');
    final cube = CubeLut.parse(warm);
    final half = CubeLut.parse(cube.toText(.5));
    expect(half.data[0], closeTo(.1, 1e-4));
  });

  test('controller imports a LUT and applies it to the clip', () {
    final c = VideoEditorController();
    expect(c.importCubeLut('bad.cube', 'nope'), isNotNull);
    expect(c.importCubeLut('good.cube', identity), isNull);
    expect(customLuts.single.name, 'Warm test');
    c.removeCustomLut(customLuts.single.id);
    expect(customLuts, isEmpty);
  });
}
