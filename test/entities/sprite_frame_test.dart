import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/int_rect.dart';
import 'package:spritesheet/domain/entities/sprite_frame.dart';

Uint8List _makeRgba(int w, int h, {int r = 255, int g = 0, int b = 0, int a = 255}) {
  final bytes = Uint8List(w * h * 4);
  for (var i = 0; i < bytes.length; i += 4) {
    bytes[i] = r;
    bytes[i + 1] = g;
    bytes[i + 2] = b;
    bytes[i + 3] = a;
  }
  return bytes;
}

void main() {
  group('SpriteFrame', () {
    test('creates with required fields', () {
      final bytes = _makeRgba(64, 64);
      final f = SpriteFrame(
        id: 'abc-123',
        name: 'hero.png',
        width: 64,
        height: 64,
        imageBytes: bytes,
        hash: 'deadbeef',
      );
      expect(f.id, 'abc-123');
      expect(f.name, 'hero.png');
      expect(f.width, 64);
      expect(f.height, 64);
      expect(f.sourceWidth, 64);
      expect(f.sourceHeight, 64);
      expect(f.order, 0);
    });

    test('effectiveWidth returns trimRect width when set', () {
      final f = SpriteFrame(
        id: '1', name: 't.png', width: 200, height: 200,
        imageBytes: _makeRgba(200, 200),
        hash: 'h',
        trimRect: IntRect(x: 10, y: 10, width: 80, height: 90),
      );
      expect(f.effectiveWidth, 80);
      expect(f.effectiveHeight, 90);
      expect(f.isTrimmed, isTrue);
    });

    test('effectiveWidth returns source width when not trimmed', () {
      final f = SpriteFrame(
        id: '1', name: 'u.png', width: 200, height: 200,
        imageBytes: _makeRgba(200, 200),
        hash: 'h',
      );
      expect(f.effectiveWidth, 200);
      expect(f.effectiveHeight, 200);
      expect(f.isTrimmed, isFalse);
    });

    test('copyWith replaces fields', () {
      final bytes = _makeRgba(64, 64);
      final a = SpriteFrame(
        id: '1', name: 'a.png', width: 64, height: 64,
        imageBytes: bytes, hash: 'h1',
      );
      final b = a.copyWith(name: 'b.png', order: 5);
      expect(b.name, 'b.png');
      expect(b.order, 5);
      expect(b.id, '1');
    });

    test('copyWith clears trimRect', () {
      final a = SpriteFrame(
        id: '1', name: 't.png', width: 100, height: 100,
        imageBytes: _makeRgba(100, 100),
        hash: 'h',
        trimRect: IntRect(x: 5, y: 5, width: 50, height: 50),
      );
      expect(a.isTrimmed, isTrue);
      final b = a.copyWith(clearTrimRect: true);
      expect(b.isTrimmed, isFalse);
      expect(b.trimRect, isNull);
    });

    test('equality excludes imageBytes and trimRect', () {
      final a = SpriteFrame(
        id: '1', name: 'a.png', width: 64, height: 64,
        imageBytes: _makeRgba(64, 64), hash: 'h1',
      );
      final b = SpriteFrame(
        id: '1', name: 'a.png', width: 64, height: 64,
        imageBytes: _makeRgba(64, 64, r: 0), hash: 'h1',
      );
      expect(a, equals(b));
    });

    test('inequality when id differs', () {
      final a = SpriteFrame(
        id: '1', name: 'a.png', width: 64, height: 64,
        imageBytes: _makeRgba(64, 64), hash: 'h1',
      );
      final b = SpriteFrame(
        id: '2', name: 'a.png', width: 64, height: 64,
        imageBytes: _makeRgba(64, 64), hash: 'h1',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
