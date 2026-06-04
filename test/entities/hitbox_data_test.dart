import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/hitbox_data.dart';

void main() {
  group('HitboxData', () {
    test('creates with valid coordinates', () {
      final h = HitboxData(
        id: 'h1',
        type: HitboxType.body,
        x: 0.1,
        y: 0.2,
        w: 0.5,
        h: 0.6,
      );
      expect(h.id, 'h1');
      expect(h.type, HitboxType.body);
      expect(h.x, 0.1);
      expect(h.y, 0.2);
      expect(h.w, 0.5);
      expect(h.h, 0.6);
    });

    group('isValid', () {
      test('returns true for valid hitbox', () {
        final h = HitboxData(
          id: 'h1',
          type: HitboxType.body,
          x: 0.1,
          y: 0.2,
          w: 0.5,
          h: 0.6,
        );
        expect(h.isValid, isTrue);
      });

      test('returns false when x out of range', () {
        final h = HitboxData(
          id: 'h1', type: HitboxType.body, x: -0.1, y: 0, w: 0.5, h: 0.5,
        );
        expect(h.isValid, isFalse);
      });

      test('returns false when x + w exceeds 1.0', () {
        final h = HitboxData(
          id: 'h1', type: HitboxType.body, x: 0.6, y: 0, w: 0.5, h: 0.5,
        );
        expect(h.isValid, isFalse);
      });

      test('returns false when y + h exceeds 1.0', () {
        final h = HitboxData(
          id: 'h1', type: HitboxType.body, x: 0, y: 0.6, w: 0.5, h: 0.5,
        );
        expect(h.isValid, isFalse);
      });

      test('returns true for zero-size hitbox at origin', () {
        final h = HitboxData(
          id: 'h1', type: HitboxType.body, x: 0, y: 0, w: 0, h: 0,
        );
        expect(h.isValid, isTrue);
      });
    });

    test('copyWith replaces fields', () {
      final a = HitboxData(
        id: 'h1', type: HitboxType.body, x: 0.1, y: 0.2, w: 0.5, h: 0.6,
      );
      final b = a.copyWith(type: HitboxType.attack, x: 0.3);
      expect(b.type, HitboxType.attack);
      expect(b.x, 0.3);
      expect(b.y, 0.2);
      expect(b.id, 'h1');
    });

    test('toJson serializes correctly', () {
      final h = HitboxData(
        id: 'h1', type: HitboxType.attack, x: 0.25, y: 0.5, w: 0.3, h: 0.4,
      );
      final json = h.toJson();
      expect(json['id'], 'h1');
      expect(json['type'], 'attack');
      expect(json['x'], 0.25);
      expect(json['y'], 0.5);
      expect(json['w'], 0.3);
      expect(json['h'], 0.4);
    });

    test('toString is informative', () {
      final h = HitboxData(
        id: 'h1', type: HitboxType.body, x: 0.1, y: 0.2, w: 0.5, h: 0.6,
      );
      expect(h.toString(), contains('body'));
    });
  });

  group('HitboxType', () {
    test('has three values', () {
      expect(HitboxType.values.length, 3);
      expect(HitboxType.values, containsAll([HitboxType.body, HitboxType.attack, HitboxType.hurt]));
    });

    test('names are lowercase', () {
      for (final t in HitboxType.values) {
        expect(t.name, equals(t.name.toLowerCase()));
      }
    });
  });
}
