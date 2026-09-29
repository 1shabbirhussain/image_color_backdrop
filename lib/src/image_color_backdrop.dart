import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'backdrop_cache.dart';
import 'backdrop_options.dart';
import 'backdrop_palette.dart';
import 'backdrop_result.dart';
import 'backdrop_style.dart';
import 'color_quantizer.dart';

/// The entry point for extracting colors from images without any widget.
///
/// ```dart
/// // The color to use behind an image:
/// final color = await ImageColorBackdrop.colorFromImageProvider(
///   const AssetImage('assets/logo.png'),
/// );
///
/// // The full palette:
/// final palette = await ImageColorBackdrop.paletteFromImageProvider(
///   NetworkImage('https://example.com/photo.jpg'),
/// );
/// print(palette.vibrant);
/// ```
///
/// All methods are asynchronous because images must be decoded first. Results
/// are cached in memory (see [cache]).
abstract final class ImageColorBackdrop {
  /// The shared cache of extracted palettes.
  static final BackdropCache cache = BackdropCache();

  static final Map<Object, Future<BackdropPalette>> _pending =
      <Object, Future<BackdropPalette>>{};

  /// Extracts the [BackdropPalette] of an [ImageProvider] (asset, network,
  /// file, memory, ...).
  ///
  /// The image is decoded at a reduced size ([BackdropOptions.maxDimension]),
  /// so this is cheap even for large photos. Set [useCache] to `false` to
  /// bypass the cache, [timeout] to stop waiting for slow images, and
  /// [configuration] when the provider depends on it (for example
  /// resolution-aware assets).
  ///
  /// Throws if the image cannot be loaded or decoded.
  static Future<BackdropPalette> paletteFromImageProvider(
    ImageProvider provider, {
    BackdropOptions options = const BackdropOptions(),
    ImageConfiguration configuration = ImageConfiguration.empty,
    bool useCache = true,
    Duration? timeout,
  }) async {
    if (!useCache || cache.maximumSize <= 0) {
      return _extractFromProvider(provider, options, configuration, timeout);
    }

    Object imageKey;
    try {
      imageKey = await provider.obtainKey(configuration);
    } catch (_) {
      imageKey = provider;
    }
    final key = (imageKey, options.samplingSignature);

    final cached = cache.get(key);
    if (cached != null) {
      return cached;
    }
    final pending = _pending[key];
    if (pending != null) {
      return pending;
    }

    final future = _extractFromProvider(
      provider,
      options,
      configuration,
      timeout,
    );
    _pending[key] = future;
    try {
      final palette = await future;
      cache.put(key, palette);
      return palette;
    } finally {
      _pending.remove(key);
    }
  }

  /// Extracts the [BackdropPalette] of an already decoded [image].
  ///
  /// The image is scaled down first when it is larger than
  /// [BackdropOptions.maxDimension]. The caller keeps ownership of [image]
  /// and is responsible for disposing it.
  static Future<BackdropPalette> paletteFromImage(
    ui.Image image, {
    BackdropOptions options = const BackdropOptions(),
  }) async {
    final longest = math.max(image.width, image.height);
    if (longest <= options.maxDimension) {
      return _paletteFromDecoded(image, options);
    }

    final scale = options.maxDimension / longest;
    final targetWidth = math.max(1, (image.width * scale).round());
    final targetHeight = math.max(1, (image.height * scale).round());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final small = await picture.toImage(targetWidth, targetHeight);
    picture.dispose();
    try {
      return await _paletteFromDecoded(small, options);
    } finally {
      small.dispose();
    }
  }

  /// Extracts the [BackdropPalette] of encoded image [bytes] (PNG, JPEG,
  /// WebP, GIF, ...).
  static Future<BackdropPalette> paletteFromBytes(
    Uint8List bytes, {
    BackdropOptions options = const BackdropOptions(),
    bool useCache = false,
    Duration? timeout,
  }) {
    return paletteFromImageProvider(
      MemoryImage(bytes),
      options: options,
      useCache: useCache,
      timeout: timeout,
    );
  }

