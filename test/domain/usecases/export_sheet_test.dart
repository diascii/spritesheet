import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spritesheet/domain/entities/anchor_data.dart';
import 'package:spritesheet/domain/entities/frame_annotation.dart';
import 'package:spritesheet/domain/entities/frame_placement.dart';
import 'package:spritesheet/domain/entities/hitbox_data.dart';
import 'package:spritesheet/domain/entities/pack_result.dart';
import 'package:spritesheet/domain/entities/sheet_config.dart';
import 'package:spritesheet/domain/repositories/image_repository.dart';
import 'package:spritesheet/domain/usecases/export_sheet.dart';

class MockImageRepository extends Mock implements ImageRepository {}

void main() {
  late ExportSheet exportSheet;
  late MockImageRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockRepo = MockImageRepository();
    exportSheet = ExportSheet(repository: mockRepo);

    when(() => mockRepo.exportSheet(any(), any())).thenAnswer((_) async {});
    when(() => mockRepo.exportJson(any(), any())).thenAnswer((_) async {});
  });

  group('ExportSheet', () {
    test('writes PNG and JSON files', () async {
      final result = await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'hero.png',
              x: 0,
              y: 0,
              width: 64,
              height: 64,
              sourceWidth: 64,
              sourceHeight: 64,
            ),
          ],
          canvasWidth: 64,
          canvasHeight: 64,
        ),
        pngBytes: Uint8List.fromList([137, 80, 78, 71]),
        config: const SheetConfig(sheetName: 'spritesheet'),
        annotations: [],
        frames: [],
        outputDirectory: '/tmp/output',
      );

      expect(result.pngPath, '/tmp/output/spritesheet.png');
      expect(result.jsonPath, '/tmp/output/spritesheet.json');
      verify(() => mockRepo.exportSheet(any(), '/tmp/output/spritesheet.png')).called(1);
      verify(() => mockRepo.exportJson(any(), '/tmp/output/spritesheet.json')).called(1);
    });

    test('JSON contains correct meta block', () async {
      Map<String, dynamic>? capturedJson;

      when(() => mockRepo.exportJson(any(), any())).thenAnswer((inv) async {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
      });

      await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'a.png',
              x: 0,
              y: 0,
              width: 64,
              height: 64,
              sourceWidth: 64,
              sourceHeight: 64,
            ),
          ],
          canvasWidth: 256,
          canvasHeight: 512,
        ),
        pngBytes: Uint8List(0),
        config: const SheetConfig(sheetName: 'hero_out'),
        annotations: [],
        frames: [],
        outputDirectory: '/out',
      );

      final meta = capturedJson!['meta'] as Map<String, dynamic>;
      expect(meta['app'], 'SpriteSheet Packer Mobile');
      expect(meta['version'], '1.0.0');
      expect(meta['image'], 'hero_out.png');
      expect(meta['format'], 'RGBA8888');
      expect(meta['size'], {'w': 256, 'h': 512});
      expect(meta['targetEngine'], 'flame');
    });

    test('JSON contains frame data', () async {
      Map<String, dynamic>? capturedJson;

      when(() => mockRepo.exportJson(any(), any())).thenAnswer((inv) async {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
      });

      await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'run_01.png',
              x: 10,
              y: 20,
              width: 120,
              height: 150,
              trimmed: true,
              sourceWidth: 200,
              sourceHeight: 200,
              spriteSourceX: 40,
              spriteSourceY: 25,
            ),
          ],
          canvasWidth: 512,
          canvasHeight: 512,
        ),
        pngBytes: Uint8List(0),
        config: const SheetConfig(),
        annotations: [],
        frames: [],
        outputDirectory: '/out',
      );

      final frames = capturedJson!['frames'] as Map<String, dynamic>;
      final frame = frames['run_01.png'] as Map<String, dynamic>;

      expect(frame['frame'], {'x': 10, 'y': 20, 'w': 120, 'h': 150});
      expect(frame['trimmed'], isTrue);
      expect(frame['sourceSize'], {'w': 200, 'h': 200});
      expect(frame['spriteSourceSize'], {'x': 40, 'y': 25, 'w': 120, 'h': 150});
    });

    test('JSON includes anchor and hitboxes when annotated', () async {
      Map<String, dynamic>? capturedJson;

      when(() => mockRepo.exportJson(any(), any())).thenAnswer((inv) async {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
      });

      await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'hero.png',
              x: 0,
              y: 0,
              width: 64,
              height: 64,
              sourceWidth: 64,
              sourceHeight: 64,
            ),
          ],
          canvasWidth: 64,
          canvasHeight: 64,
        ),
        pngBytes: Uint8List(0),
        config: const SheetConfig(),
        annotations: [
          FrameAnnotation(
            frameId: 'f1',
            anchor: AnchorData(x: 0.5, y: 1.0),
            hitboxes: [
              HitboxData(
                id: 'hb1',
                type: HitboxType.body,
                x: 0.1,
                y: 0.2,
                w: 0.5,
                h: 0.6,
              ),
            ],
          ),
        ],
        frames: const [],
        outputDirectory: '/out',
      );

      final frames = capturedJson!['frames'] as Map<String, dynamic>;
      final frame = frames['hero.png'] as Map<String, dynamic>;

      expect(frame['anchor'], {'x': 0.5, 'y': 1.0});
      expect(frame['hitboxes'], isA<List>());
      expect((frame['hitboxes'] as List).length, 1);
    });

    test('JSON omits anchor when not annotated', () async {
      Map<String, dynamic>? capturedJson;

      when(() => mockRepo.exportJson(any(), any())).thenAnswer((inv) async {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
      });

      await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'hero.png',
              x: 0,
              y: 0,
              width: 64,
              height: 64,
              sourceWidth: 64,
              sourceHeight: 64,
            ),
          ],
          canvasWidth: 64,
          canvasHeight: 64,
        ),
        pngBytes: Uint8List(0),
        config: const SheetConfig(),
        annotations: [],
        frames: [],
        outputDirectory: '/out',
      );

      final frames = capturedJson!['frames'] as Map<String, dynamic>;
      final frame = frames['hero.png'] as Map<String, dynamic>;

      expect(frame.containsKey('anchor'), isFalse);
      expect(frame.containsKey('hitboxes'), isFalse);
    });

    test('JSON output is valid and parseable', () async {
      Map<String, dynamic>? capturedJson;

      when(() => mockRepo.exportJson(any(), any())).thenAnswer((inv) async {
        capturedJson = inv.positionalArguments[0] as Map<String, dynamic>;
      });

      await exportSheet.execute(
        packResult: PackResult(
          placements: [
            FramePlacement(
              frameId: 'f1',
              frameName: 'a.png',
              x: 0,
              y: 0,
              width: 32,
              height: 32,
              sourceWidth: 32,
              sourceHeight: 32,
            ),
          ],
          canvasWidth: 32,
          canvasHeight: 32,
        ),
        pngBytes: Uint8List(0),
        config: const SheetConfig(),
        annotations: [],
        frames: const [],
        outputDirectory: '/out',
      );

      final jsonString = jsonEncode(capturedJson);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['meta'], isNotNull);
      expect(decoded['frames'], isNotNull);
    });
  });
}
