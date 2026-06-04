import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/anchor_data.dart';
import 'package:spritesheet/domain/entities/frame_annotation.dart';
import 'package:spritesheet/domain/entities/hitbox_data.dart';

void main() {
  group('FrameAnnotation', () {
    test('creates with frameId only', () {
      final a = FrameAnnotation(frameId: 'f1');
      expect(a.frameId, 'f1');
      expect(a.anchor, isNull);
      expect(a.hitboxes, isEmpty);
      expect(a.hasData, isFalse);
    });

    test('creates with anchor and hitboxes', () {
      final a = FrameAnnotation(
        frameId: 'f1',
        anchor: AnchorData(x: 0.5, y: 1.0),
        hitboxes: [
          HitboxData(
            id: 'h1', type: HitboxType.body, x: 0.1, y: 0.2, w: 0.5, h: 0.6,
          ),
        ],
      );
      expect(a.anchor, isNotNull);
      expect(a.anchor!.x, 0.5);
      expect(a.hitboxes.length, 1);
      expect(a.hasData, isTrue);
    });

    test('hasData is true with anchor only', () {
      final a = FrameAnnotation(
        frameId: 'f1',
        anchor: AnchorData(x: 0.5, y: 1.0),
      );
      expect(a.hasData, isTrue);
    });

    test('hasData is true with hitboxes only', () {
      final a = FrameAnnotation(
        frameId: 'f1',
        hitboxes: [
          HitboxData(
            id: 'h1', type: HitboxType.body, x: 0.1, y: 0.2, w: 0.5, h: 0.6,
          ),
        ],
      );
      expect(a.hasData, isTrue);
    });

    test('copyWith clears anchor', () {
      final a = FrameAnnotation(
        frameId: 'f1',
        anchor: AnchorData(x: 0.5, y: 1.0),
      );
      final b = a.copyWith(clearAnchor: true);
      expect(b.anchor, isNull);
    });

    test('copyWith replaces hitboxes', () {
      final a = FrameAnnotation(
        frameId: 'f1',
        hitboxes: [
          HitboxData(
            id: 'h1', type: HitboxType.body, x: 0.1, y: 0.2, w: 0.5, h: 0.6,
          ),
        ],
      );
      final b = a.copyWith(hitboxes: []);
      expect(b.hitboxes, isEmpty);
    });

    test('equality works', () {
      final a = FrameAnnotation(frameId: 'f1');
      final b = FrameAnnotation(frameId: 'f1');
      final c = FrameAnnotation(frameId: 'f2');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