  /// Extracts a [BackdropPalette] synchronously from raw, straight
  /// (non-premultiplied) RGBA pixels.
  ///
  /// Useful when you already hold decoded pixels, for example in an isolate
  /// or a custom image pipeline.
  static BackdropPalette paletteFromRgba(
    Uint8List rgba, {
    required int width,
    required int height,
    BackdropOptions options = const BackdropOptions(),
  }) {
    return BackdropPalette(
      ColorQuantizer.quantize(
        rgba,
        width: width,
        height: height,
        colorCount: options.colorCount,
        alphaThreshold: options.alphaThreshold,
        ignoreNearWhite: options.ignoreNearWhite,
        ignoreNearBlack: options.ignoreNearBlack,
        region: options.region,
      ),
    );
  }

  /// Extracts a [BackdropResult] (palette, picked color, styled color) from
  /// an [ImageProvider].
  ///
  /// Never throws for an empty image: the result is then a fallback result.
  /// Loading errors are still thrown.
  static Future<BackdropResult> resultFromImageProvider(
    ImageProvider provider, {
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
    ImageConfiguration configuration = ImageConfiguration.empty,
    bool useCache = true,
    Duration? timeout,
  }) async {
    final palette = await paletteFromImageProvider(
      provider,
      options: options,
      configuration: configuration,
      useCache: useCache,
      timeout: timeout,
    );
    return BackdropResult.fromPalette(palette, options: options, style: style);
  }

  /// The final, styled backdrop color for an [ImageProvider].
  ///
  /// This is the shortest way to get "a good background color for this
  /// image". Returns [BackdropOptions.fallbackColor] (styled) for an image
  /// without usable pixels.
  static Future<ui.Color> colorFromImageProvider(
    ImageProvider provider, {
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
    ImageConfiguration configuration = ImageConfiguration.empty,
    bool useCache = true,
    Duration? timeout,
  }) async {
    final result = await resultFromImageProvider(
      provider,
      options: options,
      style: style,
      configuration: configuration,
      useCache: useCache,
      timeout: timeout,
    );
    return result.color;
  }

  static Future<BackdropPalette> _extractFromProvider(
    ImageProvider provider,
    BackdropOptions options,
    ImageConfiguration configuration,
    Duration? timeout,
  ) async {
    final resized = ResizeImage(
      provider,
      width: options.maxDimension,
      height: options.maxDimension,
      policy: ResizeImagePolicy.fit,
      allowUpscaling: false,
    );
    final image = await _resolve(resized, configuration, timeout);
    try {
      return await _paletteFromDecoded(image, options);
    } finally {
      image.dispose();
    }
  }

  static Future<ui.Image> _resolve(
    ImageProvider provider,
    ImageConfiguration configuration,
    Duration? timeout,
  ) async {
    final stream = provider.resolve(configuration);
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (completer.isCompleted) {
          return;
        }
        completer.complete(info.image.clone());
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    try {
      final future = completer.future;
      return timeout == null ? await future : await future.timeout(timeout);
    } finally {
      stream.removeListener(listener);
    }
  }

  static Future<BackdropPalette> _paletteFromDecoded(
    ui.Image image,
    BackdropOptions options,
  ) async {
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data == null) {
      throw StateError('Could not read the pixels of the image.');
    }
    final rgba = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return paletteFromRgba(
      rgba,
      width: image.width,
      height: image.height,
      options: options,
    );
  }
}

/// Convenience methods on every [ImageProvider].
///
/// ```dart
/// final color = await const AssetImage('assets/logo.png').backdropColor();
/// ```
extension ImageProviderBackdropExtension on ImageProvider {
  /// Shorthand for [ImageColorBackdrop.paletteFromImageProvider].
  Future<BackdropPalette> backdropPalette({
    BackdropOptions options = const BackdropOptions(),
    ImageConfiguration configuration = ImageConfiguration.empty,
    bool useCache = true,
    Duration? timeout,
  }) {
    return ImageColorBackdrop.paletteFromImageProvider(
      this,
      options: options,
      configuration: configuration,
      useCache: useCache,
      timeout: timeout,
    );
  }

  /// Shorthand for [ImageColorBackdrop.colorFromImageProvider]: the final,
  /// styled backdrop color of this image.
  Future<ui.Color> backdropColor({
    BackdropOptions options = const BackdropOptions(),
    BackdropStyle style = BackdropStyle.original,
    ImageConfiguration configuration = ImageConfiguration.empty,
    bool useCache = true,
    Duration? timeout,
  }) {
    return ImageColorBackdrop.colorFromImageProvider(
      this,
      options: options,
      style: style,
      configuration: configuration,
      useCache: useCache,
      timeout: timeout,
    );
  }
}
