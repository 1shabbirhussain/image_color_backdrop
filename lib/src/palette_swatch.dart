import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show HSLColor;

import 'color_utils.dart';

/// One color found in an image, together with how much of the image it
/// covers.
class PaletteSwatch {
  /// Creates a swatch.
  const PaletteSwatch({
    required this.color,
    required this.population,
    required this.proportion,
  });

  /// The (average) color of this swatch. Always fully opaque.
  final Color color;

  /// How many sampled pixels belong to this swatch.
  final int population;

  /// The share of all sampled pixels that belong to this swatch, from `0.0`
  /// to `1.0`.
  final double proportion;

  /// The color in the HSL color space.
  HSLColor get hsl => HSLColor.fromColor(color);

  /// HSL saturation, from `0.0` (gray) to `1.0` (fully saturated).
  double get saturation => hsl.saturation;

  /// HSL lightness, from `0.0` (black) to `1.0` (white).
  double get lightness => hsl.lightness;

  /// A text/icon color that is readable on top of this swatch.
  Color get onColor => BackdropColorUtils.readableOn(color);

  @override
  bool operator ==(Object other) =>
      other is PaletteSwatch &&
      other.color == color &&
      other.population == population;

  @override
  int get hashCode => Object.hash(color, population);

  @override
  String toString() =>
      'PaletteSwatch(color: $color, population: $population, '
      'proportion: ${proportion.toStringAsFixed(3)})';
}
