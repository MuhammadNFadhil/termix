/// Reading the terminal's color capability from the environment.
library;

import 'dart:io';

import 'profile.dart';

/// Reads the color capability from the environment, following the conventions
/// terminals agree on. NO_COLOR turns color off (see https://no-color.org),
/// COLORTERM promises 24 bit color, and TERM names the terminal.
Profile envColorProfile() {
  final env = Platform.environment;

  if ((env['NO_COLOR'] ?? '').isNotEmpty) return Profile.ascii;

  final term = env['TERM'] ?? '';
  if (term.isEmpty || term == 'dumb') return Profile.ascii;

  final colorTerm = (env['COLORTERM'] ?? '').toLowerCase();
  if (colorTerm == 'truecolor' || colorTerm == '24bit') {
    return Profile.trueColor;
  }
  if (colorTerm == 'yes' || colorTerm == 'true') return Profile.ansi256;

  if (term.contains('truecolor') || term.contains('direct')) {
    return Profile.trueColor;
  }
  if (term.contains('256color')) return Profile.ansi256;
  if (term.contains('color') ||
      term.contains('ansi') ||
      term.contains('xterm')) {
    return Profile.ansi;
  }
  return Profile.ascii;
}

/// Guesses whether the terminal has a dark background. COLORFGBG, when set,
/// names the foreground and background as ANSI numbers. With nothing to go on,
/// dark is the safer default, since a light palette on a dark screen is
/// unreadable while the reverse is merely quiet.
bool envHasDarkBackground() {
  final fgbg = Platform.environment['COLORFGBG'] ?? '';
  if (fgbg.isNotEmpty) {
    final parts = fgbg.split(';');
    if (parts.length >= 2) {
      final bg = int.tryParse(parts.last);
      if (bg != null) return bg <= 8;
    }
  }
  return true;
}
