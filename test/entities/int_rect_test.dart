import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/int_rect.dart';

void main() {
  group('IntRect', () {
    test('creates with valid dimensions', () {
      final r = IntRect(x: 10, y: 20, width: 100, height: 200);
      expect(r.x, 10);
      expect(r.y, 20);
      expect(r.width, 100);
      expect(r.height, 200);
      expect(r.right, 110);
      expect(r.bottom, 220);
      expect(r.area, 20000);
    });

    test('asserts non-negative width', () {
      expect(
        () => IntRect(x: 0, y: 0, width: -1, height: 10),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts non-negative height', () {
      expect(
        () => IntRect(x: 0, y: 0, width: 10, height: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('overlaps returns true for intersecting rects', () {
      final a = IntRect(x: 0, y: 0, width: 100, height: 100);
      final b = IntRect(x: 50, y: 50, width: 100, height: 100);
      expect(a.overlaps(b), isTrue);
      expect(b.overlaps(a), isTrue);
    });

    test('overlaps returns false for separated rects', () {
      final a = IntRect(x: 0, y: 0, width: 50, height: 50);
      final b = IntRect(x: 100, y: 100, width: 50, height: 50);
      expect(a.overlaps(b), isFalse);
    });

    test('overlaps returns false for edge-adjacent rects', () {
      final a = IntRect(x: 0, y: 0, width: 50, height: 50);
      final b = IntRect(x: 50, y: 0, width: 50, height: 50);
      expect(a.overlaps(b), isFalse);
    });

    test('contains returns true for interior point', () {
      final r = IntRect(x: 10, y: 10, width: 100, height: 100);
      expect(r.contains(10, 10), isTrue);
      expect(r.contains(109, 109), isTrue);
      expect(r.contains(60, 60), isTrue);
    });

    test('contains returns false for exterior point', () {
      final r = IntRect(x: 10, y: 10, width: 100, height: 100);
      expect(r.contains(0, 0), isFalse);
      expect(r.contains(110, 110), isFalse);
      expect(r.contains(10, 110), isFalse);
      expect(r.contains(110, 10), isFalse);
    });

    test('equality works', () {
      final a = IntRect(x: 1, y: 2, width: 3, height: 4);
      final b = IntRect(x: 1, y: 2, width: 3, height: 4);
      final c = IntRect(x: 1, y: 2, width: 5, height: 4);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString is informative', () {
      final r = IntRect(x: 10, y: 20, width: 30, height: 40);
      expect(r.toString(), contains('10'));
      expect(r.toString(), contains('40'));
    });
  });
}
