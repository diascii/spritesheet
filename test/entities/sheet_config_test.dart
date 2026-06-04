import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/sheet_config.dart';

void main() {
  group('SheetConfig', () {
    test('creates with sensible defaults', () {
      final c = const SheetConfig();
      expect(c.sheetName, 'spritesheet');
      expect(c.maxTextureSize, 2048);
      expect(c.framePadding, 1);
      expect(c.trimEnabled, isTrue);
      expect(c.targetEngine, 'flame');
    });

    group('isValid', () {
      test('returns true for default config', () {
        expect(const SheetConfig().isValid, isTrue);
      });

      test('returns false for empty sheetName', () {
        expect(const SheetConfig(sheetName: '').isValid, isFalse);
      });

      test('returns true for maxTextureSize 2048', () {
        expect(const SheetConfig(maxTextureSize: 2048).isValid, isTrue);
      });

      test('returns true for maxTextureSize 4096', () {
        expect(const SheetConfig(maxTextureSize: 4096).isValid, isTrue);
      });

      test('returns false for invalid maxTextureSize', () {
        expect(const SheetConfig(maxTextureSize: 1024).isValid, isFalse);
        expect(const SheetConfig(maxTextureSize: 8192).isValid, isFalse);
      });

      test('returns false for negative framePadding', () {
        expect(const SheetConfig(framePadding: -1).isValid, isFalse);
      });

      test('returns false for framePadding > 16', () {
        expect(const SheetConfig(framePadding: 17).isValid, isFalse);
      });

      test('returns true for framePadding at bounds', () {
        expect(const SheetConfig(framePadding: 0).isValid, isTrue);
        expect(const SheetConfig(framePadding: 16).isValid, isTrue);
      });
    });

    test('copyWith replaces fields', () {
      final a = const SheetConfig();
      final b = a.copyWith(sheetName: 'custom', maxTextureSize: 4096);
      expect(b.sheetName, 'custom');
      expect(b.maxTextureSize, 4096);
      expect(b.framePadding, 1);
    });

    test('equality works', () {
      expect(
        const SheetConfig(),
        equals(const SheetConfig()),
      );
      expect(
        const SheetConfig(),
        isNot(equals(const SheetConfig(sheetName: 'other'))),
      );
    });

    test('toString is informative', () {
      final c = const SheetConfig();
      expect(c.toString(), contains('spritesheet'));
      expect(c.toString(), contains('2048'));
    });
  });
}
