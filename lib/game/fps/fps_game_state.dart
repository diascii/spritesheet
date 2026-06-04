import 'dart:math';
import '../../domain/entities/game_map.dart';
import '../../domain/entities/scene.dart';

import '../../domain/entities/entity_behavior.dart';

class FPSGameState {
  // Player
  double playerX;
  double playerY;
  double playerAngle; // in radians

  // Map
  final Scene scene;

  FPSGameState({
    required this.playerX,
    required this.playerY,
    required this.playerAngle,
    required this.scene,
  });

  factory FPSGameState.fromScene(Scene scene) {
    // Find player spawn point, default to 1.5, 1.5
    double startX = 1.5;
    double startY = 1.5;
    double startAngle = 0.0;

    for (final entity in scene.map.entities) {
      if (entity.behaviors.any((b) => b is PlayerControlBehavior)) {
        startX = (entity.x / scene.map.tileSize) + 0.5;
        startY = (entity.y / scene.map.tileSize) + 0.5;
        break;
      }
    }

    return FPSGameState(
      playerX: startX,
      playerY: startY,
      playerAngle: startAngle,
      scene: scene,
    );
  }
}
