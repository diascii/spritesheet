import 'dart:typed_data';

import '../entities/frame_annotation.dart';
import '../entities/pack_result.dart';
import '../entities/sheet_config.dart';
import '../entities/sprite_frame.dart';
import '../repositories/image_repository.dart';

class ExportSheetOutput {
  final String pngPath;
  final String jsonPath;

  const ExportSheetOutput({
    required this.pngPath,
    required this.jsonPath,
  });
}

class ExportSheet {
  final ImageRepository _repository;

  ExportSheet({required ImageRepository repository}) : _repository = repository;

  Future<ExportSheetOutput> execute({
    required PackResult packResult,
    required Uint8List pngBytes,
    required SheetConfig config,
    required List<FrameAnnotation> annotations,
    required List<SpriteFrame> frames,
    required String outputDirectory,
  }) async {
    final baseName = config.sheetName;
    final pngPath = '$outputDirectory/$baseName.png';
    final jsonPath = '$outputDirectory/$baseName.json';

    final json = _buildJson(packResult, config, annotations, frames);

    await _repository.exportSheet(pngBytes, pngPath);
    await _repository.exportJson(json, jsonPath);

    return ExportSheetOutput(pngPath: pngPath, jsonPath: jsonPath);
  }

  Map<String, dynamic> _buildJson(
    PackResult packResult,
    SheetConfig config,
    List<FrameAnnotation> annotations,
    List<SpriteFrame> frames,
  ) {
    final annotationMap = <String, FrameAnnotation>{};
    for (final a in annotations) {
      annotationMap[a.frameId] = a;
    }

    final frameMap = <String, SpriteFrame>{};
    for (final f in frames) {
      frameMap[f.id] = f;
    }

    final framesJson = <String, dynamic>{};

    for (final p in packResult.placements) {
      final annotation = annotationMap[p.frameId];
      final frame = frameMap[p.frameId];

      framesJson[p.frameName] = {
        'frame': {
          'x': p.x,
          'y': p.y,
          'w': p.width,
          'h': p.height,
        },
        'trimmed': p.trimmed,
        'sourceSize': {
          'w': p.sourceWidth,
          'h': p.sourceHeight,
        },
        'spriteSourceSize': {
          'x': p.spriteSourceX,
          'y': p.spriteSourceY,
          'w': p.width,
          'h': p.height,
        },
        if (frame?.tag != null && frame!.tag!.isNotEmpty) 'tag': frame.tag,
        if (annotation?.anchor != null) 'anchor': {
          'x': annotation!.anchor!.x,
          'y': annotation.anchor!.y,
        },
        if (annotation != null && annotation.hitboxes.isNotEmpty)
          'hitboxes': annotation.hitboxes.map((h) => h.toJson()).toList(),
      };
    }

    return {
      'meta': {
        'app': 'SpriteSheet Packer Mobile',
        'version': '1.0.0',
        'image': '${config.sheetName}.png',
        'format': 'RGBA8888',
        'size': {'w': packResult.canvasWidth, 'h': packResult.canvasHeight},
        'targetEngine': config.targetEngine,
      },
      'frames': framesJson,
    };
  }
}
