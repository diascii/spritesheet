import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/data/sources/hash_util.dart';

void main() {
  group('HashUtil', () {
    test('returns consistent hash for same input', () {
      final util = HashUtil();
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

      final hash1 = util.hashBytes(bytes);
      final hash2 = util.hashBytes(bytes);

      expect(hash1, equals(hash2));
    });

    test('returns different hash for different input', () {
      final util = HashUtil();
      final a = util.hashBytes(Uint8List.fromList([1, 2, 3]));
      final b = util.hashBytes(Uint8List.fromList([4, 5, 6]));

      expect(a, isNot(equals(b)));
    });

    test('returns 64-character hex string', () {
      final util = HashUtil();
      final hash = util.hashBytes(Uint8List.fromList([0]));

      expect(hash.length, 64);
      expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('handles empty bytes', () {
      final util = HashUtil();
      final hash = util.hashBytes(Uint8List(0));

      expect(hash.length, 64);
    });
  });
}
