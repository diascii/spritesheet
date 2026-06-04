import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:spritesheet/data/sources/image_decoder.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('spritesheet_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ImageDecoder', () {
    test('decodes a valid PNG file', () async {
      final image = img.Image(width: 2, height: 2, numChannels: 4);
      image.setPixelRgba(0, 0, 255, 0, 0, 255);
      image.setPixelRgba(1, 0, 0, 255, 0, 255);
      image.setPixelRgba(0, 1, 0, 0, 255, 255);
      image.setPixelRgba(1, 1, 0, 0, 0, 0);

      final file = File('${tempDir.path}/test_sprite.png');
      await file.writeAsBytes(img.encodePng(image));

      final decoder = ImageDecoder();
      final result = await decoder.decodeFile(PlatformFile(name: 'test_sprite.png', size: 100, path: file.path));

      expect(result.width, 2);
      expect(result.height, 2);
      expect(result.fileName, 'test_sprite.png');
      expect(result.rgbaBytes.length, 2 * 2 * 4);
    });

    test('extracts fileName from path', () async {
      final image = img.Image(width: 1, height: 1, numChannels: 4);
      final file = File('${tempDir.path}/subdir/hero_run.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(img.encodePng(image));

      final decoder = ImageDecoder();
      final result = await decoder.decodeFile(PlatformFile(name: 'hero_run.png', size: 100, path: file.path));

      expect(result.fileName, 'hero_run.png');
    });

    test('throws on invalid file', () async {
      final file = File('${tempDir.path}/not_a_png.bin');
      await file.writeAsBytes([0, 0, 0, 0, 0]);

      final decoder = ImageDecoder();

      expect(
        () => decoder.decodeFile(PlatformFile(name: 'not_a_png.bin', size: 100, path: file.path)),
        throwsArgumentError,
      );
    });

    test('throws on non-existent file', () async {
      final decoder = ImageDecoder();

      expect(
        () => decoder.decodeFile(PlatformFile(name: 'nonexistent.png', size: 100, path: '${tempDir.path}/nonexistent.png')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
