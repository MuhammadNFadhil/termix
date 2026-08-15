/// An RGB color with each channel held as a fraction from 0 to 1.
///
/// This is the working representation for the color space math, which expects
/// floating point channels rather than bytes.
class Rgb {

  final double r;
  final double g;
  final double b;

  const Rgb(this.r, this.g, this.b);

  /// Builds a color from a packed 0xRRGGBB integer.
  factory Rgb.fromPacked(int rgb) => Rgb(
        ((rgb >> 16) & 0xff) / 255,
        ((rgb >> 8) & 0xff) / 255,
        (rgb & 0xff) / 255,
      );

  /// Parses a hex color in the long form '#rrggbb' or the short form '#rgb'.
  /// Returns null when the text is not a valid hex color.
  static Rgb? fromHex(String s) {

    if (!s.startsWith('#')) return null;
    final body = s.substring(1);

    if (body.length == 3) {
      final r = _byte(body[0] + body[0]);
      final g = _byte(body[1] + body[1]);
      final b = _byte(body[2] + body[2]);
      if (r == null || g == null || b == null) return null;
      return Rgb(r / 255, g / 255, b / 255);
    }

    if (body.length == 6) {
      final r = _byte(body.substring(0, 2));
      final g = _byte(body.substring(2, 4));
      final b = _byte(body.substring(4, 6));
      if (r == null || g == null || b == null) return null;
      return Rgb(r / 255, g / 255, b / 255);
    }

    return null;
  }

  static int? _byte(String s) => int.tryParse(s, radix: 16);
}
