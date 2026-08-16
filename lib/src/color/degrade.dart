/// Reducing a color to what a given [Profile] can display.
///
/// A 24 bit color that a terminal cannot show is mapped to the nearest color it
/// can, and nearest is measured in HSLuv rather than in raw RGB so that grays
/// stay gray instead of drifting toward a tinted cell.
library;

import 'hsluv.dart' as hsluv;
import 'palette.dart';
import 'profile.dart';
import 'rgb.dart';
import 'term_color.dart';

extension ProfileColor on Profile {
  /// Parses a color written as '#rrggbb', '#rgb', or a number naming an ANSI
  /// slot, then reduces it to this profile. Returns null when the text is not a
  /// color this profile could represent.
  TermColor? colorOf(String spec) {
    if (spec.isEmpty) return null;

    final TermColor color;
    if (spec.startsWith('#')) {
      color = RgbColor(spec);
    } else {
      final index = int.tryParse(spec);
      if (index == null) return null;
      color = index < 16 ? AnsiColor(index) : Ansi256Color(index);
    }
    return convert(color);
  }

  /// Reduces [color] to the nearest color this profile can display.
  TermColor? convert(TermColor color) {
    if (this == Profile.ascii) return noColor;

    switch (color) {
      case NoColor():
        return color;
      case AnsiColor():
        return color;
      case Ansi256Color():
        return this == Profile.ansi ? _toAnsi(color) : color;
      case RgbColor():
        final rgb = Rgb.fromHex(color.hex);
        if (rgb == null) return null;
        if (this == Profile.trueColor) return color;
        final reduced = _to256(rgb);
        return this == Profile.ansi ? _toAnsi(reduced) : reduced;
    }
  }
}

/// Picks the 256 color slot nearest to a 24 bit color. Both the color cube and
/// the gray ramp are candidates, and the nearer one in HSLuv wins.
Ansi256Color _to256(Rgb c) {
  // The nearest cube cell, channel by channel.
  final ri = _cubeIndex(c.r * 255);
  final gi = _cubeIndex(c.g * 255);
  final bi = _cubeIndex(c.b * 255);
  final cubeSlot = 16 + 36 * ri + 6 * gi + bi;
  final cube = Rgb.fromPacked(ansiRgb(cubeSlot));

  // The nearest gray ramp entry, chosen from the average channel value.
  final average =
      ((c.r * 255).toInt() + (c.g * 255).toInt() + (c.b * 255).toInt()) ~/ 3;
  final grayIndex = average > 238 ? 23 : (average - 3) ~/ 10;
  final graySlot = 232 + grayIndex;
  final gray = Rgb.fromPacked(ansiRgb(graySlot));

  if (hsluv.distance(c, cube) <= hsluv.distance(c, gray)) {
    return Ansi256Color(cubeSlot);
  }
  return Ansi256Color(graySlot);
}

/// Maps a 0..255 channel value onto one of the six cube levels.
int _cubeIndex(double v) {
  if (v < 48) return 0;
  if (v < 115) return 1;
  return ((v - 35) / 40).toInt();
}

/// Picks the ANSI color nearest to a 256 color slot, in HSLuv.
AnsiColor _toAnsi(Ansi256Color color) {
  final target = Rgb.fromPacked(ansiRgb(color.value));
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < 16; i++) {
    final d = hsluv.distance(target, Rgb.fromPacked(ansiRgb(i)));
    if (d < bestDistance) {
      bestDistance = d;
      best = i;
    }
  }
  return AnsiColor(best);
}
