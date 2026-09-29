import 'dart:math' as math;
import 'dart:ui' show Color;

/// Small, dependency-free color helpers used throughout `image_color_backdrop`.
///
/// They are public because they are handy when you build your own widgets on
/// top of a picked backdrop color (for example to choose a readable text
/// color).
abstract final class BackdropColorUtils {
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  /// The 8-bit (0–255) red channel of [color].
  static int red(Color color) => _to8(color.r);

  /// The 8-bit (0–255) green channel of [color].
  static int green(Color color) => _to8(color.g);

  /// The 8-bit (0–255) blue channel of [color].
  static int blue(Color color) => _to8(color.b);

  /// The 8-bit (0–255) alpha channel of [color].
  static int alpha(Color color) => _to8(color.a);

  static int _to8(double value) =>
      (value * 255.0).round().clamp(0, 255).toInt();

  static double _clamp01(double value) =>
      value < 0 ? 0 : (value > 1 ? 1 : value);

  /// The WCAG 2.x contrast ratio between [a] and [b], from `1.0` (identical)
  /// to `21.0` (black on white).
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns whichever of [light] or [dark] is easier to read on top of
  /// [background].
  ///
  /// A translucent [background] is first composited over [surface] (white by
  /// default), because that is what the user actually sees.
  static Color readableOn(
    Color background, {
    Color light = const Color(0xFFFFFFFF),
    Color dark = const Color(0xFF111111),
    Color surface = _white,
  }) {
    final visible = Color.alphaBlend(background, surface);
    final withLight = contrastRatio(visible, light);
    final withDark = contrastRatio(visible, dark);
    return withDark >= withLight ? dark : light;
  }

  /// Mixes [color] with white by [amount] (`0` = unchanged, `1` = white).
  static Color lighten(Color color, double amount) =>
      Color.lerp(color, _white, _clamp01(amount))!;

  /// Mixes [color] with black by [amount] (`0` = unchanged, `1` = black).
  static Color darken(Color color, double amount) =>
      Color.lerp(color, _black, _clamp01(amount))!;

  /// Moves [color] towards white or black, whichever moves it away from
  /// [against], until the contrast ratio between them reaches [minRatio].
  ///
  /// Returns [color] untouched when it already has enough contrast. If even
  /// pure white or black cannot reach [minRatio] the closest possible result
  /// is returned.
  static Color ensureContrast(
    Color color,
    Color against, {
    double minRatio = 3.0,
  }) {
    if (contrastRatio(color, against) >= minRatio) {
      return color;
    }
    final target = against.computeLuminance() < 0.5 ? _white : _black;
    var candidate = color;
    for (var step = 1; step <= 20; step++) {
      candidate = Color.lerp(color, target, step / 20)!;
      if (contrastRatio(candidate, against) >= minRatio) {
        return candidate;
      }
    }
    return candidate;
  }

  /// A normalized (`0`–`1`) euclidean distance between two colors in RGB
  /// space. `0` means identical, `1` means black versus white.
  static double distance(Color a, Color b) {
    final dr = (red(a) - red(b)).toDouble();
    final dg = (green(a) - green(b)).toDouble();
    final db = (blue(a) - blue(b)).toDouble();
    return math.sqrt(dr * dr + dg * dg + db * db) / 441.6729559300637;
  }
}
