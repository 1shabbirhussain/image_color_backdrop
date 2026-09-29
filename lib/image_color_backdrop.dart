/// Picks the most prominent color of an image, icon or logo and turns it into
/// a ready-to-use background color.
///
/// Start with one of these:
///
/// * [ImageBackdrop] — a container whose background is picked from an image.
/// * [BackdropColorBuilder] — hands the picked color to any widget you build.
/// * [ImageColorBackdrop] — plain `Future` API without any widget.
/// * [BackdropController] — a `ChangeNotifier` to share the color across
///   widgets or re-style it live.
///
/// Use [BackdropStyle] to control opacity, brightness, saturation, blending
/// and contrast, and [BackdropOptions] to choose the color strategy and the
/// sampled image region.
library;

export 'src/backdrop_cache.dart' show BackdropCache;
export 'src/backdrop_color_builder.dart'
    show BackdropColorBuilder, BackdropWidgetBuilder;
export 'src/backdrop_controller.dart' show BackdropController;
export 'src/backdrop_options.dart' show BackdropOptions, BackdropStrategy;
export 'src/backdrop_palette.dart' show BackdropPalette;
export 'src/backdrop_region.dart' show BackdropRegion;
export 'src/backdrop_result.dart' show BackdropResult;
export 'src/backdrop_style.dart' show BackdropStyle;
export 'src/color_quantizer.dart' show ColorQuantizer;
export 'src/color_utils.dart' show BackdropColorUtils;
export 'src/image_backdrop.dart' show BackdropGradientMode, ImageBackdrop;
export 'src/image_color_backdrop.dart'
    show ImageColorBackdrop, ImageProviderBackdropExtension;
export 'src/palette_swatch.dart' show PaletteSwatch;
