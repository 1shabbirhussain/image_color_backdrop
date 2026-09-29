import 'package:flutter/foundation.dart';

/// The part of an image that is sampled when looking for a backdrop color.
///
/// Coordinates are normalized: `0.0` is the left/top edge and `1.0` is the
/// right/bottom edge, so a region works for any image size.
///
/// ```dart
/// // Match the color that surrounds a logo instead of the logo itself.
/// const BackdropOptions(region: BackdropRegion.edges);
/// ```
@immutable
class BackdropRegion {
  const BackdropRegion._(
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.borderThickness,
  );

  /// A custom rectangular region.
  ///
  /// All values are normalized to the `0.0`–`1.0` range. [right] must be
  /// greater than [left] and [bottom] must be greater than [top].
  const BackdropRegion.rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  })  : borderThickness = 0,
        assert(left >= 0 && left < right, 'left must be in [0, right)'),
        assert(top >= 0 && top < bottom, 'top must be in [0, bottom)'),
        assert(right <= 1, 'right must be at most 1'),
        assert(bottom <= 1, 'bottom must be at most 1');

  /// A frame around the image border, [thickness] wide on every side.
  ///
  /// [thickness] is a fraction of the image size and must be in `(0, 0.5]`.
  /// This is the best region for logos and icons, because their background
  /// color is usually what touches the border.
  const BackdropRegion.border({double thickness = 0.12})
      : left = 0,
        top = 0,
        right = 1,
        bottom = 1,
        borderThickness = thickness,
        assert(
          thickness > 0 && thickness <= 0.5,
          'thickness must be in (0, 0.5]',
        );

  /// The whole image (default).
  static const BackdropRegion whole = BackdropRegion._(0, 0, 1, 1, 0);

  /// The central half of the image (25% margin on each side).
  static const BackdropRegion center =
      BackdropRegion._(0.25, 0.25, 0.75, 0.75, 0);

  /// A thin frame (12% of the image size) around the image border.
  static const BackdropRegion edges = BackdropRegion._(0, 0, 1, 1, 0.12);

  /// The top quarter of the image.
  static const BackdropRegion topQuarter = BackdropRegion._(0, 0, 1, 0.25, 0);

  /// The bottom quarter of the image.
  static const BackdropRegion bottomQuarter =
      BackdropRegion._(0, 0.75, 1, 1, 0);

  /// The left quarter of the image.
  static const BackdropRegion leftQuarter = BackdropRegion._(0, 0, 0.25, 1, 0);

  /// The right quarter of the image.
  static const BackdropRegion rightQuarter =
      BackdropRegion._(0.75, 0, 1, 1, 0);

  /// Left edge of the sampled rectangle (normalized).
  final double left;

  /// Top edge of the sampled rectangle (normalized).
  final double top;

  /// Right edge of the sampled rectangle (normalized).
  final double right;

  /// Bottom edge of the sampled rectangle (normalized).
  final double bottom;

  /// When greater than zero only a frame of this thickness (normalized to the
  /// image size) is sampled.
  final double borderThickness;

  /// Whether this region covers every pixel of the image.
  bool get isWhole =>
      left == 0 &&
      top == 0 &&
      right == 1 &&
      bottom == 1 &&
      borderThickness == 0;

  /// Whether the normalized point ([nx], [ny]) lies inside the region.
  bool contains(double nx, double ny) {
    if (nx < left || nx >= right || ny < top || ny >= bottom) {
      return false;
    }
    if (borderThickness > 0) {
      final inner = 1 - borderThickness;
      return nx < borderThickness ||
          nx >= inner ||
          ny < borderThickness ||
          ny >= inner;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is BackdropRegion &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.borderThickness == borderThickness;

  @override
  int get hashCode => Object.hash(left, top, right, bottom, borderThickness);

  @override
  String toString() =>
      'BackdropRegion(left: $left, top: $top, right: $right, bottom: $bottom, '
      'borderThickness: $borderThickness)';
}
