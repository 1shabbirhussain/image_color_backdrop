import 'dart:typed_data';
import 'dart:ui' show Color;

import 'backdrop_region.dart';
import 'palette_swatch.dart';

const int _bitsPerChannel = 5;
const int _shift = 8 - _bitsPerChannel;
const int _binCount = 1 << (_bitsPerChannel * 3);
const int _nearWhite = 235;
const int _nearBlack = 20;

/// Reduces raw pixels to a small list of representative colors.
///
/// The implementation is a histogram based **median cut**: pixels are first
/// counted in a 32×32×32 color histogram, then the histogram is recursively
/// split along its longest color axis until the requested number of colors
/// is reached. The result is fast (a few milliseconds for a 96×96 sample),
/// deterministic and needs no native code, so it behaves identically on all
/// platforms.
///
/// This class works on plain bytes and does not need a Flutter binding, which
/// makes it easy to unit test.
abstract final class ColorQuantizer {
  /// Quantizes straight (non-premultiplied) RGBA [rgba] bytes.
  ///
  /// [rgba] must hold at least `width * height * 4` bytes. The returned
  /// swatches are sorted by [PaletteSwatch.population], largest first, and
  /// their proportions add up to `1.0`. An empty list is returned when no
  /// pixel qualifies.
  static List<PaletteSwatch> quantize(
    Uint8List rgba, {
    required int width,
    required int height,
    int colorCount = 8,
    int alphaThreshold = 16,
    bool ignoreNearWhite = false,
    bool ignoreNearBlack = false,
    BackdropRegion region = BackdropRegion.whole,
  }) {
    assert(width > 0 && height > 0, 'width and height must be positive');
    assert(
      rgba.length >= width * height * 4,
      'rgba must contain width * height * 4 bytes',
    );
    assert(colorCount >= 1, 'colorCount must be at least 1');

    final histogram = _collect(
      rgba,
      width: width,
      height: height,
      alphaThreshold: alphaThreshold,
      ignoreNearWhite: ignoreNearWhite,
      ignoreNearBlack: ignoreNearBlack,
      region: region,
    );

    if (histogram.total == 0 && (ignoreNearWhite || ignoreNearBlack)) {
      // The filters removed everything (for example an all-white image):
      // fall back to sampling without them.
      return quantize(
        rgba,
        width: width,
        height: height,
        colorCount: colorCount,
        alphaThreshold: alphaThreshold,
        region: region,
      );
    }
    if (histogram.total == 0) {
      return const <PaletteSwatch>[];
    }

    final occupied = <int>[];
    for (var bin = 0; bin < _binCount; bin++) {
      if (histogram.counts[bin] > 0) {
        occupied.add(bin);
      }
    }

    final boxes = <_Box>[_Box(occupied, histogram.counts)];
    while (boxes.length < colorCount) {
      final splitIndex = _pickBoxToSplit(boxes, colorCount);
      if (splitIndex < 0) {
        break;
      }
      final box = boxes.removeAt(splitIndex);
      final halves = box.split(histogram.counts);
      boxes
        ..add(halves.$1)
        ..add(halves.$2);
    }

    final swatches = <PaletteSwatch>[];
    for (final box in boxes) {
      swatches.add(box.toSwatch(histogram, histogram.total));
    }
    swatches.sort((a, b) => b.population.compareTo(a.population));
    return swatches;
  }

