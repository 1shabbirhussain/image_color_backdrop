import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const red = Color(0xFFE53935);

  setUp(() => ImageColorBackdrop.cache.clear());

  testWidgets('extracts the color of an ImageProvider', (tester) async {
    final color = await tester.runAsync(() async {
      final bytes = await solidPng(red);
      return ImageColorBackdrop.colorFromImageProvider(MemoryImage(bytes));
    });
    expect(color, red);
  });

  testWidgets('applies the style to the returned color', (tester) async {
    final color = await tester.runAsync(() async {
      final bytes = await solidPng(red);
      return MemoryImage(bytes).backdropColor(
        style: const BackdropStyle(opacity: 0.5),
      );
    });
    expect(color!.a, closeTo(0.5, 0.01));
  });

  testWidgets('paletteFromBytes decodes encoded images', (tester) async {
    final palette = await tester.runAsync(() async {
      final bytes = await solidPng(red);
      return ImageColorBackdrop.paletteFromBytes(bytes);
    });
    expect(palette!.dominant, red);
  });

  testWidgets('downscales large images', (tester) async {
    final palette = await tester.runAsync(() async {
      final bytes = await solidPng(red, size: 300);
      return ImageColorBackdrop.paletteFromImageProvider(
        MemoryImage(bytes),
        options: const BackdropOptions(maxDimension: 32),
      );
    });
    expect(palette!.dominant, red);
  });

  testWidgets('results are cached and shared', (tester) async {
    await tester.runAsync(() async {
      final bytes = await solidPng(red);
      final provider = MemoryImage(bytes);
      final first = await ImageColorBackdrop.paletteFromImageProvider(provider);
      final second = await ImageColorBackdrop.paletteFromImageProvider(provider);
      expect(identical(first, second), isTrue);
      expect(ImageColorBackdrop.cache.length, 1);

      final uncached = await ImageColorBackdrop.paletteFromImageProvider(
        provider,
        useCache: false,
      );
      expect(identical(first, uncached), isFalse);
    });
  });

  testWidgets('a broken image throws', (tester) async {
    final future = tester.runAsync(() async {
      try {
        await ImageColorBackdrop.paletteFromImageProvider(
          MemoryImage(Uint8List.fromList(<int>[1, 2, 3])),
        );
        return false;
      } catch (_) {
        return true;
      }
    });
    expect(await future, isTrue);
  });

  test('paletteFromRgba is synchronous', () {
    final rgba = buildRgba(4, 4, (_, __) => red);
    final palette = ImageColorBackdrop.paletteFromRgba(
      rgba,
      width: 4,
      height: 4,
    );
    expect(palette.dominant, red);
  });
}
