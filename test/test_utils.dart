import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_color_backdrop/image_color_backdrop.dart';

/// Builds straight RGBA pixels, asking [painter] for the color of each pixel.
Uint8List buildRgba(
  int width,
  int height,
  ui.Color Function(int x, int y) painter,
) {
  final bytes = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final color = painter(x, y);
      final i = (y * width + x) * 4;
      bytes[i] = BackdropColorUtils.red(color);
      bytes[i + 1] = BackdropColorUtils.green(color);
      bytes[i + 2] = BackdropColorUtils.blue(color);
      bytes[i + 3] = BackdropColorUtils.alpha(color);
    }
  }
  return bytes;
}

/// Encodes a solid-color PNG. Must run inside `tester.runAsync`.
Future<Uint8List> solidPng(ui.Color color, {int size = 16}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}
