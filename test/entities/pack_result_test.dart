import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/frame_placement.dart';
import 'package:spritesheet/domain/entities/pack_result.dart';

void main() {
  group('PackResult', () {
    test('creates with placements', () {
      final r = PackResult(
        placements: [
          FramePlacement(
            frameId: 'f1', frameName: 'a.png', x: 0, y: 0,
            width: 100, height: 100, sourceWidth: 100, sourceHeight: 100,
          ),
        ],
        canvasWidth: 512,
        canvasHeight: 512,
      );
      expect(r.placements.length, 1);
      expect(r.canvasWidth, 512);
      expect(r.canvasHeight, 512);
      expect(r.pageIndex, 0);
      expect(r.overflowFrameIds, isEmpty);
    });

    test('efficiency calculates correctly', () {
      final r = PackResult(
        placements: [
          FramePlacement(
            frameId: 'f1', frameName: 'a.png', x: 0, y: 0,
            width: 50, height: 50, sourceWidth: 50, sourceHeight: 50,
          ),
          FramePlacement(
            frameId: 'f2', frameName: 'b.png', x: 50, y: 0,
            width: 50, height: 50, sourceWidth: 50, sourceHeight: 50,
          ),
        ],
        canvasWidth: 100,
        canvasHeight: 100,
      );
      // 2 * (50*50) / (100*100) = 5000/10000 = 0.5
      expect(r.efficiency, closeTo(0.5, 0.001));
    });

    test('efficiency is 0.0 for zero-area canvas', () {
      final r = PackResult(
        placements: [],
        canvasWidth: 0,
        canvasHeight: 0,
      );
      expect(r.efficiency, 0.0);
    });

    test('hasOverflow is true when overflow list is non-empty', () {
      final r = PackResult(
        placements: [],
        canvasWidth: 64,
        canvasHeight: 64,
        overflowFrameIds: ['big_frame'],
      );
      expect(r.hasOverflow, isTrue);
    });

    test('hasOverflow is false when overflow list is empty', () {
      final r = PackResult(
        placements: [],
        canvasWidth: 64,
        canvasHeight: 64,
      );
      expect(r.hasOverflow, isFalse);
    });

    test('equality works', () {
      final a = PackResult(
        placements: [], canvasWidth: 64, canvasHeight: 64,
      );
      final b = PackResult(
        placements: [], canvasWidth: 64, canvasHeight: 64,
      );
      final c = PackResult(
        placements: [], canvasWidth: 128, canvasHeight: 128,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
