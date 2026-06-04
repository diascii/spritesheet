import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/algorithms/max_rects_bin_pack.dart';

void main() {
  group('MaxRectsBinPack', () {
    group('pack()', () {
      test('packs a single frame that fits exactly', () {
        final output = MaxRectsBinPack.pack(
          [const InputRect(id: 'a', width: 64, height: 64)],
          64,
          64,
        );

        expect(output.placed.length, 1);
        expect(output.failed, isEmpty);
        expect(output.placed[0].id, 'a');
        expect(output.placed[0].width, 64);
        expect(output.placed[0].height, 64);
        expect(output.placed[0].x, 0);
        expect(output.placed[0].y, 0);
        expect(output.canvasWidth, 64);
        expect(output.canvasHeight, 64);
      });

      test('returns failed when frame is larger than canvas', () {
        final output = MaxRectsBinPack.pack(
          [const InputRect(id: 'big', width: 128, height: 128)],
          64,
          64,
        );

        expect(output.placed, isEmpty);
        expect(output.failed, ['big']);
      });

      test('packs 100 frames of varying sizes', () {
        final rects = List.generate(
          100,
          (i) => InputRect(
            id: 'frame_$i',
            width: (i % 8 + 1) * 16,
            height: (i % 6 + 1) * 16,
          ),
        );

        final output = MaxRectsBinPack.pack(rects, 2048, 2048);

        expect(output.placed.length, greaterThan(90));
        expect(_noOverlaps(output.placed), isTrue);
      });

      test('handles extreme aspect ratios (1x200)', () {
        final output = MaxRectsBinPack.pack(
          [const InputRect(id: 'thin', width: 1, height: 200)],
          256,
          256,
        );

        expect(output.placed.length, 1);
        expect(output.failed, isEmpty);
      });

      test('handles extreme aspect ratios (200x1)', () {
        final output = MaxRectsBinPack.pack(
          [const InputRect(id: 'wide', width: 200, height: 1)],
          256,
          256,
        );

        expect(output.placed.length, 1);
        expect(output.failed, isEmpty);
      });

      test('fills canvas exactly with no overflow', () {
        final output = MaxRectsBinPack.pack(
          [const InputRect(id: 'a', width: 128, height: 128)],
          128,
          128,
        );

        expect(output.placed.length, 1);
        expect(output.failed, isEmpty);
        expect(output.canvasWidth, 128);
        expect(output.canvasHeight, 128);
      });

      test('packs multiple frames that exactly fill a row', () {
        final output = MaxRectsBinPack.pack(
          [
            const InputRect(id: 'a', width: 64, height: 64),
            const InputRect(id: 'b', width: 64, height: 64),
            const InputRect(id: 'c', width: 64, height: 64),
            const InputRect(id: 'd', width: 64, height: 64),
          ],
          256,
          64,
        );

        expect(output.placed.length, 4);
        expect(output.failed, isEmpty);
        // All should fit in a single row
        for (final p in output.placed) {
          expect(p.y, 0);
        }
      });

      test('no placed rect overlaps another', () {
        for (final heuristic in PackHeuristic.values) {
          final rects = List.generate(
            50,
            (i) => InputRect(
              id: 'r$i',
              width: (i % 5 + 1) * 32,
              height: (i % 4 + 1) * 32,
            ),
          );

          final output = MaxRectsBinPack.pack(
            rects,
            1024,
            1024,
            heuristic: heuristic,
          );

          expect(
            _noOverlaps(output.placed),
            isTrue,
            reason: 'Overlap detected with heuristic $heuristic',
          );
        }
      });

      test('all four heuristics produce valid placements', () {
        final rects = List.generate(
          30,
          (i) => InputRect(
            id: 'r$i',
            width: (i % 6 + 1) * 16,
            height: (i % 5 + 1) * 16,
          ),
        );

        for (final heuristic in PackHeuristic.values) {
          final output = MaxRectsBinPack.pack(
            rects,
            512,
            512,
            heuristic: heuristic,
          );

          expect(output.placed.length, greaterThan(0));
          expect(_noOverlaps(output.placed), isTrue);
        }
      });

      test('returns empty placed and failed for empty input', () {
        final output = MaxRectsBinPack.pack([], 256, 256);

        expect(output.placed, isEmpty);
        expect(output.failed, isEmpty);
        expect(output.canvasWidth, 0);
        expect(output.canvasHeight, 0);
      });

      test('handles many identical sized frames', () {
        final rects = List.generate(
          20,
          (i) => InputRect(id: 'sq$i', width: 64, height: 64),
        );

        final output = MaxRectsBinPack.pack(rects, 256, 256);

        // 256 / 64 = 4 per row, 4 rows = 16 fit, at most 4 overflow
        expect(output.placed.length, 16);
        expect(output.failed.length, 4);
      });
    });
  });
}

/// Returns true if no two placed rects overlap.
bool _noOverlaps(List<PlacedRect> rects) {
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      if (_overlaps(rects[i], rects[j])) return false;
    }
  }
  return true;
}

bool _overlaps(PlacedRect a, PlacedRect b) {
  return a.x < b.x + b.width &&
      a.x + a.width > b.x &&
      a.y < b.y + b.height &&
      a.y + a.height > b.y;
}
