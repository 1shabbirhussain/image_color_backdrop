# image_color_backdrop

[![pub package](https://img.shields.io/pub/v/image_color_backdrop.svg)](https://pub.dev/packages/image_color_backdrop)
[![pub points](https://img.shields.io/pub/points/image_color_backdrop)](https://pub.dev/packages/image_color_backdrop/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Stop hand-picking background colors for your images, icons and logos.**
`image_color_backdrop` looks at an image, finds its most prominent color and
gives you a ready-to-use background color, with knobs for opacity, brightness,
saturation, blending, contrast and gradients, so the result fits your design
instead of fighting it.

```dart
ImageBackdrop.image(
  image: const AssetImage('assets/logo.png'),
  width: 120,
  height: 120,
  borderRadius: BorderRadius.circular(24),
)
```

That is the whole integration: the logo is shown on a container whose color
was picked from the logo itself.

## Contents

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Choosing the right API](#choosing-the-right-api)
- [Controlling the color: BackdropStyle](#controlling-the-color-backdropstyle)
- [Choosing the color: BackdropOptions](#choosing-the-color-backdropoptions)
- [Recipes](#recipes)
- [Performance and caching](#performance-and-caching)
- [How it works](#how-it-works)
- [Platform support](#platform-support)
- [FAQ](#faq)
- [Example app](#example-app)
- [Contributing](#contributing)
- [License](#license)

## Features

- **One-line widget.** `ImageBackdrop.image(...)` shows an image on its own
  picked color; `ImageBackdrop(child: ...)` puts anything on it.
- **Use the color anywhere.** `BackdropColorBuilder` hands you the color for
  any `Container`, `Card`, `AppBar`, `BoxDecoration` or `TextStyle`.
  `BackdropController` shares it across widgets. The `Future` API works
  without widgets at all.
- **Six ways to pick the color.** `dominant`, `vibrant`, `muted`, `average`,
  `lightest`, `darkest`.
- **Full control over the result.** `opacity`, `brightness`, `saturation`,
  blend another color in, and guarantee a minimum contrast.
- **Smart sampling.** Ignore transparent pixels, ignore white studio
  backgrounds, or sample only the *edges* of a logo to match what surrounds
  it.
- **Readable by default.** Text and icons on the backdrop automatically switch
  between light and dark (WCAG contrast ratio).
- **Gradients.** Tonal (lighter to darker) or palette (main color to second
  color) gradients.
- **Fast.** Images are decoded at a small size, quantization takes
  milliseconds, results are cached (LRU) and identical concurrent requests are
  shared.
- **Pure Dart.** No native code, no extra dependencies, works on every Flutter
  platform.

## Installation

```yaml
dependencies:
  image_color_backdrop: ^0.1.0
```

or run:

```sh
flutter pub add image_color_backdrop
```

Requires Flutter 3.32 or newer (Dart 3.8).

```dart
import 'package:image_color_backdrop/image_color_backdrop.dart';
```

## Quick start

### 1. Show an image on its own color

```dart
ImageBackdrop.image(
  image: const AssetImage('assets/logo.png'),
  width: 120,
  height: 120,
  padding: const EdgeInsets.all(20),
  borderRadius: BorderRadius.circular(24),
  style: BackdropStyle.soft, // 18% opacity tint
)
```

### 2. Put any widget on the picked color

```dart
const cover = NetworkImage('https://example.com/cover.jpg');

ImageBackdrop(
  image: cover,
  style: BackdropStyle.pastel,
  padding: const EdgeInsets.all(16),
  borderRadius: BorderRadius.circular(16),
  child: Row(
    children: const [
      Icon(Icons.album),          // color adapts automatically
      SizedBox(width: 12),
      Text('Now playing'),         // so does the text
    ],
  ),
)
```

### 3. Use the color for anything

```dart
BackdropColorBuilder(
  image: const AssetImage('assets/logo.png'),
  builder: (context, result) {
    return Container(
      decoration: BoxDecoration(
        color: result.color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Text('Hello', style: TextStyle(color: result.onColor)),
    );
  },
)
```

`result` is a `BackdropResult`:

| Property | Meaning |
| --- | --- |
| `color` | The final background color (picked color with your `BackdropStyle` applied). |
| `sourceColor` | The color picked from the image, before styling. |
| `onColor` / `onColorFor(surface)` | A readable text or icon color for `color`. |
| `palette` | Every extracted color (`BackdropPalette`). |
| `tonalGradient()` / `paletteGradient()` | Ready-made two-color gradients. |
| `isFallback` | `true` while loading, after an error, or for an empty image. |

### 4. Get the color without any widget

```dart
final color = await const AssetImage('assets/logo.png').backdropColor(
  style: const BackdropStyle(opacity: 0.2),
);

final palette = await NetworkImage(url).backdropPalette();
print(palette.vibrant); // Color?
```

Or, equivalently, `ImageColorBackdrop.colorFromImageProvider(...)`,
`ImageColorBackdrop.paletteFromImageProvider(...)`,
`ImageColorBackdrop.paletteFromBytes(...)` and
`ImageColorBackdrop.paletteFromImage(ui.Image)`.

### 5. Use the color somewhere else on the screen

```dart
final controller = BackdropController(
  style: const BackdropStyle(opacity: 0.85),
)..load(const AssetImage('assets/cover.jpg'));

// Anywhere in your tree:
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    color: controller.color,
  ),
);

// Later, when the user selects another image:
controller.load(const AssetImage('assets/other.jpg'));

// Re-style live, without decoding the image again:
controller.style = BackdropStyle.deep;

// Don't forget:
controller.dispose();
```

## Choosing the right API

| I want to... | Use |
| --- | --- |
| show an image on a matching background | `ImageBackdrop.image` |
| put my own widgets on a matching background | `ImageBackdrop` |
| color a widget I build myself | `BackdropColorBuilder` |
| use the color outside the image's subtree, or share it | `BackdropController` |
| get a `Color` in plain Dart code | `provider.backdropColor()` or `ImageColorBackdrop` |
| analyze pixels I already have | `ImageColorBackdrop.paletteFromRgba` |

## Controlling the color: BackdropStyle

`BackdropStyle` turns the picked color into the final one. Steps are applied in
this order: saturation, brightness, blend, contrast, opacity.

| Property | Range | Default | Effect |
| --- | --- | --- | --- |
| `opacity` | 0.0 to 1.0 | 1.0 | Multiplies the alpha. Lower for a subtle tint. |
| `brightness` | -1.0 to 1.0 | 0.0 | Negative mixes in black, positive mixes in white. |
| `saturation` | -1.0 to 1.0 | 0.0 | Negative desaturates toward gray, positive boosts intensity. |
| `blendColor` | any `Color?` | null | A color mixed into the picked one, for example your surface color. |
| `blendAmount` | 0.0 to 1.0 | 0.0 | How much of `blendColor` is mixed in. |
| `ensureContrastWith` | any `Color?` | null | Keep at least `minContrastRatio` against this color. |
| `minContrastRatio` | 1.0 to 21.0 | 3.0 | 3.0 suits graphics and large text, 4.5 suits normal text. |

Presets: `BackdropStyle.original`, `.soft`, `.pastel`, `.deep`, `.subdued`.

```dart
// A white logo must stay visible: never let the background get too light.
const style = BackdropStyle(
  ensureContrastWith: Colors.white,
  minContrastRatio: 3,
);

// Calm, slightly desaturated background that blends into the page.
final calm = BackdropStyle(
  saturation: -0.3,
  blendColor: Theme.of(context).colorScheme.surface,
  blendAmount: 0.4,
);
```

You can also call `style.apply(someColor)` yourself.

## Choosing the color: BackdropOptions

| Property | Default | Effect |
| --- | --- | --- |
| `strategy` | `dominant` | Which palette color becomes the backdrop (see below). |
| `region` | `BackdropRegion.whole` | Which part of the image is sampled. |
| `colorCount` | 8 | Palette size (1 to 64). |
| `maxDimension` | 96 | The image is scaled so its longest side is at most this many pixels before sampling. |
| `alphaThreshold` | 16 | Pixels with a lower alpha (0 to 255) are ignored. |
| `ignoreNearWhite` | false | Skip white pixels (for example a white studio background). |
| `ignoreNearBlack` | false | Skip black pixels. |
| `fallbackColor` | `0xFFE0E0E0` | Used while loading, on errors and for empty images. |

### Strategies

| Strategy | Picks | Good for |
| --- | --- | --- |
| `dominant` | The color covering the most pixels. | The safe default. |
| `vibrant` | A saturated, mid-lightness color. | Accents, buttons, chips. A mostly white photo with a small red logo gives red. |
| `muted` | A softer, less saturated color. | Calm card or page backgrounds. |
| `average` | The pixel-weighted mean. | Stable, but can look muddy for contrasting images. |
| `lightest` | The lightest significant color. | Light surfaces. |
| `darkest` | The darkest significant color. | Dark surfaces, hero banners. |

### Regions

`BackdropRegion.whole` (default), `.center`, `.edges`, `.topQuarter`,
`.bottomQuarter`, `.leftQuarter`, `.rightQuarter`, plus
`BackdropRegion.border(thickness: 0.2)` and
`BackdropRegion.rect(left: 0, top: 0, right: 0.5, bottom: 1)` for custom areas
(all values normalized to 0..1).

`edges` is the best choice for logos and icons that ship with their own
background: it continues the color that already surrounds the mark.

## Recipes

**A list of brands, each on its own color**

```dart
ListView.builder(
  itemCount: brands.length,
  itemBuilder: (context, i) => ImageBackdrop.image(
    image: NetworkImage(brands[i].logoUrl),
    height: 96,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    borderRadius: BorderRadius.circular(16),
    style: BackdropStyle.pastel,
  ),
)
```

**Product photos on white**

```dart
const BackdropOptions(
  strategy: BackdropStrategy.vibrant,
  ignoreNearWhite: true,
)
```

**Tint the AppBar with the current album cover**

```dart
BackdropColorBuilder(
  image: albumCover,
  builder: (context, result) => AppBar(
    backgroundColor: result.color,
    foregroundColor: result.onColor,
    title: const Text('Now playing'),
  ),
)
```

**Match the color around a logo**

```dart
ImageBackdrop.image(
  image: const AssetImage('assets/logo_with_background.png'),
  options: const BackdropOptions(region: BackdropRegion.edges),
)
```

**Gradient from the image's two main colors**

```dart
ImageBackdrop.image(
  image: cover,
  gradientMode: BackdropGradientMode.palette,
  gradientBegin: Alignment.topCenter,
  gradientEnd: Alignment.bottomCenter,
)
```

**Do something when the color is ready**

```dart
ImageBackdrop.image(
  image: cover,
  onChanged: (result) => context.read<ThemeCubit>().setAccent(result.color),
  onError: (error, stack) => debugPrint('Could not analyze image: $error'),
)
```

**Dark mode.** `ImageBackdrop` picks readable foreground colors against the
current theme's surface, so translucent styles such as `BackdropStyle.soft`
stay readable in both light and dark themes. When you build your own widgets,
use `result.onColorFor(Theme.of(context).colorScheme.surface)`.

More recipes live in [doc/cookbook.md](doc/cookbook.md).

## Performance and caching

- Images are decoded at a reduced size (`maxDimension`, 96 by default), so the
  cost is small even for very large photos.
- Palettes are cached in memory, keyed by the image and the sampling options
  (changing only `strategy`, `style` or `fallbackColor` never re-decodes).
  `ImageColorBackdrop.cache` lets you tune it:

  ```dart
  ImageColorBackdrop.cache.maximumSize = 256; // default 128, 0 disables
  ImageColorBackdrop.cache.clear();
  ```

- Several widgets asking for the same image at the same time share a single
  extraction.
- Pass `useCache: false` to the `Future` API to bypass the cache.
- When the color is needed the moment a screen appears, warm the cache first:

  ```dart
  await Future.wait(urls.map((u) => NetworkImage(u).backdropPalette()));
  ```

## How it works

1. The image is resolved through Flutter's normal `ImageProvider` pipeline and
   decoded at a small size (`ResizeImage`).
2. Pixels are counted in a 32x32x32 color histogram. Transparent pixels, the
   optional white/black pixels and pixels outside the chosen region are
   skipped.
3. A median cut algorithm splits the histogram into `colorCount` groups; the
   average of each group becomes a swatch with its population.
4. The chosen strategy picks one swatch. Your `BackdropStyle` is applied and a
   readable foreground color is computed with the WCAG contrast formula.

Details are in [doc/how_it_works.md](doc/how_it_works.md).

## Platform support

| Android | iOS | Web | macOS | Windows | Linux |
| :---: | :---: | :---: | :---: | :---: | :---: |
| yes | yes | yes | yes | yes | yes |

The package is written in pure Dart on top of Flutter's `dart:ui`, so it has no
platform-specific code. On the web, images loaded from another origin must
allow cross-origin access (CORS) so their pixels can be read.

## FAQ

**Does it support SVG?**
SVG is not a raster image, so it cannot be sampled directly. Render the SVG to
a `ui.Image` (for example with a `PictureRecorder`) and pass it to
`ImageColorBackdrop.paletteFromImage`, or pick the color from a PNG version.

**What about animated GIFs / WebP?**
The first frame is used.

**The result is gray/white for my logo.**
The logo probably sits on a white or transparent background. Set
`ignoreNearWhite: true`, or use `BackdropStrategy.vibrant`, or sample only the
region you care about.

**How is this different from `ColorScheme.fromImageProvider`?**
`ColorScheme.fromImageProvider` builds a complete Material 3 color scheme from
one source color. This package focuses on a single, controllable *backdrop*
color and on the widgets around it: strategies, regions, opacity, contrast,
gradients, caching and drop-in widgets. They combine well: pass
`await provider.backdropColor()` to `ColorScheme.fromSeed`.

**Can I run the extraction off the main isolate?**
Decoding already happens off the UI thread inside the engine, and quantizing a
96x96 sample takes a few milliseconds. If you use very large `maxDimension`
values, run `ImageColorBackdrop.paletteFromRgba` inside `compute` yourself.

**Is the color deterministic?**
Yes. The same pixels and options always give the same palette on every
platform.

## Example app

A complete example (gallery, live playground, "use the color elsewhere") is in
[`example/`](example). To run it:

```sh
cd example
flutter create .   # generates the platform folders once
flutter run
```

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT, see [LICENSE](LICENSE). Copyright (c) 2026 Shabbir Hussain.
