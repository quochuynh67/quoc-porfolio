import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Colour-grading catalogue.
///
/// Two kinds of presets:
///  * **Colour filters** – a 4x5 colour matrix. Preview and export (FFmpeg
///    `colorchannelmixer`) are identical.
///  * **LUT looks** – a procedural 3D LUT (tone curves, split toning, fade…)
///    baked to a `.cube` file for the FFmpeg `lut3d` filter on export. The
///    live preview uses the least-squares colour matrix fitted to the LUT.
@immutable
class FilterPreset {
  const FilterPreset._(
      this.id, this.name, this.category, this._matrix, this.look, this.cube);

  factory FilterPreset(
          String id, String name, String category, List<double> matrix) =>
      FilterPreset._(id, name, category, matrix, null, null);

  factory FilterPreset.lut(
          String id, String name, String category, LookSpec look) =>
      FilterPreset._(id, name, category, null, look, null);

  /// A LUT imported from a `.cube` file.
  factory FilterPreset.cube(String id, String name, CubeLut cube) =>
      FilterPreset._(id, name, categoryCustom, null, null, cube);

  final String id;
  final String name;
  final String category;
  final List<double>? _matrix;
  final LookSpec? look;
  final CubeLut? cube;

  bool get isLut => look != null || cube != null;

  /// 4x5 colour matrix used for the live preview.
  List<double> get matrix =>
      _matrix ??
      _fitted.putIfAbsent(
          id, () => fitMatrixFn(cube != null ? cube!.sample : look!.apply));
}

final _fitted = <String, List<double>>{};

const identityMatrix = <double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

// ------------------------------------------------------------- procedural LUT

/// Parameters of a procedural grade, applied per RGB sample (values 0..1).
@immutable
class LookSpec {
  const LookSpec({
    this.exposure = 1,
    this.gain = const [1, 1, 1],
    this.gamma = const [1, 1, 1],
    this.contrast = 1,
    this.curve = 0,
    this.sat = 1,
    this.fade = 0,
    this.shadow = const [0, 0, 0],
    this.highlight = const [0, 0, 0],
    this.mono = false,
  });

  final double exposure;
  final List<double> gain;
  final List<double> gamma;
  final double contrast;

  /// 0..1 – blend towards a smooth S-curve.
  final double curve;
  final double sat;

  /// Lifted blacks (0..0.3).
  final double fade;

  /// Additive tint weighted towards shadows / highlights.
  final List<double> shadow;
  final List<double> highlight;
  final bool mono;

  List<double> apply(double r, double g, double b) {
    var c = [r, g, b];
    double luma(List<double> v) => .2126 * v[0] + .7152 * v[1] + .0722 * v[2];
    if (mono) {
      final l = luma(c);
      c = [l, l, l];
    }
    for (var i = 0; i < 3; i++) {
      var v = c[i] * exposure * gain[i];
      v = math.pow(v.clamp(0.0, 1.0), 1 / gamma[i]).toDouble();
      v = (v - .5) * contrast + .5;
      v = v.clamp(0.0, 1.0);
      if (curve > 0) {
        final s = v * v * (3 - 2 * v);
        v = v + (s - v) * curve;
      }
      c[i] = v;
    }
    final l = luma(c);
    for (var i = 0; i < 3; i++) {
      var v = l + (c[i] - l) * sat;
      v += shadow[i] * (1 - l) * (1 - l) + highlight[i] * l * l;
      v = fade + v * (1 - fade);
      c[i] = v.clamp(0.0, 1.0);
    }
    return c;
  }
}

/// Bakes [look] into a `.cube` 3D LUT; [intensity] blends with the original.
String bakeCube(String title, LookSpec look,
    {double intensity = 1, int size = 25}) {
  final b = StringBuffer()
    ..writeln('TITLE "$title"')
    ..writeln('LUT_3D_SIZE $size')
    ..writeln('DOMAIN_MIN 0 0 0')
    ..writeln('DOMAIN_MAX 1 1 1');
  final n = size - 1;
  for (var bi = 0; bi < size; bi++) {
    for (var gi = 0; gi < size; gi++) {
      for (var ri = 0; ri < size; ri++) {
        final r = ri / n, g = gi / n, bl = bi / n;
        final o = look.apply(r, g, bl);
        final rr = r + (o[0] - r) * intensity;
        final gg = g + (o[1] - g) * intensity;
        final bb = bl + (o[2] - bl) * intensity;
        b.writeln('${rr.toStringAsFixed(5)} ${gg.toStringAsFixed(5)} '
            '${bb.toStringAsFixed(5)}');
      }
    }
  }
  return b.toString();
}

