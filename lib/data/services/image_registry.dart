import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Singleton cache that converts RGBA byte arrays → dart:ui.Image.
/// Keyed by frame ID. Both the editor widgets and Flame game read from this.
class ImageRegistry {
  static final ImageRegistry instance = ImageRegistry._();
  ImageRegistry._();

  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<ui.Image>> _pending = {};

  /// Returns a cached ui.Image for the given frameId.
  /// If not cached, decodes from [rgba] bytes and caches the result.
  Future<ui.Image> getImage(String frameId, Uint8List rgba, int width, int height) async {
    if (_cache.containsKey(frameId)) return _cache[frameId]!;
    if (_pending.containsKey(frameId)) return _pending[frameId]!;

    final completer = Completer<ui.Image>();
    _pending[frameId] = completer.future;

    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (image) {
      _cache[frameId] = image;
      _pending.remove(frameId);
      completer.complete(image);
    });

    return completer.future;
  }

  /// Call when a frame's pixels change (e.g., user edits it in PixelEditor).
  void invalidate(String frameId) {
    _cache.remove(frameId)?.dispose();
    _pending.remove(frameId);
  }

  /// Call on project clear/close.
  void clearAll() {
    for (final img in _cache.values) { img.dispose(); }
    _cache.clear();
    _pending.clear();
  }

  /// Check if an image is already cached (sync check, useful for Flame).
  ui.Image? getCached(String frameId) => _cache[frameId];
}
