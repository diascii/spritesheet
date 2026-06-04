import 'package:flutter/foundation.dart';

import '../entities/int_rect.dart';
import '../entities/sprite_frame.dart';

class TrimAlpha {
  /// Trims transparent pixels and returns a copy of the frame.
  Future<SpriteFrame> call(SpriteFrame frame) async {
    return compute(_trimFrameIsolate, frame);
  }
}

SpriteFrame _trimFrameIsolate(SpriteFrame frame) {
  final bytes = frame.imageBytes;
  final w = frame.width;
  final h = frame.height;

  int top;
  for (top = 0; top < h; top++) {
    if (_rowHasAlpha(bytes, w, top)) break;
  }

  if (top == h) {
    return frame.copyWith(clearTrimRect: true);
  }

  int bottom;
  for (bottom = h - 1; bottom >= top; bottom--) {
    if (_rowHasAlpha(bytes, w, bottom)) break;
  }

  int left;
  for (left = 0; left < w; left++) {
    if (_colHasAlpha(bytes, w, h, left, top, bottom)) break;
  }

  int right;
  for (right = w - 1; right >= left; right--) {
    if (_colHasAlpha(bytes, w, h, right, top, bottom)) break;
  }

  final trimW = right - left + 1;
  final trimH = bottom - top + 1;

  if (left == 0 && top == 0 && trimW == w && trimH == h) {
    return frame.copyWith(clearTrimRect: true);
  }

  return frame.copyWith(
    trimRect: IntRect(x: left, y: top, width: trimW, height: trimH),
  );
}

bool _rowHasAlpha(Uint8List bytes, int stride, int y) {
  final rowStart = y * stride * 4;
  for (var x = 0; x < stride; x++) {
    if (bytes[rowStart + x * 4 + 3] > 0) return true;
  }
  return false;
}

bool _colHasAlpha(
  Uint8List bytes,
  int stride,
  int height,
  int x,
  int top,
  int bottom,
) {
  for (var y = top; y <= bottom; y++) {
    if (bytes[(y * stride + x) * 4 + 3] > 0) return true;
  }
  return false;
}
