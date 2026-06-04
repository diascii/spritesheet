import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spritesheet/domain/entities/sheet_config.dart';
import 'package:spritesheet/domain/entities/sprite_frame.dart';
import 'package:spritesheet/domain/usecases/pack_sprites.dart';
import 'package:spritesheet/domain/usecases/stitch_sheet.dart';
import 'package:spritesheet/domain/usecases/trim_alpha.dart';

Uint8List _makeRgba(int w, int h) {
  final bytes = Uint8List(w * h * 4);
  for (var i = 0; i < bytes.length; i += 4) {
    bytes[i] = 255;
    bytes[i + 1] = 0;
    bytes[i + 2] = 128;
    bytes[i + 3] = 255;
  }
  return bytes;
}

void main() {
  late PackSprites packSprites;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    packSprites = PackSprites(
      trimAlpha: TrimAlpha(),
      stitchSheet: StitchSheet(),
    );
  });

  group('PackSprites', () {
    test('packs two small frames and returns PNG', () async {
      final frames = [
        SpriteFrame(
          id: 'a', name: 'a.png', width: 16, height: 16,
          imageBytes: _makeRgba(16, 16), hash: 'ha',
        ),
        SpriteFrame(
          id: 'b', name: 'b.png', width: 16, height: 16,
          imageBytes: _makeRgba(16, 16), hash: 'hb',
        ),
      ];

      final config = const SheetConfig(
        maxTextureSize: 64,
        framePadding: 0,
        trimEnabled: false,
      );

      final output = await packSprites.execute(frames, config);

      expect(output.packResult.placements.length, 2);
      expect(output.packResult.overflowFrameIds, isEmpty);
      expect(output.packResult.hasOverflow, isFalse);
      expect(output.packResult.canvasWidth, greaterThan(0));
      expect(output.packResult.canvasHeight, greaterThan(0));
      expect(output.pngBytes.length, greaterThan(0));
    });

    test('packs frames with padding', () async {
      final frames = [
        SpriteFrame(
          id: 'a', name: 'a.png', width: 16, height: 16,
          imageBytes: _makeRgba(16, 16), hash: 'ha',
        ),
        SpriteFrame(
          id: 'b', name: 'b.png', width: 16, height: 16,
          imageBytes: _makeRgba(16, 16), hash: 'hb',
        ),
      ];

      final config = const SheetConfig(
        maxTextureSize: 64,
        framePadding: 2,
        trimEnabled: false,
      );

      final output = await packSprites.execute(frames, config);

      expect(output.packResult.placements.length, 2);
      expect(output.pngBytes.length, greaterThan(0));
    });

    test('handles frames that exceed max texture size', () async {
      final frames = [
        SpriteFrame(
          id: 'big', name: 'big.png', width: 256, height: 256,
          imageBytes: _makeRgba(256, 256), hash: 'hbig',
        ),
      ];

      final config = const SheetConfig(
        maxTextureSize: 128,
        framePadding: 0,
        trimEnabled: false,
      );

      final output = await packSprites.execute(frames, config);

      expect(output.packResult.placements, isEmpty);
      expect(output.packResult.overflowFrameIds, ['big']);
    });

    test('trims frames before packing when trimEnabled', () async {
      final opaqueBytes = Uint8List(16 * 16 * 4);
      for (var i = 0; i < opaqueBytes.length; i += 4) {
        opaqueBytes[i] = 255;
        opaqueBytes[i + 1] = 0;
        opaqueBytes[i + 2] = 128;
        // Leave alpha = 0 for most pixels
      }
      // Set a 8x8 opaque square in the center
      for (var y = 4; y < 12; y++) {
        for (var x = 4; x < 12; x++) {
          final i = (y * 16 + x) * 4;
          opaqueBytes[i + 3] = 255;
        }
      }

      final frames = [
        SpriteFrame(
          id: 't', name: 'trim.png', width: 16, height: 16,
          imageBytes: opaqueBytes, hash: 'ht',
        ),
      ];

      final config = const SheetConfig(
        maxTextureSize: 64,
        framePadding: 0,
        trimEnabled: true,
      );

      final output = await packSprites.execute(frames, config);

      expect(output.packResult.placements.length, 1);
      final placement = output.packResult.placements.first;
      expect(placement.trimmed, isTrue);
      // Trimmed region should be 8x8
      expect(placement.width, 8);
      expect(placement.height, 8);
      expect(placement.spriteSourceX, 4);
      expect(placement.spriteSourceY, 4);
    });
  });
}
