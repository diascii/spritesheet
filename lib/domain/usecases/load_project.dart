import 'dart:convert';
import 'dart:ui' as ui;
import '../entities/frame_annotation.dart';
import '../entities/sprite_frame.dart';
import '../entities/scene.dart';
import '../entities/game_template.dart';
import '../entities/game_map.dart';

class ProjectData {
  final List<SpriteFrame> frames;
  final List<FrameAnnotation> annotations;
  final List<Scene> scenes;
  final GameTemplate template;
  final List<ui.Color>? palette;

  ProjectData({
    required this.frames,
    required this.annotations,
    required this.scenes,
    required this.template,
    this.palette,
  });
}

class LoadProject {
  Future<ProjectData> execute(String jsonString) async {
    final Map<String, dynamic> projectData = jsonDecode(jsonString);

    if (projectData.containsKey('meta') && projectData['meta'] != null && projectData['meta']['app'] == 'SpriteSheet Packer Mobile') {
      throw Exception('This is an exported atlas JSON, not a project file. You must use "Save Project" to create a loadable project.');
    }

    if (projectData['version'] != 1) {
      throw Exception('Unsupported project version: ${projectData['version']}');
    }

    final framesJson = projectData['frames'] as List;
    final frames = framesJson.map((e) => SpriteFrame.fromJson(e)).toList();

    final annotations = (projectData['annotations'] as List)
        .map((a) => FrameAnnotation.fromJson(a as Map<String, dynamic>))
        .toList();

    List<ui.Color>? palette;
    if (projectData['palette'] != null) {
      palette = (projectData['palette'] as List).map((c) {
        final hex = c as String;
        return ui.Color(int.parse(hex, radix: 16));
      }).toList();
    }

    List<Scene> scenes = [];
    if (projectData['scenes'] != null) {
      scenes = (projectData['scenes'] as List).map((m) => Scene.fromJson(m as Map<String, dynamic>)).toList();
    } else if (projectData['maps'] != null) {
      // Legacy support for older projects
      scenes = (projectData['maps'] as List).map((m) {
        final map = GameMap.fromJson(m as Map<String, dynamic>);
        return Scene(id: map.id, name: map.name, map: map);
      }).toList();
    }

    GameTemplate template = GameTemplate.action;
    if (projectData['template'] != null) {
      final tStr = projectData['template'] as String;
      template = GameTemplate.values.firstWhere((e) => e.name == tStr, orElse: () => GameTemplate.action);
    }

    return ProjectData(frames: frames, annotations: annotations, scenes: scenes, template: template, palette: palette);
  }
}