/// Least-squares fit of a 4x5 colour matrix (offsets in 0..255) to [look].
List<double> fitMatrix(LookSpec look) => fitMatrixFn(look.apply);

List<double> fitMatrixFn(List<double> Function(double, double, double) fn) {
  const n = 9;
  final xs = <List<double>>[];
  final ys = <List<double>>[];
  for (var r = 0; r < n; r++) {
    for (var g = 0; g < n; g++) {
      for (var b = 0; b < n; b++) {
        final x = [r / (n - 1), g / (n - 1), b / (n - 1)];
        xs.add(x);
        ys.add(fn(x[0], x[1], x[2]));
      }
    }
  }
  // Normal equations (X^T X) w = X^T y with X = [r g b 1].
  final a = List.generate(4, (_) => List<double>.filled(4, 0));
  final rhs = List.generate(3, (_) => List<double>.filled(4, 0));
  for (var s = 0; s < xs.length; s++) {
    final row = [...xs[s], 1.0];
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        a[i][j] += row[i] * row[j];
      }
      for (var c = 0; c < 3; c++) {
        rhs[c][i] += row[i] * ys[s][c];
      }
    }
  }
  final out = List<double>.from(identityMatrix);
  for (var c = 0; c < 3; c++) {
    final w = _solve(a, rhs[c]);
    out[c * 5 + 0] = w[0];
    out[c * 5 + 1] = w[1];
    out[c * 5 + 2] = w[2];
    out[c * 5 + 4] = w[3] * 255;
  }
  return out;
}

List<double> _solve(List<List<double>> a, List<double> y) {
  final n = y.length;
  final m = [
    for (var i = 0; i < n; i++) [...a[i], y[i]],
  ];
  for (var i = 0; i < n; i++) {
    var p = i;
    for (var r = i + 1; r < n; r++) {
      if (m[r][i].abs() > m[p][i].abs()) p = r;
    }
    final t = m[i];
    m[i] = m[p];
    m[p] = t;
    final d = m[i][i];
    if (d.abs() < 1e-12) continue;
    for (var j = i; j <= n; j++) {
      m[i][j] /= d;
    }
    for (var r = 0; r < n; r++) {
      if (r == i) continue;
      final f = m[r][i];
      for (var j = i; j <= n; j++) {
        m[r][j] -= f * m[i][j];
      }
    }
  }
  return [for (var i = 0; i < n; i++) m[i][n]];
}

// ----------------------------------------------------------- matrix helpers

const _lr = .2126, _lg = .7152, _lb = .0722;

/// Builds a colour matrix: saturation, contrast (around mid grey), per-channel
/// gain and an additive offset (0..255 per channel).
List<double> _m({
  double sat = 1,
  double contrast = 1,
  List<double> gain = const [1, 1, 1],
  List<double> add = const [0, 0, 0],
}) {
  final s = [
    _lr * (1 - sat) + sat, _lg * (1 - sat), _lb * (1 - sat), //
    _lr * (1 - sat), _lg * (1 - sat) + sat, _lb * (1 - sat),
    _lr * (1 - sat), _lg * (1 - sat), _lb * (1 - sat) + sat,
  ];
  final m = <double>[];
  for (var r = 0; r < 3; r++) {
    for (var k = 0; k < 3; k++) {
      m.add(s[r * 3 + k] * gain[r] * contrast);
    }
    m
      ..add(0)
      ..add(128 * (1 - contrast) + add[r]);
  }
  m.addAll([0, 0, 0, 1, 0]);
  return m;
}

