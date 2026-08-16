/// The xterm 256 color palette, computed from its layout.
///
/// Slots 0 to 15 are the conventional system colors. Slots 16 to 231 are a
/// 6x6x6 cube whose channels step through 0, 95, 135, 175, 215, 255. Slots 232
/// to 255 are a 24 step gray ramp from 8 to 238 in steps of 10.
library;

/// The color of xterm palette slot [i] as a packed 0xRRGGBB integer.
int ansiRgb(int i) => _palette[i];

final List<int> _palette = _build();

// The steps a cube channel takes. The first is black, the rest are 0x5f..0xff.
const _cubeLevels = <int>[0, 0x5f, 0x87, 0xaf, 0xd7, 0xff];

// The sixteen system colors. These are a fixed terminal convention, not a
// derived quantity, so they are named directly.
const _system = <int>[
  0x000000, 0x800000, 0x008000, 0x808000,
  0x000080, 0x800080, 0x008080, 0xc0c0c0,
  0x808080, 0xff0000, 0x00ff00, 0xffff00,
  0x0000ff, 0xff00ff, 0x00ffff, 0xffffff,
];

List<int> _build() {
  final out = List<int>.filled(256, 0);

  for (var i = 0; i < 16; i++) {
    out[i] = _system[i];
  }

  for (var i = 0; i < 216; i++) {
    final r = _cubeLevels[i ~/ 36];
    final g = _cubeLevels[(i ~/ 6) % 6];
    final b = _cubeLevels[i % 6];
    out[16 + i] = (r << 16) | (g << 8) | b;
  }

  for (var i = 0; i < 24; i++) {
    final v = 8 + 10 * i;
    out[232 + i] = (v << 16) | (v << 8) | v;
  }

  return out;
}
