import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../entities/frame_placement.dart';
import '../entities/sprite_frame.dart';

class StitchSheetInput {
  final List<SpriteFrame> frames;
  final List<FramePlacement> placements;
  final int canvasWidth;
  final int canvasHeight;

  const StitchSheetInput({
    required this.frames,
    required this.placements,
    required this.canvasWidth,
    required this.canvasHeight,
  });
}

class StitchSheet {
  Future<Uint8List> execute(StitchSheetInput input) {
    return compute(_stitchIsolate, input);
  }
}

Uint8List _stitchIsolate(StitchSheetInput input) {
  final canvas = Uint8List(input.canvasWidth * input.canvasHeight * 4);
  final frameMap = <String, SpriteFrame>{};
  for (final f in input.frames) {
    frameMap[f.id] = f;
  }

  for (final p in input.placements) {
    final frame = frameMap[p.frameId];
    if (frame == null) continue;

    final srcW = p.width;
    final srcH = p.height;
    final srcOriginX = p.spriteSourceX;
    final srcOriginY = p.spriteSourceY;
    final fx = p.x;
    final fy = p.y;

    for (int row = 0; row < srcH; row++) {
      final srcStart = ((srcOriginY + row) * frame.width + srcOriginX) * 4;
      final dstStart = ((fy + row) * input.canvasWidth + fx) * 4;
      canvas.setRange(dstStart, dstStart + srcW * 4, frame.imageBytes, srcStart);
    }
  }

  final image = img.Image.fromBytes(
    width: input.canvasWidth,
    height: input.canvasHeight,
    bytes: canvas.buffer,
    numChannels: 4,
  );

  return Uint8List.fromList(img.encodePng(image));
}
