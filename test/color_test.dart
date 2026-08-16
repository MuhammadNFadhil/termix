import 'package:termix/color.dart';
import 'package:test/test.dart';

void main() {
  group('hex parsing and sequences', () {
    test('long and short hex render the same 24 bit sequence', () {
      expect(Profile.trueColor.colorOf('#ff8800')?.sequence(),
          const RgbColor('#ff8800').sequence());
      expect(Profile.trueColor.colorOf('#f80')?.sequence(background: true),
          '48;2;255;136;0');
    });

    test('invalid specs are rejected', () {
      expect(Profile.trueColor.colorOf(''), isNull);
      expect(Profile.trueColor.colorOf('#12'), isNull);
      expect(Profile.trueColor.colorOf('nope'), isNull);
    });

    test('numeric specs name ANSI slots', () {
      expect(Profile.trueColor.colorOf('9'), const AnsiColor(9));
      expect(Profile.trueColor.colorOf('200'), const Ansi256Color(200));
    });
  });

  group('degradation', () {
    test('ascii drops all color', () {
      expect(Profile.ascii.colorOf('#ff0000'), noColor);
    });

    test('trueColor passes 24 bit through untouched', () {
      expect(Profile.trueColor.colorOf('#123456'), const RgbColor('#123456'));
    });

    test('ansi256 reduces to a palette slot', () {
      final c = Profile.ansi256.colorOf('#ff0000');
      expect(c, isA<Ansi256Color>());
    });

    test('ansi reduces to one of the first sixteen', () {
      final c = Profile.ansi.colorOf('#00ff00') as AnsiColor;
      expect(c.value, inInclusiveRange(0, 15));
    });
  });

  group('gray handling', () {
    // A dark neutral should land on the gray ramp near its own lightness, not
    // on the near black end of it.
    test('#111111 maps to the matching gray ramp slot', () {
      final c = Profile.ansi256.colorOf('#111111') as Ansi256Color;
      expect(c.value, 233); // 0x121212, nearer than 232 (0x080808)
    });

    test('a mid gray stays on the ramp, not a tinted cube cell', () {
      final c = Profile.ansi256.colorOf('#767676') as Ansi256Color;
      expect(c.value, inInclusiveRange(232, 255));
    });
  });

  group('ANSI sequences', () {
    test('foreground and background differ by ten', () {
      expect(const AnsiColor(1).sequence(), '31');
      expect(const AnsiColor(1).sequence(background: true), '41');
    });

    test('bright colors use the 90 range', () {
      expect(const AnsiColor(9).sequence(), '91');
      expect(const AnsiColor(15).sequence(background: true), '107');
    });
  });
}
