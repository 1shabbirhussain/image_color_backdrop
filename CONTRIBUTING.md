# Contributing

Thanks for helping improve `image_color_backdrop`!

## Ground rules

- Open an issue before large changes so we can agree on the approach.
- Keep the package dependency-free (only the Flutter SDK).
- Every public member needs a dartdoc comment (`public_member_api_docs` is
  enabled).
- Add or update tests for every behavior change, and add a line to
  `CHANGELOG.md`.

## Setup

```sh
flutter pub get
```

## Before opening a pull request

```sh
dart format .
flutter analyze
flutter test
```

CI runs the same commands plus `dart pub publish --dry-run`.

## Project layout

| Path | Contents |
| --- | --- |
| `lib/src/color_quantizer.dart` | Histogram + median cut on raw pixels (no Flutter binding needed). |
| `lib/src/backdrop_palette.dart` | Palette and strategy selection. |
| `lib/src/backdrop_style.dart` | Opacity, brightness, saturation, blend, contrast. |
| `lib/src/image_color_backdrop.dart` | Image loading, caching, `Future` API. |
| `lib/src/backdrop_color_builder.dart`, `image_backdrop.dart`, `backdrop_controller.dart` | Widgets and controller. |
| `test/` | Unit and widget tests. |
| `example/` | Example app. |

## Reporting bugs

Please include the Flutter version (`flutter --version`), the platform, the
smallest image that reproduces the problem, and the options you used.