  static int _pickBoxToSplit(List<_Box> boxes, int colorCount) {
    // The first 75% of the splits are driven by population so that large
    // color areas are represented well; the rest also consider the size of
    // the color volume so that rare but distinct colors get a chance.
    final byPopulationOnly = boxes.length < (colorCount * 0.75).ceil();
    var bestIndex = -1;
    var bestScore = -1.0;
    for (var i = 0; i < boxes.length; i++) {
      final box = boxes[i];
      if (box.bins.length < 2) {
        continue;
      }
      final score = byPopulationOnly
          ? box.population.toDouble()
          : box.population.toDouble() * box.volume;
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  static _Histogram _collect(
    Uint8List rgba, {
    required int width,
    required int height,
    required int alphaThreshold,
    required bool ignoreNearWhite,
    required bool ignoreNearBlack,
    required BackdropRegion region,
  }) {
    final histogram = _Histogram();
    final counts = histogram.counts;
    final sumR = histogram.sumR;
    final sumG = histogram.sumG;
    final sumB = histogram.sumB;
    final wholeImage = region.isWhole;
    var total = 0;

    for (var y = 0; y < height; y++) {
      final ny = (y + 0.5) / height;
      for (var x = 0; x < width; x++) {
        if (!wholeImage && !region.contains((x + 0.5) / width, ny)) {
          continue;
        }
        final i = (y * width + x) * 4;
        if (rgba[i + 3] < alphaThreshold) {
          continue;
        }
        final r = rgba[i];
        final g = rgba[i + 1];
        final b = rgba[i + 2];
        if (ignoreNearWhite &&
            r >= _nearWhite &&
            g >= _nearWhite &&
            b >= _nearWhite) {
          continue;
        }
        if (ignoreNearBlack &&
            r <= _nearBlack &&
            g <= _nearBlack &&
            b <= _nearBlack) {
          continue;
        }
        final bin = ((r >> _shift) << (_bitsPerChannel * 2)) |
            ((g >> _shift) << _bitsPerChannel) |
            (b >> _shift);
        counts[bin]++;
        sumR[bin] += r;
        sumG[bin] += g;
        sumB[bin] += b;
        total++;
      }
    }
    histogram.total = total;
    return histogram;
  }
}

class _Histogram {
  final Int32List counts = Int32List(_binCount);
  final Float64List sumR = Float64List(_binCount);
  final Float64List sumG = Float64List(_binCount);
  final Float64List sumB = Float64List(_binCount);
  int total = 0;
}

int _rOf(int bin) => bin >> (_bitsPerChannel * 2);
int _gOf(int bin) => (bin >> _bitsPerChannel) & 0x1F;
int _bOf(int bin) => bin & 0x1F;

class _Box {
  factory _Box(List<int> bins, Int32List counts) {
    var minR = 31, maxR = 0, minG = 31, maxG = 0, minB = 31, maxB = 0;
    var population = 0;
    for (final bin in bins) {
      final r = _rOf(bin), g = _gOf(bin), b = _bOf(bin);
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (g < minG) minG = g;
      if (g > maxG) maxG = g;
      if (b < minB) minB = b;
      if (b > maxB) maxB = b;
      population += counts[bin];
    }
    return _Box._(bins, population, maxR - minR + 1, maxG - minG + 1,
        maxB - minB + 1);
  }

  _Box._(this.bins, this.population, this.rangeR, this.rangeG, this.rangeB);

  final List<int> bins;
  final int population;
  final int rangeR;
  final int rangeG;
  final int rangeB;

  int get volume => rangeR * rangeG * rangeB;

  (_Box, _Box) split(Int32List counts) {
    final int Function(int) axis;
    if (rangeR >= rangeG && rangeR >= rangeB) {
      axis = _rOf;
    } else if (rangeG >= rangeB) {
      axis = _gOf;
    } else {
      axis = _bOf;
    }

    final sorted = List<int>.of(bins)
      ..sort((a, b) => axis(a).compareTo(axis(b)));

    final half = population / 2;
    var running = 0;
    var cut = 1;
    for (var i = 0; i < sorted.length - 1; i++) {
      running += counts[sorted[i]];
      cut = i + 1;
      if (running >= half) {
        break;
      }
    }
    return (
      _Box(sorted.sublist(0, cut), counts),
      _Box(sorted.sublist(cut), counts),
    );
  }

  PaletteSwatch toSwatch(_Histogram histogram, int total) {
    var r = 0.0, g = 0.0, b = 0.0;
    for (final bin in bins) {
      r += histogram.sumR[bin];
      g += histogram.sumG[bin];
      b += histogram.sumB[bin];
    }
    final n = population == 0 ? 1 : population;
    return PaletteSwatch(
      color: Color.fromARGB(
        255,
        (r / n).round().clamp(0, 255).toInt(),
        (g / n).round().clamp(0, 255).toInt(),
        (b / n).round().clamp(0, 255).toInt(),
      ),
      population: population,
      proportion: population / total,
    );
  }
}
