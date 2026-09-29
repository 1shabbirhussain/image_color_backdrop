import 'dart:math' as math;
import 'dart:ui' show Color;

import 'backdrop_options.dart';
import 'color_utils.dart';
import 'palette_swatch.dart';

/// The set of representative colors extracted from an image.
///
/// A palette is immutable. Use [colorFor] / [swatchFor] to pick a color with
/// a [BackdropStrategy], or use the convenience getters such as [dominant]
/// and [vibrant].
class BackdropPalette {
  /// Creates a palette from [swatches]. They are sorted by population.
  BackdropPalette(Iterable<PaletteSwatch> swatches)
      : swatches = List<PaletteSwatch>.unmodifiable(
          (List<PaletteSwatch>.of(swatches))
            ..sort((a, b) => b.population.compareTo(a.population)),
        );

  /// A palette without any color, for example for a fully transparent image.
  static final BackdropPalette empty = BackdropPalette(const <PaletteSwatch>[]);

  /// All swatches, largest first.
  final List<PaletteSwatch> swatches;

  /// Whether the palette contains no colors.
  bool get isEmpty => swatches.isEmpty;

  /// Whether the palette contains at least one color.
  bool get isNotEmpty => swatches.isNotEmpty;

  /// The most common color, or `null` for an empty palette.
  Color? get dominant => swatchFor(BackdropStrategy.dominant)?.color;

  /// The most eye-catching color, or `null` for an empty palette.
  Color? get vibrant => swatchFor(BackdropStrategy.vibrant)?.color;

  /// A soft, less saturated color, or `null` for an empty palette.
  Color? get muted => swatchFor(BackdropStrategy.muted)?.color;

  /// The pixel-weighted average color, or `null` for an empty palette.
  Color? get average => swatchFor(BackdropStrategy.average)?.color;

  /// The lightest significant color, or `null` for an empty palette.
  Color? get lightest => swatchFor(BackdropStrategy.lightest)?.color;

  /// The darkest significant color, or `null` for an empty palette.
  Color? get darkest => swatchFor(BackdropStrategy.darkest)?.color;

  /// Picks the swatch that best fits [strategy], or `null` when empty.
  ///
  /// For [BackdropStrategy.average] a synthetic swatch is returned.
  PaletteSwatch? swatchFor(BackdropStrategy strategy) {
    if (swatches.isEmpty) {
      return null;
    }
    switch (strategy) {
      case BackdropStrategy.dominant:
        return swatches.first;
      case BackdropStrategy.vibrant:
        return _bestBy(
          (s, popRatio) =>
              0.5 * s.saturation + 0.3 * _midLightness(s) + 0.2 * popRatio,
        );
      case BackdropStrategy.muted:
        return _bestBy(
          (s, popRatio) =>
              0.5 * (1 - (s.saturation - 0.3).abs()) +
              0.3 * _midLightness(s) +
              0.2 * popRatio,
        );
      case BackdropStrategy.average:
        return _averageSwatch();
      case BackdropStrategy.lightest:
        return _significant().reduce((a, b) => b.lightness > a.lightness ? b : a);
      case BackdropStrategy.darkest:
        return _significant().reduce((a, b) => b.lightness < a.lightness ? b : a);
    }
  }

  /// Picks the color that best fits [strategy], or `null` when empty.
  Color? colorFor(BackdropStrategy strategy) => swatchFor(strategy)?.color;

  /// The most populous swatch whose color differs noticeably from [color],
  /// or `null` when the palette has no such swatch.
  ///
  /// Used to build two-color gradients.
  PaletteSwatch? secondaryTo(Color color, {double minDistance = 0.12}) {
    for (final swatch in swatches) {
      if (BackdropColorUtils.distance(swatch.color, color) >= minDistance) {
        return swatch;
      }
    }
    return null;
  }

  /// Swatches that cover at least 2% of the image (or all of them when none
  /// does), so that a few stray pixels never win "lightest"/"darkest".
  List<PaletteSwatch> _significant() {
    final significant =
        swatches.where((s) => s.proportion >= 0.02).toList(growable: false);
    return significant.isEmpty ? swatches : significant;
  }

  double _midLightness(PaletteSwatch s) => 1 - ((s.lightness - 0.5).abs() * 2);

  PaletteSwatch _bestBy(double Function(PaletteSwatch, double) score) {
    final significant =
        swatches.where((s) => s.proportion >= 0.005).toList(growable: false);
    final candidates = significant.isEmpty ? swatches : significant;
    final maxPopulation = candidates.map((s) => s.population).reduce(math.max);
    var best = candidates.first;
    var bestScore = -double.infinity;
    for (final swatch in candidates) {
      final value = score(swatch, swatch.population / maxPopulation);
      if (value > bestScore) {
        bestScore = value;
        best = swatch;
      }
    }
    return best;
  }

  PaletteSwatch _averageSwatch() {
    var r = 0.0, g = 0.0, b = 0.0;
    var total = 0;
    for (final swatch in swatches) {
      r += BackdropColorUtils.red(swatch.color) * swatch.population;
      g += BackdropColorUtils.green(swatch.color) * swatch.population;
      b += BackdropColorUtils.blue(swatch.color) * swatch.population;
      total += swatch.population;
    }
    final n = total == 0 ? 1 : total;
    return PaletteSwatch(
      color: Color.fromARGB(
        255,
        (r / n).round().clamp(0, 255).toInt(),
        (g / n).round().clamp(0, 255).toInt(),
        (b / n).round().clamp(0, 255).toInt(),
      ),
      population: total,
      proportion: 1,
    );
  }

  @override
  String toString() => 'BackdropPalette(${swatches.length} swatches: '
      '${swatches.map((s) => s.color).join(', ')})';
}
