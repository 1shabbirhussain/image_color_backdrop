import 'dart:collection';

import 'backdrop_palette.dart';

/// A small in-memory least-recently-used cache of extracted palettes.
///
/// It is used automatically by [ImageColorBackdrop] and the widgets so that
/// scrolling a list of images back and forth does not repeat the work.
/// Access the shared instance with `ImageColorBackdrop.cache`.
class BackdropCache {
  /// Creates a cache that keeps at most [maximumSize] palettes.
  BackdropCache({this.maximumSize = 128})
    : assert(maximumSize >= 0, 'maximumSize must not be negative');

  final LinkedHashMap<Object, BackdropPalette> _entries =
      LinkedHashMap<Object, BackdropPalette>();

  /// The maximum number of palettes kept. Set to `0` to disable caching.
  ///
  /// Lowering the value evicts the least recently used entries immediately.
  int maximumSize;

  /// How many palettes are currently cached.
  int get length => _entries.length;

  /// Returns the cached palette for [key] and marks it as recently used.
  BackdropPalette? get(Object key) {
    final value = _entries.remove(key);
    if (value != null) {
      _entries[key] = value;
    }
    return value;
  }

  /// Stores [palette] under [key], evicting old entries when needed.
  void put(Object key, BackdropPalette palette) {
    if (maximumSize <= 0) {
      return;
    }
    _entries.remove(key);
    _entries[key] = palette;
    while (_entries.length > maximumSize) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes the palette stored under [key]. Returns whether one existed.
  bool remove(Object key) => _entries.remove(key) != null;

  /// Removes every cached palette.
  void clear() => _entries.clear();
}
