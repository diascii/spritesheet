import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/frame_placement.dart';

void main() {
  group('FramePlacement', () {
    test('creates with required fields', () {
      final p = FramePlacement(
        frameId: 'f1',
        frameName: 'hero_run_01.png',
        x: 10,
        y: 20,
        width: 120,
        height: 150,
        sourceWidth: 200,
        sourceHeight: 200,
      );
      expect(p.frameId, 'f1');
      expect(p.frameName, 'hero_run_01.png');
      expect(p.x, 10);
      expect(p.y, 20);
      expect(p.trimmed, false);
      expect(p.spriteSourceX, 0);
      expect(p.spriteSourceY, 0);
    });

    test('creates trimmed placement', () {
      final p = FramePlacement(
        frameId: 'f1',
        frameName: 'trimmed.png',
        x: 0,
        y: 0,
        width: 80,
        height: 100,
        trimmed: true,
        sourceWidth: 200,
        sourceHeight: 200,
        spriteSourceX: 40,
        spriteSourceY: 25,
      );
      expect(p.trimmed, isTrue);
      expect(p.spriteSourceX, 40);
      expect(p.spriteSourceY, 25);
    });

    test('equality works', () {
      final a = FramePlacement(
        frameId: 'f1', frameName: 'a.png', x: 0, y: 0, width: 10, height: 10,
        sourceWidth: 10, sourceHeight: 10,
      );
      final b = FramePlacement(
        frameId: 'f1', frameName: 'a.png', x: 0, y: 0, width: 10, height: 10,
        sourceWidth: 10, sourceHeight: 10,
      );
      final c = FramePlacement(
        frameId: 'f2', frameName: 'b.png', x: 0, y: 0, width: 10, height: 10,
        sourceWidth: 10, sourceHeight: 10,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString is informative', () {
      final p = FramePlacement(
        frameId: 'f1', frameName: 'a.png', x: 5, y: 10, width: 20, height: 30,
        sourceWidth: 20, sourceHeight: 30,
      );
      expect(p.toString(), contains('a.png'));
      expect(p.toString(), contains('5'));
    });
  });
}
