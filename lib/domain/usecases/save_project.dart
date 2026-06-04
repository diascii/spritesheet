import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../utils/downloader.dart';

import '../entities/frame_annotation.dart';
import '../entities/sprite_frame.dart';
import '../entities/scene.dart';
import '../entities/game_template.dart';

class SaveProject {
  Future<void> execute({
    required String filePath,
    required List<SpriteFrame> frames,
    required List<FrameAnnotation> annotations,
    required List<Scene>? scenes,
    required GameTemplate template,
    List<ui.Color>? palette,
  }) async {
    final Map<String, dynamic> projectData = {
      'version': 1,
      'template': template.name,
      'frames': frames.map((f) => f.toJson()).toList(),
      'annotations': annotations.map((a) => a.toJson()).toList(),
      'palette': palette?.map((c) => c.toARGB32().toRadixString(16).padLeft(8, '0')).toList(),
      'scenes': scenes?.map((s) => s.toJson()).toList(),
    };

    final jsonString = jsonEncode(projectData);
    final bytes = utf8.encode(jsonString);

    if (kIsWeb) {
      final filename = filePath.split(RegExp(r'[\\/]')).last;
      downloadFileForWeb(Uint8List.fromList(bytes), filename);
    } else {
      final file = File(filePath);
      await file.writeAsString(jsonString);
    }
  }
}
