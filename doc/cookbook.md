# Cookbook

Copy-paste solutions for common situations. All snippets assume:

```dart
import 'package:flutter/material.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';
```

## Avatars and app icons with matching tiles

```dart
ImageBackdrop.image(
  image: NetworkImage(app.iconUrl),
  width: 64,
  height: 64,
  padding: const EdgeInsets.all(10),
  borderRadius: BorderRadius.circular(16),
  style: BackdropStyle.soft,
)
```

## A logo that must stay visible on its backdrop

White logos disappear on light backgrounds. Keep the backdrop dark enough:

```dart
ImageBackdrop.image(
  image: const AssetImage('assets/white_logo.png'),
  style: const BackdropStyle(
    ensureContrastWith: Colors.white,
    minContrastRatio: 3,
  ),
)
```

## A card whose accent comes from its cover

```dart
BackdropColorBuilder(
  image: NetworkImage(book.coverUrl),
  options: const BackdropOptions(strategy: BackdropStrategy.vibrant),
  style: BackdropStyle.pastel,
  builder: (context, result) => Card(
    color: result.color,
    child: ListTile(
      leading: Image.network(book.coverUrl, width: 40),
      title: Text(book.title, style: TextStyle(color: result.onColor)),
    ),
  ),
)
```

## A whole page that follows the selected image

```dart
class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final controller = BackdropController(
    options: const BackdropOptions(ignoreNearWhite: true),
    style: BackdropStyle.pastel,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: controller.color,
        body: PhotoCarousel(
          onPageChanged: (photo) => controller.load(NetworkImage(photo.url)),
        ),
      ),
    );
  }
}
```

## Blend the backdrop into your theme

Mixing some of the surface color into the picked color makes strong logo colors
sit calmly on your page:

```dart
BackdropStyle(
  saturation: -0.2,
  blendColor: Theme.of(context).colorScheme.surface,
  blendAmount: 0.5,
)
```

## Different look in light and dark mode

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;

ImageBackdrop.image(
  image: logo,
  style: isDark ? BackdropStyle.deep : BackdropStyle.pastel,
)
```

## Match the color already surrounding a logo

```dart
ImageBackdrop.image(
  image: const AssetImage('assets/badge_on_color.png'),
  options: const BackdropOptions(region: BackdropRegion.edges),
)
```

## Build a Material 3 scheme from the picked color

```dart
final color = await NetworkImage(url).backdropColor(
  options: const BackdropOptions(strategy: BackdropStrategy.vibrant),
);
final scheme = ColorScheme.fromSeed(seedColor: color);
```

## Read a palette in a repository or view model

```dart
final palette = await AssetImage('assets/hero.png').backdropPalette(
  options: const BackdropOptions(colorCount: 6),
);

final accent = palette.vibrant ?? palette.dominant;
final onAccent = accent == null
    ? null
    : BackdropColorUtils.readableOn(accent);
```

## Analyze pixels you already have

```dart
final palette = ImageColorBackdrop.paletteFromRgba(
  rgbaBytes,           // straight (non-premultiplied) RGBA
  width: 64,
  height: 64,
);
```

## Analyze an SVG

```dart
// 1. Render the SVG to a ui.Image with your SVG library of choice.
final ui.Image image = await renderSvgToImage(svg);

// 2. Extract the palette. You own the image and must dispose it.
final palette = await ImageColorBackdrop.paletteFromImage(image);
image.dispose();
```

## Test widgets that use the package

Image decoding needs real asynchrony, so wrap it in `tester.runAsync`:

```dart
testWidgets('shows the picked color', (tester) async {
  final bytes = await tester.runAsync(() => makePng());
  await tester.pumpWidget(MaterialApp(
    home: ImageBackdrop(image: MemoryImage(bytes!), duration: Duration.zero),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
  // expect(...)
});
```

To avoid decoding in unit tests entirely, use
`ImageColorBackdrop.paletteFromRgba` with synthetic pixels.
