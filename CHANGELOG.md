# Changelog

All notable changes to this package are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the package
adheres to [Semantic Versioning](https://semver.org/).

## 0.1.0

Initial release.

### Added

- `ImageBackdrop`: a container whose background color is picked from an
  image, with `ImageBackdrop.image` for the common "image on its own color"
  case, gradients, rounded corners, shadows, animated color changes and
  automatic readable text/icon colors.
- `BackdropColorBuilder`: hands the picked color (`BackdropResult`) to any
  widget you build.
- `BackdropController`: a `ChangeNotifier` to share the color across widgets
  and re-style it live.
- `ImageColorBackdrop` and the `ImageProvider.backdropColor()` /
  `backdropPalette()` extensions: a plain `Future` API without widgets.
- `BackdropStyle` with `opacity`, `brightness`, `saturation`, `blendColor`,
  `blendAmount` and `ensureContrastWith`, plus the presets `original`,
  `soft`, `pastel`, `deep` and `subdued`.
- `BackdropOptions` with six color strategies (`dominant`, `vibrant`,
  `muted`, `average`, `lightest`, `darkest`), sampled regions
  (`whole`, `center`, `edges`, quarters and custom rectangles),
  `ignoreNearWhite`, `ignoreNearBlack`, transparency threshold and sampling
  size.
- Pure Dart histogram + median cut `ColorQuantizer`, an in-memory LRU
  `BackdropCache`, request de-duplication, and `BackdropColorUtils`
  (contrast ratio, readable foreground, lighten/darken).
- Example app with a gallery, a live playground and "use the color
  elsewhere" demos.
