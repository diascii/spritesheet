import 'dart:ui';
import 'package:equatable/equatable.dart';
import 'game_map.dart';

class Scene extends Equatable {
  final String id;
  final String name;
  final GameMap map;
  final String? bgmAssetId;
  final Color backgroundColor;
  final List<SceneTransition> transitions;

  const Scene({
    required this.id,
    required this.name,
    required this.map,
    this.bgmAssetId,
    this.backgroundColor = const Color(0xFF000000),
    this.transitions = const [],
  });

  Scene copyWith({
    String? id,
    String? name,
    GameMap? map,
    String? bgmAssetId,
    Color? backgroundColor,
    List<SceneTransition>? transitions,
  }) {
    return Scene(
      id: id ?? this.id,
      name: name ?? this.name,
      map: map ?? this.map,
      bgmAssetId: bgmAssetId ?? this.bgmAssetId,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      transitions: transitions ?? this.transitions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'map': map.toJson(),
      'bgmAssetId': bgmAssetId,
      'backgroundColor': backgroundColor.value,
      'transitions': transitions.map((t) => t.toJson()).toList(),
    };
  }

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      name: json['name'] as String,
      map: GameMap.fromJson(json['map']),
      bgmAssetId: json['bgmAssetId'] as String?,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : const Color(0xFF000000),
      transitions: (json['transitions'] as List?)
              ?.map((t) => SceneTransition.fromJson(t))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props =>
      [id, name, map, bgmAssetId, backgroundColor, transitions];
}

class SceneTransition extends Equatable {
  final String id;
  final String targetSceneId;
  final double triggerX, triggerY, triggerW, triggerH;
  final double spawnX, spawnY;

  const SceneTransition({
    required this.id,
    required this.targetSceneId,
    required this.triggerX,
    required this.triggerY,
    required this.triggerW,
    required this.triggerH,
    required this.spawnX,
    required this.spawnY,
  });

  SceneTransition copyWith({
    String? id,
    String? targetSceneId,
    double? triggerX,
    double? triggerY,
    double? triggerW,
    double? triggerH,
    double? spawnX,
    double? spawnY,
  }) {
    return SceneTransition(
      id: id ?? this.id,
      targetSceneId: targetSceneId ?? this.targetSceneId,
      triggerX: triggerX ?? this.triggerX,
      triggerY: triggerY ?? this.triggerY,
      triggerW: triggerW ?? this.triggerW,
      triggerH: triggerH ?? this.triggerH,
      spawnX: spawnX ?? this.spawnX,
      spawnY: spawnY ?? this.spawnY,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetSceneId': targetSceneId,
      'triggerX': triggerX,
      'triggerY': triggerY,
      'triggerW': triggerW,
      'triggerH': triggerH,
      'spawnX': spawnX,
      'spawnY': spawnY,
    };
  }

  factory SceneTransition.fromJson(Map<String, dynamic> json) {
    return SceneTransition(
      id: json['id'] as String,
      targetSceneId: json['targetSceneId'] as String,
      triggerX: (json['triggerX'] as num).toDouble(),
      triggerY: (json['triggerY'] as num).toDouble(),
      triggerW: (json['triggerW'] as num).toDouble(),
      triggerH: (json['triggerH'] as num).toDouble(),
      spawnX: (json['spawnX'] as num).toDouble(),
      spawnY: (json['spawnY'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetSceneId,
        triggerX,
        triggerY,
        triggerW,
        triggerH,
        spawnX,
        spawnY
      ];
}
