import 'package:flutter/material.dart';

import 'backdrop_color_builder.dart';
import 'backdrop_options.dart';
import 'backdrop_result.dart';
import 'backdrop_style.dart';

/// How [ImageBackdrop] fills its background.
enum BackdropGradientMode {
  /// A flat color (default).
  none,

  /// A subtle gradient from a slightly lighter to a slightly darker shade of
  /// the picked color.
  tonal,

  /// A gradient from the picked color to the second most prominent color of
  /// the image.
  palette,
}

/// A container whose background color is picked from an image.
///
/// The quickest way to use it is [ImageBackdrop.image], which shows the image
/// and colors the space around it:
///
/// ```dart
/// ImageBackdrop.image(
///   image: const AssetImage('assets/logo.png'),
///   width: 120,
///   height: 120,
///   borderRadius: BorderRadius.circular(24),
/// );
/// ```
///
/// Use the default constructor to put *any* child on the picked color,
/// for example a title next to a cover picture:
///
/// ```dart
/// ImageBackdrop(
///   image: cover,
///   style: BackdropStyle.pastel,
///   child: ListTile(title: Text('Album')),
/// );
/// ```
///
/// Text and icons inside [child] automatically switch between light and dark
/// so they stay readable ([adaptForeground]). The color fades smoothly
/// whenever it changes ([duration]).
class ImageBackdrop extends StatelessWidget {
  /// Puts [child] on a background picked from [image].
  const ImageBackdrop({
    required this.image,
    this.child,
    this.options = const BackdropOptions(),
    this.style = BackdropStyle.original,
    this.gradientMode = BackdropGradientMode.none,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.adaptForeground = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.onChanged,
    this.onError,
    super.key,
  });

  /// Shows [image] on the color picked from it.
  ///
  /// The image is laid out with [fit] inside [padding] (16 logical pixels on
  /// all sides by default) and centered in the backdrop.
  ImageBackdrop.image({
    required this.image,
    BoxFit fit = BoxFit.contain,
    double? imageWidth,
    double? imageHeight,
    this.options = const BackdropOptions(),
    this.style = BackdropStyle.original,
    this.gradientMode = BackdropGradientMode.none,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.adaptForeground = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.onChanged,
    this.onError,
    super.key,
  }) : child = Image(
         image: image,
         fit: fit,
         width: imageWidth,
         height: imageHeight,
       );

  /// The image the color is picked from.
  final ImageProvider image;

  /// The widget drawn on the backdrop.
  final Widget? child;

  /// Sampling options and color selection strategy.
  final BackdropOptions options;

  /// How the picked color is turned into the final color.
  final BackdropStyle style;

  /// Whether to draw a flat color or a gradient.
  final BackdropGradientMode gradientMode;

  /// Where the gradient starts (ignored for [BackdropGradientMode.none]).
  final AlignmentGeometry gradientBegin;

  /// Where the gradient ends (ignored for [BackdropGradientMode.none]).
  final AlignmentGeometry gradientEnd;

  /// Fixed width of the container, or `null` to size to the child.
  final double? width;

  /// Fixed height of the container, or `null` to size to the child.
  final double? height;

  /// Space between the backdrop edge and [child].
  final EdgeInsetsGeometry? padding;

  /// Space around the backdrop.
  final EdgeInsetsGeometry? margin;

  /// How [child] is aligned inside the backdrop.
  final AlignmentGeometry? alignment;

  /// Rounded corners of the backdrop.
  final BorderRadiusGeometry? borderRadius;

  /// An optional border drawn around the backdrop.
  final BoxBorder? border;

  /// Optional shadows drawn behind the backdrop.
  final List<BoxShadow>? boxShadow;

  /// How [child] is clipped to the rounded corners. Defaults to
  /// [Clip.antiAlias].
  final Clip clipBehavior;

  /// When `true` (default), text and icons inside [child] use a color that is
  /// readable on the picked background.
  final bool adaptForeground;

  /// How long the color takes to change. Use [Duration.zero] to disable the
  /// animation.
  final Duration duration;

  /// The easing curve of the color change.
  final Curve curve;

  /// Called every time a new image has been analyzed successfully.
  final ValueChanged<BackdropResult>? onChanged;

  /// Called when the image cannot be loaded.
  final void Function(Object error, StackTrace stackTrace)? onError;

  List<Color>? _gradientColors(BackdropResult result) {
    switch (gradientMode) {
      case BackdropGradientMode.none:
        return null;
      case BackdropGradientMode.tonal:
        return result.tonalGradient();
      case BackdropGradientMode.palette:
        return result.paletteGradient();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropColorBuilder(
      image: image,
      options: options,
      style: style,
      onChanged: onChanged,
      onError: onError,
      builder: (context, result) {
        final colors = _gradientColors(result);
        final surface = Theme.of(context).colorScheme.surface;
        final foreground = result.onColorFor(surface);

        var content = child;
        if (content != null && adaptForeground) {
          content = DefaultTextStyle.merge(
            style: TextStyle(color: foreground),
            child: IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: content,
            ),
          );
        }

        return AnimatedContainer(
          duration: duration,
          curve: curve,
          width: width,
          height: height,
          margin: margin,
          padding: padding,
          alignment: alignment,
          clipBehavior: clipBehavior,
          decoration: BoxDecoration(
            color: colors == null ? result.color : null,
            gradient: colors == null
                ? null
                : LinearGradient(
                    begin: gradientBegin,
                    end: gradientEnd,
                    colors: colors,
                  ),
            borderRadius: borderRadius,
            border: border,
            boxShadow: boxShadow,
          ),
          child: content,
        );
      },
    );
  }
}
