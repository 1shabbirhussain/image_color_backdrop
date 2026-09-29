import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

void main() {
  const blue = Color(0xFF1E88E5);

  group('BackdropStyle', () {
    test('the default style leaves the color untouched', () {
      expect(const BackdropStyle().apply(blue), blue);
      expect(BackdropStyle.original.apply(blue), blue);
    });

    test('opacity multiplies alpha', () {
      final result = const BackdropStyle(opacity: 0.5).apply(blue);
      expect(result.a, closeTo(0.5, 0.01));
      expect(BackdropColorUtils.red(result), BackdropColorUtils.red(blue));

      final twice = const BackdropStyle(opacity: 0.5)
          .apply(blue.withValues(alpha: 0.5));
      expect(twice.a, closeTo(0.25, 0.01));
    });

    test('brightness reaches white and black at the extremes', () {
      expect(
        const BackdropStyle(brightness: 1).apply(blue),
        const Color(0xFFFFFFFF),
      );
      expect(
        const BackdropStyle(brightness: -1).apply(blue),
        const Color(0xFF000000),
      );
      final lighter = const BackdropStyle(brightness: 0.4).apply(blue);
      expect(lighter.computeLuminance(), greaterThan(blue.computeLuminance()));
      final darker = const BackdropStyle(brightness: -0.4).apply(blue);
      expect(darker.computeLuminance(), lessThan(blue.computeLuminance()));
    });

    test('saturation -1 produces a gray', () {
      final gray = const BackdropStyle(saturation: -1).apply(blue);
      expect(BackdropColorUtils.red(gray), BackdropColorUtils.green(gray));
      expect(BackdropColorUtils.green(gray), BackdropColorUtils.blue(gray));
    });

    test('blendAmount 1 replaces the color with the blend color', () {
      const orange = Color(0xFFFF9800);
      final result =
          const BackdropStyle(blendColor: orange, blendAmount: 1).apply(blue);
      expect(result, orange);
    });

    test('ensureContrastWith keeps the minimum contrast ratio', () {
      const lightGray = Color(0xFFEEEEEE);
      const white = Color(0xFFFFFFFF);
      final result = const BackdropStyle(
        ensureContrastWith: white,
        minContrastRatio: 4.5,
      ).apply(lightGray);
      expect(
        BackdropColorUtils.contrastRatio(result, white),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('supports value equality and copyWith', () {
      expect(const BackdropStyle(opacity: 0.4), const BackdropStyle(opacity: 0.4));
      expect(
        const BackdropStyle(opacity: 0.4).copyWith(brightness: 0.1),
        const BackdropStyle(opacity: 0.4, brightness: 0.1),
      );
      expect(BackdropStyle.soft, isNot(BackdropStyle.deep));
    });
  });

  group('BackdropColorUtils', () {
    test('contrastRatio of black on white is 21', () {
      expect(
        BackdropColorUtils.contrastRatio(
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ),
        closeTo(21, 0.01),
      );
    });

    test('readableOn picks a light color on dark and a dark color on light', () {
      expect(
        BackdropColorUtils.readableOn(const Color(0xFF101010)),
        const Color(0xFFFFFFFF),
      );
      expect(
        BackdropColorUtils.readableOn(const Color(0xFFF5F5F5)),
        const Color(0xFF111111),
      );
    });

    test('readableOn considers the surface behind translucent colors', () {
      final translucent = const Color(0xFF000000).withValues(alpha: 0.1);
      // Over white it looks light -> dark text.
      expect(
        BackdropColorUtils.readableOn(translucent),
        const Color(0xFF111111),
      );
      // Over black it looks dark -> light text.
      expect(
        BackdropColorUtils.readableOn(
          translucent,
          surface: const Color(0xFF000000),
        ),
        const Color(0xFFFFFFFF),
      );
    });

    test('distance is 0 for equal colors and 1 for black vs white', () {
      expect(BackdropColorUtils.distance(blue, blue), 0);
      expect(
        BackdropColorUtils.distance(
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ),
        closeTo(1, 0.0001),
      );
    });
  });
}
