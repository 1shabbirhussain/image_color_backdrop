import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'backdrop_region.dart';

/// How the backdrop color is chosen from the colors found in an image.
enum BackdropStrategy {
  /// The color that covers the most pixels. Best all-round default and the
  /// closest match to "the color of the image".
  dominant,

  /// A saturated, mid-lightness color that stands out. Ideal for accents:
  /// a mostly white photo with a small red logo yields red.
  vibrant,

  /// A softer, less saturated color. Ideal for calm card or page backgrounds.
  muted,

  /// The pixel-weighted average of every sampled color. Can look muddy for
  /// images with contrasting colors, but is perfectly stable.
  average,

  /// The lightest of the significant colors in the image.
  lightest,

  /// The darkest of the significant colors in the image.
  darkest,
}

/// Settings that control how an image is sampled and which color is picked.
///
/// The defaults work well for icons, logos and photos. Every instance is
/// immutable and can be shared freely.
@immutable
class BackdropOptions {
  /// Creates sampling options.
  const BackdropOptions({
    this.strategy = BackdropStrategy.dominant,
    this.region = BackdropRegion.whole,
    this.colorCount = 8,
    this.maxDimension = 96,
    this.alphaThreshold = 16,
    this.ignoreNearWhite = false,
    this.ignoreNearBlack = false,
    this.fallbackColor = const Color(0xFFE0E0E0),
  })  : assert(colorCount >= 1 && colorCount <= 64,
            'colorCount must be between 1 and 64'),
        assert(maxDimension >= 8 && maxDimension <= 1024,
            'maxDimension must be between 8 and 1024'),
        assert(alphaThreshold >= 0 && alphaThreshold <= 255,
            'alphaThreshold must be between 0 and 255');

  /// Which color of the palette becomes the backdrop color.
  ///
  /// Changing only the strategy never triggers a new image decode.
  final BackdropStrategy strategy;

  /// Which part of the image is sampled. Defaults to [BackdropRegion.whole].
  final BackdropRegion region;

  /// How many colors the palette is reduced to (1–64, default 8).
  ///
  /// More colors give finer choices for [BackdropStrategy.vibrant],
  /// [BackdropStrategy.muted] and gradients, but slightly slower extraction.
  final int colorCount;

  /// The image is scaled down so that its longest side is at most this many
  /// pixels before sampling (default 96). Smaller is faster, larger is more
  /// precise for tiny details.
  final int maxDimension;

  /// Pixels with an alpha value below this (0–255, default 16) are ignored,
  /// so transparent PNG backgrounds do not influence the result.
  final int alphaThreshold;

  /// Skip near-white pixels (each channel at least 235). Useful for product
  /// photos on white studio backgrounds.
  ///
  /// If that leaves no pixels at all, the filter is dropped automatically.
  final bool ignoreNearWhite;

  /// Skip near-black pixels (each channel at most 20). Useful for images
  /// with black bars or dark shadows.
  ///
  /// If that leaves no pixels at all, the filter is dropped automatically.
  final bool ignoreNearBlack;

  /// The color reported while an image is loading, when it fails to load,
  /// or when it contains no usable pixels.
  final Color fallbackColor;

  /// The subset of settings that influences the extracted palette.
  ///
  /// Options with an equal signature can share a cached palette, even when
  /// their [strategy] or [fallbackColor] differ.
  (BackdropRegion, int, int, int, bool, bool) get samplingSignature => (
        region,
        colorCount,
        maxDimension,
        alphaThreshold,
        ignoreNearWhite,
        ignoreNearBlack,
      );

  /// Returns a copy with the given fields replaced.
  BackdropOptions copyWith({
    BackdropStrategy? strategy,
    BackdropRegion? region,
    int? colorCount,
    int? maxDimension,
    int? alphaThreshold,
    bool? ignoreNearWhite,
    bool? ignoreNearBlack,
    Color? fallbackColor,
  }) {
    return BackdropOptions(
      strategy: strategy ?? this.strategy,
      region: region ?? this.region,
      colorCount: colorCount ?? this.colorCount,
      maxDimension: maxDimension ?? this.maxDimension,
      alphaThreshold: alphaThreshold ?? this.alphaThreshold,
      ignoreNearWhite: ignoreNearWhite ?? this.ignoreNearWhite,
      ignoreNearBlack: ignoreNearBlack ?? this.ignoreNearBlack,
      fallbackColor: fallbackColor ?? this.fallbackColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackdropOptions &&
      other.strategy == strategy &&
      other.samplingSignature == samplingSignature &&
      other.fallbackColor == fallbackColor;

  @override
  int get hashCode => Object.hash(strategy, samplingSignature, fallbackColor);

  @override
  String toString() => 'BackdropOptions(strategy: $strategy, region: $region, '
      'colorCount: $colorCount, maxDimension: $maxDimension, '
      'alphaThreshold: $alphaThreshold, ignoreNearWhite: $ignoreNearWhite, '
      'ignoreNearBlack: $ignoreNearBlack, fallbackColor: $fallbackColor)';
}
