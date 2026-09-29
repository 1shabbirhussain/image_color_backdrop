import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

import 'test_utils.dart';

/// Lets real async work (image decoding) finish, then pumps a frame.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
}

void main() {
  const red = Color(0xFFE53935);
  const fallback = Color(0xFF00FF00);

  setUp(() => ImageColorBackdrop.cache.clear());

  testWidgets('BackdropColorBuilder starts with the fallback, then the color', (
    tester,
  ) async {
    final Uint8List bytes = (await tester.runAsync(() => solidPng(red)))!;
    final seen = <BackdropResult>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BackdropColorBuilder(
          image: MemoryImage(bytes),
          options: const BackdropOptions(fallbackColor: fallback),
          builder: (context, result) {
            seen.add(result);
            return ColoredBox(color: result.color);
          },
        ),
      ),
    );

    expect(seen.first.isFallback, isTrue);
    expect(seen.first.color, fallback);

    await settle(tester);

    expect(seen.last.isFallback, isFalse);
    expect(seen.last.color, red);
  });

  testWidgets('BackdropColorBuilder reports errors and keeps the fallback', (
    tester,
  ) async {
    Object? error;
    BackdropResult? last;

    await tester.pumpWidget(
      MaterialApp(
        home: BackdropColorBuilder(
          image: MemoryImage(Uint8List.fromList(<int>[1, 2, 3])),
          onError: (e, _) => error = e,
          builder: (context, result) {
            last = result;
            return const SizedBox();
          },
        ),
      ),
    );
    await settle(tester);

    expect(error, isNotNull);
    expect(last!.isFallback, isTrue);
  });

  testWidgets('ImageBackdrop paints the picked color', (tester) async {
    final Uint8List bytes = (await tester.runAsync(() => solidPng(red)))!;

    await tester.pumpWidget(
      MaterialApp(
        home: ImageBackdrop(
          image: MemoryImage(bytes),
          duration: Duration.zero,
          child: const Text('Hello'),
        ),
      ),
    );
    await settle(tester);

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, red);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('BackdropController exposes the color and reacts to style', (
    tester,
  ) async {
    final Uint8List bytes = (await tester.runAsync(() => solidPng(red)))!;
    final controller = BackdropController();
    addTearDown(controller.dispose);

    expect(controller.result.isFallback, isTrue);

    await tester.runAsync(() => controller.load(MemoryImage(bytes)));
    expect(controller.isLoading, isFalse);
    expect(controller.color, red);

    controller.style = const BackdropStyle(opacity: 0.5);
    expect(controller.color.a, closeTo(0.5, 0.01));
  });
}
