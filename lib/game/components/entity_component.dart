import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:ui' as ui;
import '../../domain/entities/game_map.dart';
import '../../domain/entities/entity_behavior.dart';
import 'behavior_components.dart';
import '../pixel_game.dart';

class EntityComponent extends SpriteComponent
    with HasGameReference<PixelGame>, CollisionCallbacks {
  final MapEntity entityData;

  EntityComponent({
    required this.entityData,
    required ui.Image image,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          sprite: Sprite(image),
          position: position,
          size: size,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
      size: Vector2(entityData.hitboxWidth, entityData.hitboxHeight),
      position: Vector2((size.x - entityData.hitboxWidth) / 2, (size.y - entityData.hitboxHeight) / 2),
    ));

    for (final behavior in entityData.behaviors) {
      add(_createBehaviorComponent(behavior));
    }
  }

  Component _createBehaviorComponent(EntityBehavior behavior) {
    if (behavior is PlayerControlBehavior) {
      return PlayerControlComponent(behavior: behavior);
    } else if (behavior is PatrolBehavior) {
      return PatrolComponent(behavior: behavior);
    } else if (behavior is ChaseBehavior) {
      return ChaseComponent(behavior: behavior);
    } else if (behavior is DialogBehavior) {
      return DialogComponent(behavior: behavior);
    } else if (behavior is StaticBehavior) {
      return StaticBehaviorComponent(behavior: behavior);
    } else if (behavior is ProjectileBehavior) {
      return ProjectileComponent(behavior: behavior);
    } else if (behavior is GridMovementBehavior) {
      return GridMovementComponent(behavior: behavior);
    } else if (behavior is InteractableBehavior) {
      return InteractableComponent(behavior: behavior);
    }
    throw Exception('Unsupported behavior: $behavior');
  }
}
