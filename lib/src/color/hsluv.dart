/// sRGB to HSLuv conversion and a perceptual distance between two colors.
///
/// HSLuv is a human friendly transform of CIELUV. The pipeline is the standard
/// colorimetric one, run in this order:
///
///   sRGB -> linear RGB -> CIE XYZ -> CIELUV -> LCh -> HSLuv
///
/// The matrices are the sRGB primaries under the D65 white point. kappa and
/// epsilon are the CIE terms (29/3)^3 and (6/29)^3. The gamut boundary formula
/// for the maximum chroma at a given lightness is the one from hsluv.org.
/// Lightness and chroma are kept on a 0..1 scale, which is why the CIELUV L
/// uses 1.16 and 0.16 in place of the usual 116 and 16.
library;

import 'dart:math' as math;

import 'rgb.dart';

// sRGB to CIE XYZ (D65).
const _rgbToXyz = <List<double>>[
  [0.41239079926595948, 0.35758433938387796, 0.18048078840183429],
  [0.21263900587151036, 0.71516867876775593, 0.072192315360733715],
  [0.019330818715591851, 0.11919477979462599, 0.95053215224966058],
];

// CIE XYZ to linear sRGB, the inverse of the matrix above. HSLuv needs it to
// trace the edges of the sRGB gamut.
const _xyzToRgb = <List<double>>[
  [3.2409699419045214, -1.5373831775700935, -0.49861076029300328],
  [-0.96924363628087983, 1.8759675015077207, 0.041555057407175613],
  [0.055630079696993609, -0.20397695888897657, 1.0569715142428786],
];

// The D65 reference white in CIE XYZ.
const _refX = 0.95045592705167;
const _refY = 1.0;
const _refZ = 1.089057750759878;

const _kappa = 903.2962962962963; // (29/3)^3
const _epsilon = 0.0088564516790356308; // (6/29)^3

/// The HSLuv coordinates of a color, hue in degrees and the rest on 0..1.
typedef Hsluv = ({double h, double s, double l});

/// Converts an sRGB color to HSLuv.
Hsluv toHsluv(Rgb color) {
  final xyz = _toXyz(color);
  final luv = _toLuv(xyz);
  final (l, c, h) = _toLch(luv);

  // The gamut boundary math works in 0..100, so scale up for the chroma step.
  final l100 = l * 100;
  final c100 = c * 100;

  final double s;
  if (l100 > 99.9999999 || l100 < 0.00000001) {
    s = 0;
  } else {
    s = c100 / _maxChroma(l100, h) * 100;
  }
  return (h: h, s: _clamp01(s / 100), l: _clamp01(l));
}

/// The perceptual distance between two colors, with hue scaled so that H, S and
/// L weigh roughly the same. This is what lets a gray degrade to a gray rather
/// than to the nearest tinted cell.
double distance(Rgb a, Rgb b) {
  final x = toHsluv(a);
  final y = toHsluv(b);
  final dh = (x.h - y.h) / 100;
  final ds = x.s - y.s;
  final dl = x.l - y.l;
  return math.sqrt(dh * dh + ds * ds + dl * dl);
}

List<double> _toXyz(Rgb c) {
  final r = _linearize(c.r);
  final g = _linearize(c.g);
  final b = _linearize(c.b);
  return [
    for (final row in _rgbToXyz) row[0] * r + row[1] * g + row[2] * b,
  ];
}

List<double> _toLuv(List<double> xyz) {
  final x = xyz[0], y = xyz[1], z = xyz[2];
  final yr = y / _refY;
  final l = yr <= _epsilon ? yr * _kappa / 100 : 1.16 * _cbrt(yr) - 0.16;
  final (u, v) = _uv(x, y, z);
  final (un, vn) = _uv(_refX, _refY, _refZ);
  return [l, 13 * l * (u - un), 13 * l * (v - vn)];
}

(double, double) _uv(double x, double y, double z) {
  final denom = x + 15 * y + 3 * z;
  if (denom == 0) return (0, 0);
  return (4 * x / denom, 9 * y / denom);
}

(double, double, double) _toLch(List<double> luv) {
  final l = luv[0], u = luv[1], v = luv[2];
  final c = math.sqrt(u * u + v * v);

  // Guard against the floating point noise when u and v both sit near zero.
  final double h;
  if ((v - u).abs() > 1e-4 && u.abs() > 1e-4) {
    h = (math.atan2(v, u) * 180 / math.pi + 360) % 360;
  } else {
    h = 0;
  }
  return (l, c, h);
}

double _maxChroma(double l, double h) {
  final hr = h / 360 * 2 * math.pi;
  var min = double.infinity;
  for (final (slope, intercept) in _boundLines(l)) {
    final length = intercept / (math.sin(hr) - slope * math.cos(hr));
    if (length > 0 && length < min) min = length;
  }
  return min;
}

/// The six line segments that bound the sRGB gamut at lightness [l], each the
/// locus where one linear RGB channel is pinned to 0 or to 1.
List<(double, double)> _boundLines(double l) {
  final sub1 = math.pow(l + 16, 3).toDouble() / 1560896;
  final sub2 = sub1 > _epsilon ? sub1 : l / _kappa;

  final lines = <(double, double)>[];
  for (final m in _xyzToRgb) {
    final m1 = m[0], m2 = m[1], m3 = m[2];
    for (var t = 0; t < 2; t++) {
      final top1 = (284517 * m1 - 94839 * m3) * sub2;
      final top2 =
          (838422 * m3 + 769860 * m2 + 731718 * m1) * l * sub2 - 769860 * t * l;
      final bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t;
      lines.add((top1 / bottom, top2 / bottom));
    }
  }
  return lines;
}

double _linearize(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _cbrt(double v) =>
    v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
