import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/entity_behavior.dart';
import 'entity_component.dart';

abstract class BehaviorComponent<T extends EntityBehavior> extends Component with HasAncestor<EntityComponent> {
  final T behavior;

  BehaviorComponent({required this.behavior});
}

class PlayerControlComponent extends BehaviorComponent<PlayerControlBehavior> {
  PlayerControlComponent({required super.behavior});

  Vector2 velocity = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    
    // Process input
    final game = ancestor.game;
    final keysPressed = game.keysPressed;
    
    final direction = Vector2.zero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
      direction.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
      direction.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
      direction.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
      direction.x += 1;
    }

    if (game.joystick.direction != JoystickDirection.idle) {
      direction.setFrom(game.joystick.relativeDelta);
    }

    if (!direction.isZero()) {
      velocity = direction.normalized() * behavior.speed;
      ancestor.position += velocity * dt;
    } else {
      velocity = Vector2.zero();
    }
    
    game.gameCamera.follow(ancestor, maxSpeed: 200, snap: false);
  }
}

class PatrolComponent extends BehaviorComponent<PatrolBehavior> {
  PatrolComponent({required super.behavior});

  Vector2 startPosition = Vector2.zero();
  Vector2 targetPosition = Vector2.zero();
  bool movingToTarget = true;
  double pauseTimer = 0.0;

  @override
  void onMount() {
    super.onMount();
    startPosition = ancestor.position.clone();
    targetPosition = startPosition + Vector2(behavior.patrolDistanceX, behavior.patrolDistanceY);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (pauseTimer > 0) {
      pauseTimer -= dt;
      return;
    }

    final target = movingToTarget ? targetPosition : startPosition;
    final direction = target - ancestor.position;
    
    if (direction.length < 2.0) {
      ancestor.position = target.clone();
      movingToTarget = !movingToTarget;
      pauseTimer = behavior.pauseDuration;
      return;
    }

    final velocity = direction.normalized() * behavior.speed;
    ancestor.position += velocity * dt;
  }
}

class ChaseComponent extends BehaviorComponent<ChaseBehavior> {
  ChaseComponent({required super.behavior});

  @override
  void update(double dt) {
    super.update(dt);

    // Find player component
    final game = ancestor.game;
    EntityComponent? player;
    for (final c in game.gameWorld.children) {
      if (c is EntityComponent && c.children.any((bc) => bc is PlayerControlComponent)) {
        player = c;
        break;
      }
    }

    if (player == null) return;

    final distance = ancestor.position.distanceTo(player.position);
    
    if (distance < behavior.detectionRadius) {
      final direction = player.position - ancestor.position;
      if (direction.length > 2.0) {
        final velocity = direction.normalized() * behavior.speed;
        ancestor.position += velocity * dt;
      }
    }
  }
}

class DialogComponent extends BehaviorComponent<DialogBehavior> {
  DialogComponent({required super.behavior});
  // TODO: Trigger dialog on collision / interaction
}

class StaticBehaviorComponent extends BehaviorComponent<StaticBehavior> {
  StaticBehaviorComponent({required super.behavior});
}

class ProjectileComponent extends BehaviorComponent<ProjectileBehavior> {
  ProjectileComponent({required super.behavior});
  // TODO: Implement flying forward and disappearing
}

class GridMovementComponent extends BehaviorComponent<GridMovementBehavior> {
  GridMovementComponent({required super.behavior});

  Vector2? targetPosition;
  late final double tileSize;
  
  @override
  void onMount() {
    super.onMount();
    tileSize = ancestor.game.scene.map.tileSize.toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final game = ancestor.game;
    
    // If moving, move towards target
    if (targetPosition != null) {
      final direction = targetPosition! - ancestor.position;
      final distance = direction.length;
      final step = behavior.speed * tileSize * dt;
      
      if (distance <= step) {
        ancestor.position = targetPosition!;
        targetPosition = null;
      } else {
        ancestor.position += direction.normalized() * step;
      }
      game.gameCamera.follow(ancestor, maxSpeed: 200, snap: false);
      return;
    }

    // Not moving, check input
    final keysPressed = game.keysPressed;
    final direction = Vector2.zero();
    
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
      direction.y = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
      direction.y = 1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
      direction.x = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
      direction.x = 1;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      _tryInteract();
      return; // Do not move if interacting
    }

    if (!direction.isZero()) {
      // Calculate target
      final newTarget = ancestor.position + direction * tileSize;
      
      // Basic collision check against map bounds
      final map = game.scene.map;
      if (newTarget.x >= 0 && newTarget.x <= (map.width - 1) * tileSize &&
          newTarget.y >= 0 && newTarget.y <= (map.height - 1) * tileSize) {
        
        // Check solid collision
        final targetCol = (newTarget.x / tileSize).round();
        final targetRow = (newTarget.y / tileSize).round();
        final index = targetRow * map.width + targetCol;
        
        bool isSolid = false;
        if (map.layers.isNotEmpty && map.layers[0].solids.length > index) {
          isSolid = map.layers[0].solids[index];
        }

        if (!isSolid) {
          targetPosition = newTarget;
        }
      }
    }
  }

  void _tryInteract() {
    // Basic interaction: find nearest interactable entity
    final game = ancestor.game;
    for (final child in game.gameWorld.children) {
      if (child is EntityComponent && child != ancestor) {
        final dist = ancestor.position.distanceTo(child.position);
        if (dist <= tileSize * 1.5) { // Within 1 tile
          for (final b in child.children) {
            if (b is InteractableComponent) {
              game.triggerInteraction(b.behavior);
              return;
            }
          }
        }
      }
    }
  }
}

class InteractableComponent extends BehaviorComponent<InteractableBehavior> {
  InteractableComponent({required super.behavior});
}
