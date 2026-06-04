import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/scene.dart';
import '../../domain/entities/game_template.dart';

class ProjectState extends Equatable {
  final String projectName;
  final GameTemplate template;
  final List<Scene> scenes;
  final String? activeSceneId;
  final Map<String, dynamic> globalVariables;
  // TODO: Add audioAssets, monsterTemplates, weaponTemplates, itemTemplates in later phases

  const ProjectState({
    this.projectName = 'New Project',
    this.template = GameTemplate.action,
    this.scenes = const [],
    this.activeSceneId,
    this.globalVariables = const {},
  });

  ProjectState copyWith({
    String? projectName,
    GameTemplate? template,
    List<Scene>? scenes,
    String? activeSceneId,
    Map<String, dynamic>? globalVariables,
  }) {
    return ProjectState(
      projectName: projectName ?? this.projectName,
      template: template ?? this.template,
      scenes: scenes ?? this.scenes,
      activeSceneId: activeSceneId ?? this.activeSceneId,
      globalVariables: globalVariables ?? this.globalVariables,
    );
  }

  @override
  List<Object?> get props => [
        projectName,
        template,
        scenes,
        activeSceneId,
        globalVariables,
      ];
}

class ProjectCubit extends Cubit<ProjectState> {
  ProjectCubit() : super(const ProjectState());

  void setProjectName(String name) {
    emit(state.copyWith(projectName: name));
  }

  void setTemplate(GameTemplate template) {
    emit(state.copyWith(template: template));
  }

  void addScene(Scene scene) {
    final scenes = List<Scene>.from(state.scenes)..add(scene);
    emit(state.copyWith(
      scenes: scenes,
      activeSceneId: state.activeSceneId ?? scene.id,
    ));
  }

  void updateScene(Scene scene) {
    final index = state.scenes.indexWhere((s) => s.id == scene.id);
    if (index != -1) {
      final scenes = List<Scene>.from(state.scenes)..[index] = scene;
      emit(state.copyWith(scenes: scenes));
    }
  }

  void removeScene(String sceneId) {
    final scenes = state.scenes.where((s) => s.id != sceneId).toList();
    final activeSceneId = state.activeSceneId == sceneId
        ? (scenes.isNotEmpty ? scenes.first.id : null)
        : state.activeSceneId;
    emit(state.copyWith(scenes: scenes, activeSceneId: activeSceneId));
  }

  void setActiveScene(String sceneId) {
    if (state.scenes.any((s) => s.id == sceneId)) {
      emit(state.copyWith(activeSceneId: sceneId));
    }
  }

  void setGlobalVariable(String key, dynamic value) {
    final vars = Map<String, dynamic>.from(state.globalVariables);
    vars[key] = value;
    emit(state.copyWith(globalVariables: vars));
  }

  void removeGlobalVariable(String key) {
    final vars = Map<String, dynamic>.from(state.globalVariables);
    vars.remove(key);
    emit(state.copyWith(globalVariables: vars));
  }

  void loadProjectData({
    required String projectName,
    required GameTemplate template,
    required List<Scene> scenes,
    required String? activeSceneId,
    required Map<String, dynamic> globalVariables,
  }) {
    emit(ProjectState(
      projectName: projectName,
      template: template,
      scenes: scenes,
      activeSceneId: activeSceneId ?? (scenes.isNotEmpty ? scenes.first.id : null),
      globalVariables: globalVariables,
    ));
  }
}
