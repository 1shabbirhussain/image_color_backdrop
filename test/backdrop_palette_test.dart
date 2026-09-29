import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

PaletteSwatch swatch(Color color, int population, int total) => PaletteSwatch(
      color: color,
      population: population,
      proportion: population / total,
    );

void main() {
  const gray = Color(0xFF9E9E9E);
  const red = Color(0xFFE53935);
  const lightBlue = Color(0xFFBBDEFB);
  const navy = Color(0xFF0D1B4A);

  final palette = BackdropPalette([
    swatch(red, 100, 1000),
    swatch(gray, 600, 1000),
    swatch(lightBlue, 200, 1000),
    swatch(navy, 100, 1000),
  ]);

  group('BackdropPalette', () {
    test('sorts swatches by population', () {
      expect(palette.swatches.first.color, gray);
      expect(palette.swatches.map((s) => s.population), <int>[600, 200, 100, 100]);
    });

    test('dominant is the most populous color', () {
      expect(palette.dominant, gray);
    });

    test('vibrant prefers the saturated color over the dominant gray', () {
      expect(palette.vibrant, red);
    });

    test('lightest and darkest pick the extremes', () {
      expect(palette.lightest, lightBlue);
      expect(palette.darkest, navy);
    });

    test('average is the population weighted mean', () {
      final two = BackdropPalette([
        swatch(const Color(0xFF000000), 1, 2),
        swatch(const Color(0xFFFFFFFF), 1, 2),
      ]);
      final average = two.average!;
      expect(BackdropColorUtils.red(average), inInclusiveRange(127, 128));
    });

    test('an empty palette returns null for every strategy', () {
      expect(BackdropPalette.empty.isEmpty, isTrue);
      for (final strategy in BackdropStrategy.values) {
        expect(BackdropPalette.empty.colorFor(strategy), isNull);
      }
    });

    test('secondaryTo skips colors that are too similar', () {
      final similar = BackdropPalette([
        swatch(const Color(0xFF808080), 10, 20),
        swatch(const Color(0xFF828282), 6, 20),
        swatch(red, 4, 20),
      ]);
      expect(similar.secondaryTo(const Color(0xFF808080))!.color, red);
      expect(
        BackdropPalette([swatch(gray, 1, 1)]).secondaryTo(gray),
        isNull,
      );
    });
  });

  group('BackdropResult', () {
    test('fromPalette applies strategy and style', () {
      final result = BackdropResult.fromPalette(
        palette,
        options: const BackdropOptions(strategy: BackdropStrategy.vibrant),
        style: const BackdropStyle(opacity: 0.5),
      );
      expect(result.isFallback, isFalse);
      expect(result.sourceColor, red);
      expect(result.color.a, closeTo(0.5, 0.01));
    });

    test('an empty palette gives the fallback color', () {
      const fallback = Color(0xFF123456);
      final result = BackdropResult.fromPalette(
        BackdropPalette.empty,
        options: const BackdropOptions(fallbackColor: fallback),
      );
      expect(result.isFallback, isTrue);
      expect(result.color, fallback);
    });

    test('gradients have two colors', () {
      final result = BackdropResult.fromPalette(palette);
      expect(result.tonalGradient(), hasLength(2));
      expect(result.paletteGradient(), hasLength(2));
      expect(result.paletteGradient().first, result.color);
    });
  });

  group('BackdropOptions', () {
    test('strategy does not change the sampling signature', () {
      const a = BackdropOptions(strategy: BackdropStrategy.dominant);
      const b = BackdropOptions(strategy: BackdropStrategy.vibrant);
      expect(a.samplingSignature, b.samplingSignature);
      expect(a, isNot(b));
      expect(a.copyWith(colorCount: 4).samplingSignature,
          isNot(a.samplingSignature));
    });
  });

  group('BackdropCache', () {
    test('evicts the least recently used entry', () {
      final cache = BackdropCache(maximumSize: 2);
      final a = BackdropPalette.empty;
      cache
        ..put('a', a)
        ..put('b', a);
      cache.get('a'); // 'b' is now the least recently used.
      cache.put('c', a);

      expect(cache.length, 2);
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), isNotNull);
      expect(cache.get('c'), isNotNull);
    });

    test('a maximumSize of zero disables caching', () {
      final cache = BackdropCache(maximumSize: 0)
        ..put('a', BackdropPalette.empty);
      expect(cache.length, 0);
    });
  });
}
