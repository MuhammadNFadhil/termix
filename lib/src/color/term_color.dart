/// A concrete terminal color and the SGR parameters that select it.
library;

import 'rgb.dart';

/// SGR control sequence introducer (CSI).
const String csi = '\x1b[';

/// SGR parameter for resetting every attribute.
const String resetSeq = '0';

/// SGR selector for setting foreground color.
const String foregroundSeq = '38';

/// SGR selector for setting background color.
const String backgroundSeq = '48';

/// One color, able to render itself as the numeric body of an SGR sequence.
sealed class TermColor {
  const TermColor();

  /// Renders this color as SGR parameters, as a foreground color by default or
  /// as a background color when [background] is set.
  String sequence({bool background = false});
}

/// The absence of a color, meaning the terminal default.
class NoColor extends TermColor {
  const NoColor();

  @override
  String sequence({bool background = false}) => '';

  @override
  bool operator ==(Object other) => other is NoColor;

  @override
  int get hashCode => 0;
}

/// A shared instance of [NoColor].
const NoColor noColor = NoColor();

/// One of the original sixteen ANSI colors, numbered 0 to 15.
class AnsiColor extends TermColor {
  const AnsiColor(this.value);

  final int value;

  @override
  String sequence({bool background = false}) {
    // 0 to 7 map to 30 to 37, and 8 to 15 to the bright range 90 to 97:
    final base = value < 8
      ? value + 30
      : value - 8 + 90;

    // Backgrounds are ten higher in each case:
    return '${background ? base + 10 : base}';
  }

  @override
  bool operator ==(Object other) => other is AnsiColor && other.value == value;

  @override
  int get hashCode => Object.hash('ansi', value);
}

/// A color from the xterm 256 color palette.
class Ansi256Color extends TermColor {
  const Ansi256Color(this.value);

  final int value;

  @override
  String sequence({bool background = false}) =>
      '${background ? backgroundSeq : foregroundSeq};5;$value';

  @override
  bool operator ==(Object other) =>
      other is Ansi256Color && other.value == value;

  @override
  int get hashCode => Object.hash('ansi256', value);
}

/// A 24 bit color, written as '#rrggbb' or '#rgb'.
class RgbColor extends TermColor {
  const RgbColor(this.hex);

  final String hex;

  @override
  String sequence({bool background = false}) {
    final color = Rgb.fromHex(hex);
    if (color == null) return '';
    final selector = background ? backgroundSeq : foregroundSeq;
    // Channels are truncated rather than rounded when going back to bytes.
    return '$selector;2;${(color.r * 255).toInt()};${(color.g * 255).toInt()};'
        '${(color.b * 255).toInt()}';
  }

  @override
  bool operator ==(Object other) => other is RgbColor && other.hex == hex;

  @override
  int get hashCode => Object.hash('rgb', hex);
}
