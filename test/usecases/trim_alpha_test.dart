import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/sprite_frame.dart';
import 'package:spritesheet/domain/usecases/trim_alpha.dart';

Uint8List _makeRgba(int w, int h, {bool opaque = false}) {
  final bytes = Uint8List(w * h * 4);
  if (opaque) {
    for (var i = 0; i < bytes.length; i += 4) {
      bytes[i] = 255;
      bytes[i + 1] = 0;
      bytes[i + 2] = 128;
      bytes[i + 3] = 255;
    }
  }
  return bytes;
}

Uint8List _makeRgbaWithRect(int w, int h, int rx, int ry, int rw, int rh) {
  final bytes = Uint8List(w * h * 4);
  for (var y = ry; y < ry + rh && y < h; y++) {
    for (var x = rx; x < rx + rw && x < w; x++) {
      final i = (y * w + x) * 4;
      bytes[i] = 255;
      bytes[i + 1] = 0;
      bytes[i + 2] = 128;
      bytes[i + 3] = 255;
    }
  }
  return bytes;
}

void main() {
  late TrimAlpha trimAlpha;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    trimAlpha = TrimAlpha();
  });

  group('TrimAlpha', () {
    test('returns clearTrimRect for fully opaque frame', () async {
      final frame = SpriteFrame(
        id: 'f1',
        name: 'opaque.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgba(100, 100, opaque: true),
        hash: 'h1',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isFalse);
      expect(result.trimRect, isNull);
    });

    test('returns clearTrimRect for fully transparent frame', () async {
      final frame = SpriteFrame(
        id: 'f2',
        name: 'empty.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgba(100, 100),
        hash: 'h2',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isFalse);
      expect(result.trimRect, isNull);
    });

    test('detects trim rect for centered opaque region', () async {
      final frame = SpriteFrame(
        id: 'f3',
        name: 'centered.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgbaWithRect(100, 100, 25, 25, 50, 50),
        hash: 'h3',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isTrue);
      expect(result.trimRect!.x, 25);
      expect(result.trimRect!.y, 25);
      expect(result.trimRect!.width, 50);
      expect(result.trimRect!.height, 50);
    });

    test('trims from top edge', () async {
      final frame = SpriteFrame(
        id: 'f4',
        name: 'top_trim.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgbaWithRect(100, 100, 0, 30, 100, 10),
        hash: 'h4',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isTrue);
      expect(result.trimRect!.y, 30);
      expect(result.trimRect!.height, 10);
    });

    test('trims single pixel at corner', () async {
      final frame = SpriteFrame(
        id: 'f5',
        name: 'single_pixel.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgbaWithRect(100, 100, 99, 99, 1, 1),
        hash: 'h5',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isTrue);
      expect(result.trimRect!.x, 99);
      expect(result.trimRect!.y, 99);
      expect(result.trimRect!.width, 1);
      expect(result.trimRect!.height, 1);
    });

    test('trims single row strip', () async {
      final frame = SpriteFrame(
        id: 'f6',
        name: 'row.png',
        width: 100,
        height: 100,
        imageBytes: _makeRgbaWithRect(100, 100, 10, 50, 80, 1),
        hash: 'h6',
      );

      final result = await trimAlpha(frame);
      expect(result.isTrimmed, isTrue);
      expect(result.trimRect!.y, 50);
      expect(result.trimRect!.height, 1);
    });
  });
}
