import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

import 'test_utils.dart';

void main() {
  const red = Color(0xFFE53935);
  const blue = Color(0xFF1E88E5);
  const white = Color(0xFFFFFFFF);

  group('ColorQuantizer', () {
    test('a solid image yields exactly its color', () {
      final rgba = buildRgba(10, 10, (_, _) => red);
      final swatches = ColorQuantizer.quantize(rgba, width: 10, height: 10);

      expect(swatches, hasLength(1));
      expect(swatches.first.color, red);
      expect(swatches.first.proportion, 1.0);
      expect(swatches.first.population, 100);
    });

    test('swatches are sorted by population and proportions add up to 1', () {
      // 70% red (left 7 columns), 30% blue.
      final rgba = buildRgba(10, 10, (x, _) => x < 7 ? red : blue);
      final swatches = ColorQuantizer.quantize(rgba, width: 10, height: 10);

      expect(swatches.length, greaterThanOrEqualTo(2));
      expect(swatches.first.color, red);
      expect(swatches.first.proportion, closeTo(0.7, 0.001));
      final sum = swatches.fold<double>(0, (a, s) => a + s.proportion);
      expect(sum, closeTo(1.0, 0.0001));
      for (var i = 1; i < swatches.length; i++) {
        expect(
          swatches[i - 1].population,
          greaterThanOrEqualTo(swatches[i].population),
        );
      }
    });

    test('never returns more colors than requested', () {
      final rgba = buildRgba(
        32,
        32,
        (x, y) => Color.fromARGB(255, x * 8, y * 8, (x + y) * 4),
      );
      for (final count in <int>[1, 2, 5, 12]) {
        final swatches = ColorQuantizer.quantize(
          rgba,
          width: 32,
          height: 32,
          colorCount: count,
        );
        expect(swatches.length, lessThanOrEqualTo(count));
        expect(swatches, isNotEmpty);
      }
    });

    test('ignores transparent pixels', () {
      // Left half transparent white, right half opaque blue.
      final rgba = buildRgba(
        10,
        10,
        (x, _) => x < 5 ? const Color(0x00FFFFFF) : blue,
      );
      final swatches = ColorQuantizer.quantize(rgba, width: 10, height: 10);

      expect(swatches, hasLength(1));
      expect(swatches.first.color, blue);
      expect(swatches.first.population, 50);
    });

    test('a fully transparent image yields no swatches', () {
      final rgba = buildRgba(4, 4, (_, _) => const Color(0x00000000));
      expect(ColorQuantizer.quantize(rgba, width: 4, height: 4), isEmpty);
    });

    test('ignoreNearWhite drops a white background', () {
      // White background with a red dot in the middle.
      final rgba = buildRgba(
        20,
        20,
        (x, y) => (x >= 8 && x < 12 && y >= 8 && y < 12) ? red : white,
      );

      final plain = ColorQuantizer.quantize(rgba, width: 20, height: 20);
      expect(plain.first.color, white);

      final filtered = ColorQuantizer.quantize(
        rgba,
        width: 20,
        height: 20,
        ignoreNearWhite: true,
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.color, red);
    });

    test('filters are dropped when they would remove every pixel', () {
      final rgba = buildRgba(6, 6, (_, _) => white);
      final swatches = ColorQuantizer.quantize(
        rgba,
        width: 6,
        height: 6,
        ignoreNearWhite: true,
      );
      expect(swatches.first.color, white);
    });

    test('regions restrict which pixels are sampled', () {
      // Blue frame around a red center.
      final rgba = buildRgba(
        40,
        40,
        (x, y) => (x >= 10 && x < 30 && y >= 10 && y < 30) ? red : blue,
      );

      final whole = ColorQuantizer.quantize(rgba, width: 40, height: 40);
      // Center is 400 px, frame is 1200 px: blue dominates the whole image.
      expect(whole.first.color, blue);

      final center = ColorQuantizer.quantize(
        rgba,
        width: 40,
        height: 40,
        region: BackdropRegion.center,
      );
      expect(center.first.color, red);

      final edges = ColorQuantizer.quantize(
        rgba,
        width: 40,
        height: 40,
        region: BackdropRegion.edges,
      );
      expect(edges, hasLength(1));
      expect(edges.first.color, blue);
    });
  });

  group('BackdropRegion', () {
    test('contains handles rectangles and borders', () {
      expect(BackdropRegion.whole.contains(0.0, 0.0), isTrue);
      expect(BackdropRegion.whole.isWhole, isTrue);
      expect(BackdropRegion.center.contains(0.5, 0.5), isTrue);
      expect(BackdropRegion.center.contains(0.1, 0.5), isFalse);
      expect(BackdropRegion.edges.contains(0.05, 0.5), isTrue);
      expect(BackdropRegion.edges.contains(0.5, 0.5), isFalse);
      expect(BackdropRegion.topQuarter.contains(0.5, 0.1), isTrue);
      expect(BackdropRegion.topQuarter.contains(0.5, 0.9), isFalse);
    });

    test('supports value equality', () {
      expect(
        const BackdropRegion.border(thickness: 0.12),
        BackdropRegion.edges,
      );
      expect(
        const BackdropRegion.rect(left: 0, top: 0, right: 0.5, bottom: 0.5),
        isNot(BackdropRegion.whole),
      );
    });
  });
}