/// Two-colour map: shadows → [lo], highlights → [hi] (0xRRGGBB).
List<double> _duo(int lo, int hi, {double contrast = 1}) {
  List<double> ch(int c) =>
      [(c >> 16 & 255) / 255, (c >> 8 & 255) / 255, (c & 255) / 255];
  final l = ch(lo), h = ch(hi);
  final m = <double>[];
  for (var r = 0; r < 3; r++) {
    final d = (h[r] - l[r]) * contrast;
    m
      ..add(d * _lr)
      ..add(d * _lg)
      ..add(d * _lb)
      ..add(0)
      ..add(l[r] * 255 + (h[r] - l[r]) * 128 * (1 - contrast));
  }
  m.addAll([0, 0, 0, 1, 0]);
  return m;
}

/// Mono with a colour cast: luma × [gain] + [add].
List<double> _monoTint(
    {List<double> gain = const [1, 1, 1],
    List<double> add = const [0, 0, 0],
    double contrast = 1}) {
  final m = <double>[];
  for (var r = 0; r < 3; r++) {
    final g = gain[r] * contrast;
    m
      ..add(g * _lr)
      ..add(g * _lg)
      ..add(g * _lb)
      ..add(0)
      ..add(add[r] + 128 * (1 - contrast));
  }
  m.addAll([0, 0, 0, 1, 0]);
  return m;
}

// ---------------------------------------------------------------- catalogue

const categoryBasic = 'Basic';
const categoryMono = 'B&W';
const categoryTint = 'Tint';
const categoryRetro = 'Retro';
const categoryDuo = 'Duotone';
const categoryCinema = 'Cinema LUT';
const categoryFilm = 'Film LUT';
const categoryMood = 'Mood LUT';
const categoryVn = 'Việt Nam LUT';
const categoryCustom = 'My LUTs';

const filterCategories = <String>[
  categoryBasic,
  categoryCinema,
  categoryFilm,
  categoryMood,
  categoryVn,
  categoryMono,
  categoryTint,
  categoryRetro,
  categoryDuo,
  categoryCustom,
];

