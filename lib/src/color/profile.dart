/// How much color a terminal can display. A color rendered through a profile is
/// reduced to what that profile is able to show.
enum Profile {
  /// No color at all. Escape sequences are dropped entirely.
  ascii,

  /// The original sixteen ANSI colors.
  ansi,

  /// The 256 color xterm palette.
  ansi256,

  /// Full 24 bit color, sent through unchanged.
  trueColor,
}
