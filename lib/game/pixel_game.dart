import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../domain/entities/scene.dart';
import '../domain/entities/sprite_frame.dart';
import '../domain/entities/entity_behavior.dart';
import '../data/services/image_registry.dart';
import 'game_map_loader.dart';
import 'components/entity_component.dart';
import 'components/behavior_components.dart';

/// The Flame game instance. Created once when user presses "Play".
/// Disposed when user presses "Stop".
class PixelGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  final Scene scene;
  final List<SpriteFrame> frames;
  final ImageRegistry imageRegistry;
  final void Function(SceneTransition)? onTransition;
  final void Function(InteractableBehavior)? onInteraction;

  PixelGame({
    required this.scene,
    required this.frames,
    required this.imageRegistry,
    this.onTransition,
    this.onInteraction,
  });

  late final World gameWorld;
  late final CameraComponent gameCamera;
  late final GameMapLoader _loader;
  EntityComponent? player;
  late final JoystickComponent joystick;
  
  // Track keys for BehaviorComponents
  final Set<LogicalKeyboardKey> keysPressed = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _loader = GameMapLoader(scene: scene, frames: frames, registry: imageRegistry);
    await _loader.preloadImages();

    gameWorld = World();
    add(gameWorld);

    await _loadTiles();
    await _loadEntities();

    gameCamera = CameraComponent(world: gameWorld);
    add(gameCamera);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white54),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white24),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    gameCamera.viewport.add(joystick);

    if (player != null) {
      gameCamera.follow(player!, maxSpeed: 200, snap: true);
    }
  }

  Future<void> _loadTiles() async {
    final tileComponents = await _loader.buildTileComponents();
    gameWorld.addAll(tileComponents);
  }

  Future<void> _loadEntities() async {
    final entityComponents = await _loader.buildEntityComponents();
    gameWorld.addAll(entityComponents);

    for (final c in entityComponents) {
      if (c is EntityComponent && c.entityData.behaviors.any((b) => b is PlayerControlBehavior)) {
        player = c;
        break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    this.keysPressed.clear();
    this.keysPressed.addAll(keysPressed);
    return KeyEventResult.handled;
  }

  void triggerTransition(SceneTransition transition) {
    if (onTransition != null) {
      onTransition!(transition);
    }
  }

  void triggerInteraction(InteractableBehavior behavior) {
    if (onInteraction != null) {
      onInteraction!(behavior);
    }
  }
}