final filterPresets = <FilterPreset>[
  // ---------------------------------------------------------------- basic
  FilterPreset('none', 'Original', categoryBasic, identityMatrix),
  FilterPreset('vivid', 'Vivid', categoryBasic, const [
    1.25, -.1, -.1, 0, 0, //
    -.1, 1.25, -.1, 0, 0,
    -.1, -.1, 1.25, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('warm', 'Warm', categoryBasic, const [
    1.1, 0, 0, 0, 12, //
    0, 1.0, 0, 0, 4,
    0, 0, .85, 0, -8,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('cool', 'Cool', categoryBasic, const [
    .9, 0, 0, 0, -6, //
    0, 1.0, 0, 0, 2,
    0, 0, 1.15, 0, 14,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('fade', 'Fade', categoryBasic, const [
    .85, 0, 0, 0, 30, //
    0, .85, 0, 0, 30,
    0, 0, .85, 0, 30,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('drama', 'Drama', categoryBasic, const [
    1.4, 0, 0, 0, -45, //
    0, 1.4, 0, 0, -45,
    0, 0, 1.4, 0, -45,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('bright', 'Bright', categoryBasic,
      _m(contrast: 1.05, gain: [1.08, 1.08, 1.08], add: [10, 10, 10])),
  FilterPreset('crisp', 'Crisp', categoryBasic, _m(sat: 1.15, contrast: 1.25)),
  FilterPreset('soft', 'Soft', categoryBasic,
      _m(sat: .92, contrast: .88, add: [14, 14, 14])),
  FilterPreset('pop', 'Pop', categoryBasic, _m(sat: 1.6, contrast: 1.1)),
  FilterPreset('muted', 'Muted', categoryBasic, _m(sat: .6, contrast: .95)),

  // ------------------------------------------------------------------ b&w
  FilterPreset('mono', 'Mono', categoryMono, const [
    .33, .59, .11, 0, 0, //
    .33, .59, .11, 0, 0,
    .33, .59, .11, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('noir', 'Noir', categoryMono, const [
    .5, .9, .2, 0, -30, //
    .5, .9, .2, 0, -30,
    .5, .9, .2, 0, -30,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('silver', 'Silver', categoryMono,
      _monoTint(contrast: 1.1, gain: const [1, 1, 1.04])),
  FilterPreset(
      'hicontrast', 'High contrast', categoryMono, _monoTint(contrast: 1.7)),
  FilterPreset('softmono', 'Soft mono', categoryMono,
      _monoTint(contrast: .8, add: const [18, 18, 18])),
  FilterPreset('bluemono', 'Blue mono', categoryMono,
      _monoTint(gain: const [.7, .9, 1.15], add: const [0, 4, 14])),
  FilterPreset('selenium', 'Selenium', categoryMono,
      _monoTint(gain: const [1.05, .95, .95], add: const [8, 0, 6])),
  FilterPreset('sepia', 'Sepia', categoryMono, const [
    .393, .769, .189, 0, 0, //
    .349, .686, .168, 0, 0,
    .272, .534, .131, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('cyanotype', 'Cyanotype', categoryMono,
      _duo(0x0B2A4A, 0xCFE9F2, contrast: 1.05)),

  // ----------------------------------------------------------------- tint
  FilterPreset('sunset', 'Sunset', categoryTint,
      _m(sat: 1.2, gain: const [1.18, .96, .8], add: const [8, 0, -6])),
  FilterPreset(
      'golden',
      'Golden hour',
      categoryTint,
      _m(
          sat: 1.15,
          contrast: 1.05,
          gain: const [1.15, 1.04, .78],
          add: const [10, 4, -8])),
  FilterPreset(
      'peach',
      'Peach',
      categoryTint,
      _m(
          sat: .95,
          contrast: .95,
          gain: const [1.08, .98, .92],
          add: const [14, 8, 4])),
  FilterPreset(
      'rose',
      'Rosé',
      categoryTint,
      _m(
          sat: 1.05,
          contrast: .95,
          gain: const [1.1, .92, 1.0],
          add: const [14, 2, 10])),
  FilterPreset(
      'candy',
      'Candy',
      categoryTint,
      _m(
          sat: 1.35,
          contrast: .95,
          gain: const [1.08, .98, 1.1],
          add: const [14, 6, 14])),
  FilterPreset(
      'lavender',
      'Lavender',
      categoryTint,
      _m(
          sat: .95,
          contrast: .95,
          gain: const [.98, .94, 1.12],
          add: const [10, 4, 18])),
  FilterPreset(
      'mint',
      'Mint',
      categoryTint,
      _m(
          sat: .95,
          contrast: .95,
          gain: const [.92, 1.06, 1.02],
          add: const [4, 12, 10])),
  FilterPreset('ocean', 'Ocean', categoryTint,
      _m(sat: 1.1, gain: const [.82, 1.0, 1.18], add: const [-6, 4, 12])),
  FilterPreset(
      'forest',
      'Forest',
      categoryTint,
      _m(
          sat: 1.05,
          contrast: 1.05,
          gain: const [.9, 1.08, .86],
          add: const [-4, 4, -6])),
  FilterPreset('amber', 'Amber', categoryTint,
      _m(sat: 1.1, gain: const [1.2, 1.02, .7], add: const [10, 2, -10])),
  FilterPreset(
      'icy',
      'Icy',
      categoryTint,
      _m(
          sat: .85,
          contrast: 1.05,
          gain: const [.88, 1.0, 1.2],
          add: const [-4, 6, 20])),
  FilterPreset('emerald', 'Emerald', categoryTint,
      _m(sat: 1.2, gain: const [.82, 1.12, .96], add: const [-6, 6, 4])),

  // ---------------------------------------------------------------- retro
  FilterPreset('vintage', 'Vintage', categoryRetro, const [
    .9, .15, .05, 0, 10, //
    .1, .85, .05, 0, 6,
    .1, .1, .7, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset(
      'polaroid',
      'Polaroid',
      categoryRetro,
      _m(
          sat: 1.1,
          contrast: .9,
          gain: const [1.08, 1.0, .9],
          add: const [18, 10, 6])),
  FilterPreset(
      'seventies',
      "'70s",
      categoryRetro,
      _m(
          sat: 1.25,
          contrast: .95,
          gain: const [1.18, 1.0, .72],
          add: const [14, 4, -4])),
  FilterPreset('camcorder', '90s camcorder', categoryRetro,
      _m(sat: 1.3, contrast: 1.1, gain: const [1.04, 1.06, .92])),
  FilterPreset(
      'fadedfilm',
      'Faded film',
      categoryRetro,
      _m(
          sat: .85,
          contrast: .85,
          gain: const [1.02, 1.0, .96],
          add: const [26, 24, 22])),
  FilterPreset('crossprocess', 'Cross process', categoryRetro, const [
    1.25, .05, -.1, 0, -8, //
    -.05, 1.05, .15, 0, 4,
    -.15, .2, .85, 0, 24,
    0, 0, 0, 1, 0,
  ]),
  FilterPreset('lomo', 'Lomo', categoryRetro,
      _m(sat: 1.4, contrast: 1.3, gain: const [1.05, 1.02, .92])),
  FilterPreset(
      'oldphoto',
      'Old photo',
      categoryRetro,
      _m(
          sat: .55,
          contrast: .9,
          gain: const [1.1, 1.0, .8],
          add: const [20, 12, 0])),

  // -------------------------------------------------------------- duotone
  FilterPreset(
      'duo_bo', 'Blue · Orange', categoryDuo, _duo(0x0A1F6B, 0xFFB347)),
  FilterPreset('duo_pc', 'Pink · Cyan', categoryDuo, _duo(0x7A1F8F, 0x5DE6F0)),
  FilterPreset(
      'duo_pg', 'Purple · Gold', categoryDuo, _duo(0x2B0F54, 0xFFD36B)),
  FilterPreset('duo_nr', 'Noir · Red', categoryDuo, _duo(0x0A0A0A, 0xFF4D4D)),
  FilterPreset('duo_tp', 'Teal · Peach', categoryDuo, _duo(0x0B3B45, 0xFFC9A8)),
  FilterPreset('duo_mid', 'Midnight', categoryDuo, _duo(0x050B2A, 0x8FB8FF)),
  FilterPreset('duo_vn', 'Vàng · Đỏ', categoryDuo, _duo(0x8B0000, 0xFFE24A)),
  FilterPreset('duo_mg', 'Matcha', categoryDuo, _duo(0x0F3D2A, 0xD6F5A8)),

  // ------------------------------------------------------------ cinema LUT
  FilterPreset.lut(
      'lut_tealorange',
      'Teal & Orange',
      categoryCinema,
      const LookSpec(
          contrast: 1.12,
          curve: .35,
          sat: 1.12,
          shadow: [-.02, .05, .08],
          highlight: [.08, .03, -.06])),
  FilterPreset.lut(
      'lut_blockbuster',
      'Blockbuster',
      categoryCinema,
      const LookSpec(
          contrast: 1.18,
          curve: .45,
          sat: 1.05,
          gamma: [1.02, 1, .96],
          shadow: [-.01, .04, .07],
          highlight: [.06, .02, -.04])),
  FilterPreset.lut('lut_bleach', 'Bleach bypass', categoryCinema,
      const LookSpec(contrast: 1.3, curve: .5, sat: .45, fade: .02)),
  FilterPreset.lut(
      'lut_moodyblue',
      'Moody blue',
      categoryCinema,
      const LookSpec(
          exposure: .96,
          contrast: 1.1,
          curve: .3,
          sat: .9,
          gain: [.94, 1, 1.1],
          shadow: [-.02, .02, .08])),
  FilterPreset.lut(
      'lut_noir',
      'Hollywood noir',
      categoryCinema,
      const LookSpec(
          mono: true,
          contrast: 1.35,
          curve: .55,
          highlight: [0, 0, .02],
          shadow: [0, 0, .015])),
  FilterPreset.lut(
      'lut_cyberpunk',
      'Cyberpunk',
      categoryCinema,
      const LookSpec(
          contrast: 1.15,
          curve: .4,
          sat: 1.3,
          shadow: [.06, -.02, .12],
          highlight: [.04, .08, .1])),
  FilterPreset.lut(
      'lut_matrix',
      'Matrix green',
      categoryCinema,
      const LookSpec(
          contrast: 1.15,
          curve: .3,
          sat: .85,
          gain: [.82, 1.1, .85],
          shadow: [-.02, .05, -.01])),
  FilterPreset.lut(
      'lut_daynight',
      'Day for night',
      categoryCinema,
      const LookSpec(
          exposure: .72,
          contrast: 1.1,
          sat: .75,
          gain: [.8, .95, 1.2],
          shadow: [-.02, .02, .08])),
  FilterPreset.lut(
      'lut_neonnight',
      'Neon night',
      categoryCinema,
      const LookSpec(
          exposure: .92,
          contrast: 1.2,
          curve: .45,
          sat: 1.4,
          shadow: [.07, -.02, .1],
          highlight: [.05, .04, .03])),

  // -------------------------------------------------------------- film LUT
  FilterPreset.lut(
      'lut_kodak',
      'Kodak Gold',
      categoryFilm,
      const LookSpec(
          contrast: 1.06,
          curve: .25,
          sat: 1.1,
          fade: .03,
          gain: [1.06, 1.02, .88],
          shadow: [.01, .005, -.01],
          highlight: [.05, .03, -.04])),
  FilterPreset.lut(
      'lut_velvia',
      'Fuji Velvia',
      categoryFilm,
      const LookSpec(
          contrast: 1.18,
          curve: .35,
          sat: 1.5,
          gamma: [1, 1.04, 1],
          shadow: [0, -.01, .02])),
  FilterPreset.lut(
      'lut_eterna',
      'Fuji Eterna',
      categoryFilm,
      const LookSpec(
          contrast: .96,
          curve: .15,
          sat: .88,
          fade: .04,
          gain: [.98, 1.04, 1.02],
          shadow: [-.005, .015, .02])),
  FilterPreset.lut(
      'lut_portra',
      'Portra 400',
      categoryFilm,
      const LookSpec(
          exposure: 1.04,
          contrast: .94,
          curve: .15,
          sat: .92,
          fade: .035,
          gain: [1.04, 1.0, .94],
          highlight: [.03, .02, .01])),
  FilterPreset.lut(
      'lut_agfa',
      'Agfa Vista',
      categoryFilm,
      const LookSpec(
          contrast: 1.1,
          curve: .3,
          sat: 1.25,
          fade: .02,
          gain: [1.08, 1, .9],
          shadow: [.02, 0, .03])),
  FilterPreset.lut(
      'lut_cinestill',
      'CineStill 800T',
      categoryFilm,
      const LookSpec(
          contrast: 1.08,
          curve: .3,
          sat: 1.1,
          gain: [.95, 1.0, 1.08],
          shadow: [-.01, .02, .06],
          highlight: [.07, .01, -.02])),
  FilterPreset.lut(
      'lut_tri',
      'Tri-X 400',
      categoryFilm,
      const LookSpec(
          mono: true,
          contrast: 1.25,
          curve: .5,
          fade: .03,
          gamma: [1.05, 1.05, 1.05])),
  FilterPreset.lut(
      'lut_ektar',
      'Ektar 100',
      categoryFilm,
      const LookSpec(
          contrast: 1.12, curve: .3, sat: 1.4, gain: [1.05, 1.0, .96])),

  // -------------------------------------------------------------- mood LUT
  FilterPreset.lut(
      'lut_autumn',
      'Golden autumn',
      categoryMood,
      const LookSpec(
          contrast: 1.08,
          curve: .25,
          sat: 1.2,
          gain: [1.12, 1.0, .8],
          highlight: [.05, .02, -.05])),
  FilterPreset.lut(
      'lut_summer',
      'Summer pop',
      categoryMood,
      const LookSpec(
          exposure: 1.05,
          contrast: 1.08,
          sat: 1.35,
          gain: [1.03, 1.03, .98],
          highlight: [.03, .03, .0])),
  FilterPreset.lut(
      'lut_pastel',
      'Pastel dream',
      categoryMood,
      const LookSpec(
          exposure: 1.06,
          contrast: .85,
          sat: .85,
          fade: .08,
          gain: [1.03, 1.0, 1.05],
          shadow: [.03, .01, .05])),
  FilterPreset.lut(
      'lut_dreamy',
      'Dreamy haze',
      categoryMood,
      const LookSpec(
          exposure: 1.08,
          contrast: .82,
          sat: .9,
          fade: .1,
          highlight: [.03, .02, .04],
          shadow: [.02, .0, .04])),
  FilterPreset.lut(
      'lut_winter',
      'Winter blue',
      categoryMood,
      const LookSpec(
          contrast: 1.05,
          sat: .8,
          gain: [.92, 1.0, 1.14],
          highlight: [.0, .02, .06])),
  FilterPreset.lut(
      'lut_forestmood',
      'Misty forest',
      categoryMood,
      const LookSpec(
          exposure: .98,
          contrast: .95,
          sat: .9,
          fade: .04,
          gain: [.9, 1.06, .94],
          shadow: [-.01, .03, .02])),
  FilterPreset.lut(
      'lut_rosegold',
      'Rose gold',
      categoryMood,
      const LookSpec(
          contrast: .96,
          sat: 1.0,
          fade: .03,
          gain: [1.08, .96, .94],
          highlight: [.05, .02, .02],
          shadow: [.02, 0, .01])),
  FilterPreset.lut(
      'lut_sunsetlut',
      'Sunset glow',
      categoryMood,
      const LookSpec(
          contrast: 1.1,
          curve: .3,
          sat: 1.3,
          gain: [1.16, .96, .82],
          shadow: [.04, -.01, .05],
          highlight: [.08, .03, -.05])),

  // ----------------------------------------------------------- Việt Nam LUT
  FilterPreset.lut(
      'lut_hanoi',
      'Hà Nội xưa',
      categoryVn,
      const LookSpec(
          contrast: .96,
          sat: .75,
          fade: .06,
          gain: [1.06, 1.02, .84],
          shadow: [.015, .015, -.005])),
  FilterPreset.lut(
      'lut_saigon',
      'Sài Gòn hoàng hôn',
      categoryVn,
      const LookSpec(
          contrast: 1.1,
          curve: .3,
          sat: 1.3,
          gain: [1.15, .98, .84],
          shadow: [.03, -.01, .06],
          highlight: [.07, .03, -.04])),
  FilterPreset.lut(
      'lut_halong',
      'Vịnh Hạ Long',
      categoryVn,
      const LookSpec(
          exposure: 1.02,
          contrast: .98,
          sat: .95,
          fade: .04,
          gain: [.9, 1.04, 1.1],
          highlight: [.01, .03, .05])),
  FilterPreset.lut(
      'lut_dalat',
      'Đà Lạt sương',
      categoryVn,
      const LookSpec(
          exposure: 1.05,
          contrast: .88,
          sat: .88,
          fade: .08,
          gain: [1.03, 1.02, 1.0],
          shadow: [.02, .02, .04],
          highlight: [.04, .03, .02])),
  FilterPreset.lut(
      'lut_tet',
      'Tết đỏ',
      categoryVn,
      const LookSpec(
          contrast: 1.12,
          curve: .3,
          sat: 1.35,
          gain: [1.18, .94, .8],
          highlight: [.06, .02, -.03])),
  FilterPreset.lut(
      'lut_hoian',
      'Hội An đèn lồng',
      categoryVn,
      const LookSpec(
          exposure: .96,
          contrast: 1.12,
          curve: .35,
          sat: 1.25,
          gain: [1.2, 1.0, .72],
          shadow: [.03, 0, .02],
          highlight: [.08, .04, -.05])),
  FilterPreset.lut(
      'lut_sapa',
      'Sa Pa ruộng bậc thang',
      categoryVn,
      const LookSpec(
          contrast: 1.08,
          curve: .2,
          sat: 1.3,
          gain: [.96, 1.1, .86],
          highlight: [.03, .05, -.02])),
  FilterPreset.lut(
      'lut_mekong',
      'Miền Tây sông nước',
      categoryVn,
      const LookSpec(
          contrast: 1.04,
          sat: 1.1,
          fade: .03,
          gain: [1.04, 1.06, .88],
          highlight: [.04, .04, -.03])),
];

/// LUTs imported by the user in this session (`.cube` files).
final customLuts = <FilterPreset>[];

FilterPreset filterPresetById(String id) {
  for (final p in filterPresets) {
    if (p.id == id) return p;
  }
  for (final p in customLuts) {
    if (p.id == id) return p;
  }
  return filterPresets.first;
}

/// A parsed Adobe/Resolve `.cube` 3D LUT.
class CubeLut {
  CubeLut._(
      this.title, this.size, this.data, this.dmin, this.dmax, this.source);

  final String title;
  final int size;

  /// RGB triplets, red varying fastest.
  final List<double> data;
  final List<double> dmin;
  final List<double> dmax;
  final String source;

  /// Throws [FormatException] with a readable message.
  static CubeLut parse(String text) {
    var title = '';
    var size = 0;
    var dmin = [0.0, 0.0, 0.0];
    var dmax = [1.0, 1.0, 1.0];
    final data = <double>[];
    List<double> nums(List<String> p) => [
          for (final v in p.skip(1))
            double.tryParse(v) ?? (throw FormatException('Bad number "$v"')),
        ];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(RegExp(r'\s+'));
      final key = parts.first.toUpperCase();
      if (key == 'TITLE') {
        title = line.substring(5).trim().replaceAll('"', '');
      } else if (key == 'LUT_3D_SIZE') {
        size = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
      } else if (key == 'LUT_1D_SIZE') {
        throw const FormatException('1D LUTs are not supported (3D only).');
      } else if (key == 'DOMAIN_MIN') {
        dmin = nums(parts);
      } else if (key == 'DOMAIN_MAX') {
        dmax = nums(parts);
      } else if (double.tryParse(parts.first) != null) {
        if (parts.length < 3) throw const FormatException('Bad data row.');
        data
          ..add(double.parse(parts[0]))
          ..add(double.parse(parts[1]))
          ..add(double.parse(parts[2]));
      }
    }
    if (size < 2 || size > 129) {
      throw const FormatException('Missing or invalid LUT_3D_SIZE.');
    }
    if (dmin.length != 3 || dmax.length != 3) {
      throw const FormatException('Bad DOMAIN_MIN / DOMAIN_MAX.');
    }
    final expected = size * size * size * 3;
    if (data.length != expected) {
      throw FormatException(
          'Expected ${expected ~/ 3} colour rows for size $size, '
          'found ${data.length ~/ 3}.');
    }
    return CubeLut._(title, size, data, dmin, dmax, text);
  }

  /// Trilinear lookup for r, g, b in 0..1.
  List<double> sample(double r, double g, double b) {
    final n = size - 1;
    final pos = [
      for (final (i, v) in [r, g, b].indexed)
        (((v - dmin[i]) / (dmax[i] - dmin[i])) * n).clamp(0.0, n.toDouble()),
    ];
    final i0 = [for (final p in pos) p.floor().clamp(0, n - 1)];
    final f = [for (var k = 0; k < 3; k++) pos[k] - i0[k]];
    final out = [0.0, 0.0, 0.0];
    for (var corner = 0; corner < 8; corner++) {
      final dr = corner & 1, dg = (corner >> 1) & 1, db = (corner >> 2) & 1;
      final w = (dr == 1 ? f[0] : 1 - f[0]) *
          (dg == 1 ? f[1] : 1 - f[1]) *
          (db == 1 ? f[2] : 1 - f[2]);
      if (w == 0) continue;
      final idx =
          (((i0[2] + db) * size + (i0[1] + dg)) * size + (i0[0] + dr)) * 3;
      for (var c = 0; c < 3; c++) {
        out[c] += data[idx + c] * w;
      }
    }
    return out;
  }

  /// `.cube` text blended with the identity by [intensity] (1 = as imported).
  String toText(double intensity) {
    if (intensity >= 1) return source;
    final b = StringBuffer()
      ..writeln('TITLE "${title.isEmpty ? 'LUT' : title}"')
      ..writeln('LUT_3D_SIZE $size')
      ..writeln('DOMAIN_MIN ${dmin.join(' ')}')
      ..writeln('DOMAIN_MAX ${dmax.join(' ')}');
    final n = size - 1;
    var idx = 0;
    for (var bi = 0; bi < size; bi++) {
      for (var gi = 0; gi < size; gi++) {
        for (var ri = 0; ri < size; ri++) {
          final inp = [ri, gi, bi];
          final row = <String>[];
          for (var c = 0; c < 3; c++) {
            final x = dmin[c] + inp[c] / n * (dmax[c] - dmin[c]);
            row.add((x + (data[idx + c] - x) * intensity).toStringAsFixed(5));
          }
          b.writeln(row.join(' '));
          idx += 3;
        }
      }
    }
    return b.toString();
  }
}
