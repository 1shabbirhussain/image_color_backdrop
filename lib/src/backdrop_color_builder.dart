import 'package:flutter/widgets.dart';

import 'backdrop_options.dart';
import 'backdrop_palette.dart';
import 'backdrop_result.dart';
import 'backdrop_style.dart';
import 'image_color_backdrop.dart';

/// Signature of the function that builds the widget tree of a
/// [BackdropColorBuilder] from the current [BackdropResult].
typedef BackdropWidgetBuilder = Widget Function(
  BuildContext context,
  BackdropResult result,
);

/// Analyzes an image and rebuilds with its backdrop color.
///
/// This is the most flexible widget of the package: it does not draw
/// anything itself, it just hands you the [BackdropResult] so you can paint
/// *anything* with the color: a `Container`, a `Card`, an `AppBar`, a
/// `BoxDecoration`, a text color, a gradient, ...
///
/// ```dart
/// BackdropColorBuilder(
///   image: const AssetImage('assets/logo.png'),
///   style: const BackdropStyle(opacity: 0.15),
///   builder: (context, result) {
///     return Container(
///       color: result.color,
///       child: Text('Hello', style: TextStyle(color: result.onColor)),
///     );
///   },
/// );
/// ```
///
/// Until the image has been analyzed, [BackdropResult.isFallback] is `true`
/// and the color is [BackdropOptions.fallbackColor]. When [image] changes,
/// the previous color stays visible until the new one is ready.
class BackdropColorBuilder extends StatefulWidget {
  /// Creates a builder that analyzes [image] and calls [builder].
  const BackdropColorBuilder({
    required this.image,
    required this.builder,
    this.options = const BackdropOptions(),
    this.style = BackdropStyle.original,
    this.onChanged,
    this.onError,
    super.key,
  });

  /// The image to analyze. Any [ImageProvider] works.
  final ImageProvider image;

  /// Builds the child from the current [BackdropResult].
  final BackdropWidgetBuilder builder;

  /// Sampling options and color selection strategy.
  final BackdropOptions options;

  /// How the picked color is turned into the final color.
  final BackdropStyle style;

  /// Called every time a new image has been analyzed successfully. Handy for
  /// handing the color to something outside of this widget's subtree.
  final ValueChanged<BackdropResult>? onChanged;

  /// Called when the image cannot be loaded. The builder keeps receiving a
  /// fallback result.
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<BackdropColorBuilder> createState() => _BackdropColorBuilderState();
}

class _BackdropColorBuilderState extends State<BackdropColorBuilder> {
  BackdropPalette? _palette;
  int _token = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(BackdropColorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final imageChanged = widget.image != oldWidget.image;
    final samplingChanged = widget.options.samplingSignature !=
        oldWidget.options.samplingSignature;
    if (imageChanged || samplingChanged) {
      _load();
    }
  }

  BackdropResult get _result {
    final palette = _palette;
    if (palette == null) {
      return BackdropResult.fallback(
        options: widget.options,
        style: widget.style,
      );
    }
    return BackdropResult.fromPalette(
      palette,
      options: widget.options,
      style: widget.style,
    );
  }

  Future<void> _load() async {
    final token = ++_token;
    final configuration = createLocalImageConfiguration(context);
    try {
      final palette = await ImageColorBackdrop.paletteFromImageProvider(
        widget.image,
        options: widget.options,
        configuration: configuration,
      );
      if (!mounted || token != _token) {
        return;
      }
      setState(() => _palette = palette);
      widget.onChanged?.call(_result);
    } catch (error, stackTrace) {
      if (!mounted || token != _token) {
        return;
      }
      setState(() => _palette = null);
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _result);
}
