import 'dart:typed_data';

import '../algorithms/max_rects_bin_pack.dart';
import '../entities/frame_placement.dart';
import '../entities/pack_result.dart';
import '../entities/sheet_config.dart';
import '../entities/sprite_frame.dart';
import 'stitch_sheet.dart';
import 'trim_alpha.dart';

class PackSpritesOutput {
  final PackResult packResult;
  final Uint8List pngBytes;

  const PackSpritesOutput({
    required this.packResult,
    required this.pngBytes,
  });
}

class PackSprites {
  final TrimAlpha trimAlpha;
  final StitchSheet stitchSheet;

  PackSprites({
    required this.trimAlpha,
    required this.stitchSheet,
  });

  Future<PackSpritesOutput> execute(
    List<SpriteFrame> frames,
    SheetConfig config,
  ) async {
    final List<SpriteFrame> trimmed = config.trimEnabled
        ? await Future.wait(frames.map((f) => trimAlpha(f)))
        : frames;

    final padding = config.framePadding;
    final inputRects = trimmed.map((f) {
      final ew = f.effectiveWidth;
      final eh = f.effectiveHeight;
      return InputRect(
        id: f.id,
        width: ew + padding,
        height: eh + padding,
      );
    }).toList();

    final output = MaxRectsBinPack.pack(
      inputRects,
      config.maxTextureSize,
      config.maxTextureSize,
    );

    final placements = <FramePlacement>[];
    final overflowIds = <String>[];
    final placedIds = <String>{};

    for (final pr in output.placed) {
      final frame = trimmed.firstWhere((f) => f.id == pr.id);
      final ew = frame.effectiveWidth;
      final eh = frame.effectiveHeight;

      placedIds.add(pr.id);
      placements.add(FramePlacement(
        frameId: frame.id,
        frameName: frame.name,
        x: pr.x,
        y: pr.y,
        width: ew,
        height: eh,
        trimmed: frame.isTrimmed,
        sourceWidth: frame.width,
        sourceHeight: frame.height,
        spriteSourceX: frame.trimRect?.x ?? 0,
        spriteSourceY: frame.trimRect?.y ?? 0,
      ));
    }

    for (final r in output.failed) {
      overflowIds.add(r);
    }

    final packResult = PackResult(
      placements: placements,
      canvasWidth: output.canvasWidth,
      canvasHeight: output.canvasHeight,
      overflowFrameIds: overflowIds,
    );

    final pngBytes = await stitchSheet.execute(
      StitchSheetInput(
        frames: trimmed,
        placements: placements,
        canvasWidth: output.canvasWidth,
        canvasHeight: output.canvasHeight,
      ),
    );

    return PackSpritesOutput(
      packResult: packResult,
      pngBytes: pngBytes,
    );
  }
}
