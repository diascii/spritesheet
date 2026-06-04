import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:ui' as ui;

class TileComponent extends SpriteComponent with HasGameReference {
  final bool isSolid;

  TileComponent({
    required ui.Image image,
    required Vector2 position,
    required Vector2 size,
    this.isSolid = false,
  }) : super(
    sprite: Sprite(image),
    position: position,
    size: size,
  );

  @override
  Future<void> onLoad() async {
    if (isSolid) {
      add(RectangleHitbox()..collisionType = CollisionType.passive);
    }
  }
}
