import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show HSLColor;

import 'color_utils.dart';

/// A recipe that turns the picked image color into the final background
/// color: how transparent, how light or dark, how saturated, how much of
/// another color to mix in, and whether a minimum contrast must be kept.
///
/// Every property has a neutral default, so `const BackdropStyle()` returns
/// the picked color unchanged. The steps are applied in this order:
/// [saturation], [brightness], [blendColor], [ensureContrastWith], [opacity].
///
/// ```dart
/// const style = BackdropStyle(opacity: 0.2, saturation: -0.2);
/// final background = style.apply(pickedColor);
/// ```
@immutable
class BackdropStyle {
  /// Creates a style. See the individual fields for their ranges.
  const BackdropStyle({
    this.opacity = 1.0,
    this.brightness = 0.0,
    this.saturation = 0.0,
    this.blendColor,
    this.blendAmount = 0.0,
    this.ensureContrastWith,
    this.minContrastRatio = 3.0,
  }) : assert(opacity >= 0 && opacity <= 1, 'opacity must be in [0, 1]'),
       assert(
         brightness >= -1 && brightness <= 1,
         'brightness must be in [-1, 1]',
       ),
       assert(
         saturation >= -1 && saturation <= 1,
         'saturation must be in [-1, 1]',
       ),
       assert(
         blendAmount >= 0 && blendAmount <= 1,
         'blendAmount must be in [0, 1]',
       ),
       assert(
         minContrastRatio >= 1 && minContrastRatio <= 21,
         'minContrastRatio must be in [1, 21]',
       );

  /// The picked color, unchanged.
  static const BackdropStyle original = BackdropStyle();

  /// A see-through tint (18% opacity) that keeps the hue but stays calm.
  static const BackdropStyle soft = BackdropStyle(opacity: 0.18);

  /// A light, pastel version of the color.
  static const BackdropStyle pastel = BackdropStyle(
    brightness: 0.7,
    saturation: -0.1,
  );

  /// A darker, richer version of the color.
  static const BackdropStyle deep = BackdropStyle(brightness: -0.35);

  /// A desaturated, slightly lightened version of the color.
  static const BackdropStyle subdued = BackdropStyle(
    saturation: -0.5,
    brightness: 0.15,
  );

  /// Multiplies the color's alpha. `1.0` is opaque (default), `0.0` is fully
  /// transparent.
  final double opacity;

  /// Lightens (positive) or darkens (negative) the color, from `-1.0`
  /// (black) through `0.0` (unchanged) to `1.0` (white).
  final double brightness;

  /// Boosts (positive) or reduces (negative) color intensity, from `-1.0`
  /// (gray) through `0.0` (unchanged) to `1.0` (fully saturated).
  final double saturation;

  /// A color to mix into the picked one, for example the page's surface
  /// color to soften a strong background. Ignored when `null`.
  final Color? blendColor;

  /// How much of [blendColor] is mixed in, from `0.0` (none) to `1.0`
  /// (replaces the picked color).
  final double blendAmount;

  /// When set, the color is lightened or darkened as far as needed so that it
  /// keeps at least [minContrastRatio] against this color.
  ///
  /// Typical use: keep a white logo visible by passing `Colors.white`.
  final Color? ensureContrastWith;

  /// The contrast ratio (1–21, WCAG) enforced against [ensureContrastWith].
  /// `3.0` is the WCAG minimum for graphical objects; `4.5` is the minimum
  /// for normal text.
  final double minContrastRatio;

  /// Applies this style to [base] and returns the resulting color.
  Color apply(Color base) {
    var color = base;

    if (saturation != 0) {
      final hsl = HSLColor.fromColor(color);
      final s = saturation > 0
          ? hsl.saturation + (1 - hsl.saturation) * saturation
          : hsl.saturation * (1 + saturation);
      color = hsl.withSaturation(s.clamp(0.0, 1.0).toDouble()).toColor();
    }

    if (brightness > 0) {
      color = BackdropColorUtils.lighten(color, brightness);
    } else if (brightness < 0) {
      color = BackdropColorUtils.darken(color, -brightness);
    }

    final blend = blendColor;
    if (blend != null && blendAmount > 0) {
      color = Color.lerp(color, blend, blendAmount)!;
    }

    final against = ensureContrastWith;
    if (against != null) {
      color = BackdropColorUtils.ensureContrast(
        color,
        against,
        minRatio: minContrastRatio,
      );
    }

    if (opacity < 1) {
      color = color.withValues(alpha: color.a * opacity);
    }
    return color;
  }

  /// Returns a copy with the given fields replaced.
  ///
  /// To clear [blendColor] or [ensureContrastWith] create a new
  /// [BackdropStyle] instead.
  BackdropStyle copyWith({
    double? opacity,
    double? brightness,
    double? saturation,
    Color? blendColor,
    double? blendAmount,
    Color? ensureContrastWith,
    double? minContrastRatio,
  }) {
    return BackdropStyle(
      opacity: opacity ?? this.opacity,
      brightness: brightness ?? this.brightness,
      saturation: saturation ?? this.saturation,
      blendColor: blendColor ?? this.blendColor,
      blendAmount: blendAmount ?? this.blendAmount,
      ensureContrastWith: ensureContrastWith ?? this.ensureContrastWith,
      minContrastRatio: minContrastRatio ?? this.minContrastRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackdropStyle &&
      other.opacity == opacity &&
      other.brightness == brightness &&
      other.saturation == saturation &&
      other.blendColor == blendColor &&
      other.blendAmount == blendAmount &&
      other.ensureContrastWith == ensureContrastWith &&
      other.minContrastRatio == minContrastRatio;

  @override
  int get hashCode => Object.hash(
    opacity,
    brightness,
    saturation,
    blendColor,
    blendAmount,
    ensureContrastWith,
    minContrastRatio,
  );

  @override
  String toString() =>
      'BackdropStyle(opacity: $opacity, '
      'brightness: $brightness, saturation: $saturation, '
      'blendColor: $blendColor, blendAmount: $blendAmount, '
      'ensureContrastWith: $ensureContrastWith, '
      'minContrastRatio: $minContrastRatio)';
}
