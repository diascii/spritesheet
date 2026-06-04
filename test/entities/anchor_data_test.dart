import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/anchor_data.dart';

void main() {
  group('AnchorData', () {
    test('creates with valid coordinates', () {
      final a = AnchorData(x: 0.5, y: 1.0);
      expect(a.x, 0.5);
      expect(a.y, 1.0);
    });

    group('isValid', () {
      test('returns true for valid anchor', () {
        expect(AnchorData(x: 0.5, y: 1.0).isValid, isTrue);
        expect(AnchorData(x: 0.0, y: 0.0).isValid, isTrue);
        expect(AnchorData(x: 1.0, y: 1.0).isValid, isTrue);
      });

      test('returns false when x out of range', () {
        expect(AnchorData(x: -0.1, y: 0.5).isValid, isFalse);
        expect(AnchorData(x: 1.1, y: 0.5).isValid, isFalse);
      });

      test('returns false when y out of range', () {
        expect(AnchorData(x: 0.5, y: -0.1).isValid, isFalse);
        expect(AnchorData(x: 0.5, y: 1.1).isValid, isFalse);
      });
    });

    test('copyWith replaces fields', () {
      final a = AnchorData(x: 0.5, y: 1.0);
      final b = a.copyWith(x: 0.3);
      expect(b.x, 0.3);
      expect(b.y, 1.0);
    });

    test('toJson serializes correctly', () {
      final a = AnchorData(x: 0.5, y: 1.0);
      final json = a.toJson();
      expect(json['x'], 0.5);
      expect(json['y'], 1.0);
    });

    test('equality works', () {
      expect(AnchorData(x: 0.5, y: 1.0), equals(AnchorData(x: 0.5, y: 1.0)));
      expect(AnchorData(x: 0.5, y: 1.0), isNot(equals(AnchorData(x: 0.3, y: 1.0))));
    });
  });
}
