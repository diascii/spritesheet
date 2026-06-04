import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'entity_component.dart';
import 'behavior_components.dart';
import '../../domain/entities/scene.dart';
import '../pixel_game.dart';

class TransitionZone extends PositionComponent with CollisionCallbacks, HasGameRef<PixelGame> {
  final SceneTransition transition;

  TransitionZone({required this.transition})
      : super(
          position: Vector2(transition.triggerX, transition.triggerY),
          size: Vector2(transition.triggerW, transition.triggerH),
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EntityComponent && other.children.any((c) => c is PlayerControlComponent || c is GridMovementComponent)) {
      gameRef.triggerTransition(transition);
    }
  }
}
