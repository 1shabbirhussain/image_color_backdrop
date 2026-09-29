import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'backdrop_options.dart';
import 'backdrop_palette.dart';
import 'backdrop_style.dart';
import 'color_utils.dart';

/// Everything a widget needs to paint a backdrop: the extracted palette, the
/// picked color, the styled final color and a readable foreground color.
@immutable
class BackdropResult {
  const BackdropResult._({
    required this.palette,
    required this.options,
    required this.style,
    required this.sourceColor,
    required this.color,
    required this.isFallback,
  });

  /// Builds a result from an extracted [palette].
  ///
  /// The color is chosen with [BackdropOptions.strategy] and transformed by
  /// [style]. An empty palette yields a fallback result.
  factory BackdropResult.fromPalette(
    BackdropPalette palette, {
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
  }) {
    final picked = palette.colorFor(options.strategy);
    if (picked == null) {
      return BackdropResult.fallback(options: options, style: style);
    }
    return BackdropResult._(
      palette: palette,
      options: options,
      style: style,
      sourceColor: picked,
      color: style.apply(picked),
      isFallback: false,
    );
  }

  /// A result that carries [BackdropOptions.fallbackColor]. It is what
  /// widgets report while an image is loading or when loading failed.
  factory BackdropResult.fallback({
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
  }) {
    return BackdropResult._(
      palette: BackdropPalette.empty,
      options: options,
      style: style,
      sourceColor: options.fallbackColor,
      color: style.apply(options.fallbackColor),
      isFallback: true,
    );
  }

  /// All colors extracted from the image (empty for a fallback result).
  final BackdropPalette palette;

  /// The options that were used.
  final BackdropOptions options;

  /// The style that was applied.
  final BackdropStyle style;

  /// The color chosen from the image, before [style] was applied.
  final Color sourceColor;

  /// The final background color: [sourceColor] transformed by [style].
  final Color color;

  /// `true` while loading, after an error, or for an image without usable
  /// pixels. In that case [color] is derived from
  /// [BackdropOptions.fallbackColor].
  final bool isFallback;

  /// A text/icon color that is readable on [color] when [color] is drawn on
  /// a white surface.
  Color get onColor => onColorFor(const Color(0xFFFFFFFF));

  /// A text/icon color that is readable on [color] when [color] is drawn on
  /// [surface]. This matters for translucent styles, because the visible
  /// color then depends on what is behind it.
  Color onColorFor(Color surface) =>
      BackdropColorUtils.readableOn(color, surface: surface);

  /// A subtle two-color gradient built from [color]: slightly lighter to
  /// slightly darker. [amount] (0–1) controls how far the colors move.
  List<Color> tonalGradient({double amount = 0.15}) => <Color>[
        BackdropColorUtils.lighten(color, amount),
        BackdropColorUtils.darken(color, amount),
      ];

  /// A two-color gradient from [color] to the most prominent *other* color
  /// of the image (styled the same way). Falls back to [tonalGradient] when
  /// the image has only one distinct color.
  List<Color> paletteGradient() {
    final second = palette.secondaryTo(sourceColor);
    if (second == null) {
      return tonalGradient();
    }
    return <Color>[color, style.apply(second.color)];
  }

  @override
  bool operator ==(Object other) =>
      other is BackdropResult &&
      other.color == color &&
      other.sourceColor == sourceColor &&
      other.isFallback == isFallback &&
      other.palette == palette;

  @override
  int get hashCode => Object.hash(color, sourceColor, isFallback, palette);

  @override
  String toString() => 'BackdropResult(color: $color, '
      'sourceColor: $sourceColor, isFallback: $isFallback)';
}
