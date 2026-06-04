import 'package:flame/components.dart';

import '../domain/entities/scene.dart';
import '../domain/entities/sprite_frame.dart';
import '../data/services/image_registry.dart';
import 'components/tile_component.dart';
import 'components/entity_component.dart';
import 'components/transition_zone.dart';

class GameMapLoader {
  final Scene scene;
  final List<SpriteFrame> frames;
  final ImageRegistry registry;

  GameMapLoader({required this.scene, required this.frames, required this.registry});

  /// Pre-loads all frame images into the registry.
  Future<void> preloadImages() async {
    for (final frame in frames) {
      await registry.getImage(frame.id, frame.imageBytes, frame.width, frame.height);
    }
  }

  /// Builds tile components for the game world.
  Future<List<Component>> buildTileComponents() async {
    final List<Component> components = [];
    final map = scene.map;
    final layer = map.layers[0]; // Assuming first layer is tiles
    for (int y = 0; y < map.height; y++) {
      for (int x = 0; x < map.width; x++) {
        final index = y * map.width + x;
        final tileId = layer.tiles[index];
        if (tileId != null) {
          final frame = frames.cast<SpriteFrame?>().firstWhere((f) => f?.id == tileId, orElse: () => null);
          if (frame != null) {
            final image = registry.getCached(frame.id);
            if (image != null) {
              final isSolid = layer.solids.length > index ? layer.solids[index] : false;
              components.add(TileComponent(
                image: image,
                position: Vector2(x * map.tileSize.toDouble(), y * map.tileSize.toDouble()),
                size: Vector2(map.tileSize.toDouble(), map.tileSize.toDouble()),
                isSolid: isSolid,
              ));
            }
          }
        }
      }
    }
    return components;
  }

  /// Builds entity components (player, enemies, etc.)
  Future<List<Component>> buildEntityComponents() async {
    final List<Component> components = [];
    final map = scene.map;
    for (final entity in map.entities) {
      final frame = frames.cast<SpriteFrame?>().firstWhere((f) => f?.id == entity.frameId, orElse: () => null);
      if (frame != null) {
        final image = registry.getCached(frame.id);
        if (image != null) {
          components.add(EntityComponent(
            entityData: entity,
            image: image,
            position: Vector2(entity.x, entity.y),
            size: Vector2(map.tileSize.toDouble(), map.tileSize.toDouble()), // Or entity size
          ));
        }
      }
    }
    
    // Add transition zones
    for (final transition in scene.transitions) {
      components.add(TransitionZone(transition: transition));
    }
    
    return components;
  }
}
