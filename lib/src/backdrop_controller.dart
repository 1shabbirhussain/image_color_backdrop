import 'package:flutter/widgets.dart';

import 'backdrop_options.dart';
import 'backdrop_palette.dart';
import 'backdrop_result.dart';
import 'backdrop_style.dart';
import 'image_color_backdrop.dart';

/// A [ChangeNotifier] that loads an image, exposes its backdrop color and
/// lets you re-style it live.
///
/// It is the tool of choice when the color is needed *somewhere else* than
/// right next to the image, for example to tint an app bar or a whole page
/// while a photo is shown elsewhere, or when the color must be shared by
/// several widgets.
///
/// ```dart
/// final controller = BackdropController(
///   style: const BackdropStyle(opacity: 0.8),
/// )..load(const AssetImage('assets/cover.jpg'));
///
/// ListenableBuilder(
///   listenable: controller,
///   builder: (context, _) => Container(color: controller.color),
/// );
/// ```
///
/// Remember to call [dispose] when the controller is no longer needed.
class BackdropController extends ChangeNotifier {
  /// Creates a controller. When [image] is given it is loaded immediately.
  BackdropController({
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
    ImageProvider? image,
  }) : _options = options,
       _style = style {
    if (image != null) {
      load(image);
    }
  }

  BackdropOptions _options;
  BackdropStyle _style;
  ImageProvider? _image;
  BackdropPalette? _palette;
  Object? _error;
  bool _isLoading = false;
  bool _disposed = false;
  int _token = 0;

  /// The current sampling options.
  BackdropOptions get options => _options;

  /// The current style.
  BackdropStyle get style => _style;

  /// The image that is (being) shown, if any.
  ImageProvider? get image => _image;

  /// Whether an image is currently being analyzed.
  bool get isLoading => _isLoading;

  /// The error of the last failed load, or `null`.
  Object? get error => _error;

  /// The current result. It is a fallback result until the first image has
  /// been analyzed, and after a failed load.
  BackdropResult get result {
    final palette = _palette;
    if (palette == null) {
      return BackdropResult.fallback(options: _options, style: _style);
    }
    return BackdropResult.fromPalette(
      palette,
      options: _options,
      style: _style,
    );
  }

  /// The final, styled backdrop color.
  Color get color => result.color;

  /// A readable foreground color for [color], assuming a white surface.
  Color get onColor => result.onColor;

  /// The extracted palette, or [BackdropPalette.empty] when nothing has been
  /// analyzed yet.
  BackdropPalette get palette => _palette ?? BackdropPalette.empty;

  /// Loads and analyzes [image]. Older, still running loads are ignored.
  ///
  /// Errors are stored in [error] instead of being thrown.
  Future<void> load(
    ImageProvider image, {
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) async {
    _image = image;
    final token = ++_token;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final palette = await ImageColorBackdrop.paletteFromImageProvider(
        image,
        options: _options,
        configuration: configuration,
      );
      if (_disposed || token != _token) {
        return;
      }
      _palette = palette;
    } catch (e) {
      if (_disposed || token != _token) {
        return;
      }
      _palette = null;
      _error = e;
    }
    _isLoading = false;
    _notify();
  }

  /// Changes the [style]. Listeners are notified; the image is not analyzed
  /// again.
  set style(BackdropStyle value) {
    if (value == _style) {
      return;
    }
    _style = value;
    _notify();
  }

  /// Changes the [options]. When sampling-related settings changed, the
  /// current image is analyzed again; a changed strategy applies instantly.
  set options(BackdropOptions value) {
    if (value == _options) {
      return;
    }
    final resample = value.samplingSignature != _options.samplingSignature;
    _options = value;
    final current = _image;
    if (resample && current != null) {
      load(current);
    } else {
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
