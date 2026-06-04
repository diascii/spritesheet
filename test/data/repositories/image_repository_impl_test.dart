import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spritesheet/data/repositories/image_repository_impl.dart';
import 'package:spritesheet/data/sources/hash_util.dart';
import 'package:spritesheet/data/sources/image_decoder.dart';

class MockImageDecoder extends Mock implements ImageDecoder {}
class FakePlatformFile extends Fake implements PlatformFile {
  @override
  final String path;
  @override
  final String name;
  FakePlatformFile(this.path, this.name);
}

void main() {
  late Directory tempDir;
  late MockImageDecoder mockDecoder;
  late HashUtil hashUtil;
  late ImageRepositoryImpl repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(FakePlatformFile('', ''));
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('spritesheet_test_');
    mockDecoder = MockImageDecoder();
    hashUtil = HashUtil();
    repository = ImageRepositoryImpl(
      imageDecoder: mockDecoder,
      hashUtil: hashUtil,
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ImageRepositoryImpl', () {
    test('importFrames returns decoded frames', () async {
      final rgbaA = Uint8List(16 * 16 * 4);
      for (var i = 0; i < rgbaA.length; i += 4) {
        rgbaA[i] = 255;
        rgbaA[i + 3] = 255;
      }
      final rgbaB = Uint8List(32 * 32 * 4);
      for (var i = 0; i < rgbaB.length; i += 4) {
        rgbaB[i] = 128;
        rgbaB[i + 3] = 255;
      }

      when(() => mockDecoder.decodeFile(any(that: predicate<PlatformFile>((f) => f.name == 'a.png')))).thenAnswer(
        (_) async => ImageDecodeResult(
          rgbaBytes: rgbaA,
          width: 16,
          height: 16,
          fileName: 'a.png',
        ),
      );
      when(() => mockDecoder.decodeFile(any(that: predicate<PlatformFile>((f) => f.name == 'b.png')))).thenAnswer(
        (_) async => ImageDecodeResult(
          rgbaBytes: rgbaB,
          width: 32,
          height: 32,
          fileName: 'b.png',
        ),
      );

      final frames = await repository.importFrames([
        PlatformFile(name: 'a.png', size: 100, path: '/path/a.png'),
        PlatformFile(name: 'b.png', size: 100, path: '/path/b.png')
      ]);

      expect(frames.length, 2);
      expect(frames[0].name, 'a.png');
      expect(frames[0].width, 16);
      expect(frames[0].height, 16);
      expect(frames[1].name, 'b.png');
      expect(frames[1].width, 32);
      expect(frames[1].height, 32);
      expect(frames[0].hash.length, 64);
      expect(frames[1].hash.length, 64);
    });

    test('importFrames skips duplicate content', () async {
      final rgba = Uint8List(4 * 4 * 4);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba[i] = 255;
        rgba[i + 3] = 255;
      }

      when(() => mockDecoder.decodeFile(any())).thenAnswer(
        (_) async => ImageDecodeResult(
          rgbaBytes: rgba,
          width: 4,
          height: 4,
          fileName: 'dup.png',
        ),
      );

      final frames = await repository.importFrames([
        PlatformFile(name: 'a.png', size: 100, path: '/path/a.png'),
        PlatformFile(name: 'b.png', size: 100, path: '/path/b.png'),
      ]);

      // Same content → only one frame returned
      expect(frames.length, 1);
    });

    test('importFrames returns empty list for empty input', () async {
      final frames = await repository.importFrames([]);
      expect(frames, isEmpty);
    });

    test('exportSheet writes PNG bytes to file', () async {
      final pngBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
      final outputPath = '${tempDir.path}/output.png';

      await repository.exportSheet(pngBytes, outputPath);

      final file = File(outputPath);
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), pngBytes);
    });

    test('exportJson writes formatted JSON to file', () async {
      final data = {'name': 'test', 'value': 42};
      final outputPath = '${tempDir.path}/output.json';

      await repository.exportJson(data, outputPath);

      final file = File(outputPath);
      expect(file.existsSync(), isTrue);

      final contents = await file.readAsString();
      expect(contents, contains('"name"'));
      expect(contents, contains('"test"'));
      expect(contents, contains('"value"'));
      expect(contents, contains('42'));
    });

    test('importFrames assigns unique IDs to each frame', () async {
      final rgbaA = Uint8List(4 * 4 * 4);
      for (var i = 0; i < rgbaA.length; i += 4) {
        rgbaA[i] = 255;
        rgbaA[i + 3] = 255;
      }
      final rgbaB = Uint8List(4 * 4 * 4);
      for (var i = 0; i < rgbaB.length; i += 4) {
        rgbaB[i] = 128;
        rgbaB[i + 3] = 255;
      }

      when(() => mockDecoder.decodeFile(any(that: predicate<PlatformFile>((f) => f.name == 'a.png')))).thenAnswer(
        (_) async => ImageDecodeResult(
          rgbaBytes: rgbaA, width: 4, height: 4, fileName: 'a.png',
        ),
      );
      when(() => mockDecoder.decodeFile(any(that: predicate<PlatformFile>((f) => f.name == 'b.png')))).thenAnswer(
        (_) async => ImageDecodeResult(
          rgbaBytes: rgbaB, width: 4, height: 4, fileName: 'b.png',
        ),
      );

      final frames = await repository.importFrames([
        PlatformFile(name: 'a.png', size: 100, path: '/path/a.png'),
        PlatformFile(name: 'b.png', size: 100, path: '/path/b.png')
      ]);

      expect(frames.length, 2);
      expect(frames[0].id, isNot(equals(frames[1].id)));
    });
  });
}
