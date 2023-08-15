import 'dart:async';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/util/collision_util.dart';

/// Mixin responsible for adding stop the movement when happen collision
mixin BlockMovementCollision on Movement {
  final _collisionUtil = CollisionUtil();

  Rect? _shapeRectNormalized;

  bool onBlockMovement(
    Set<Vector2> intersectionPoints,
    GameComponent other,
  ) {
    return true;
  }

  void onBlockedMovement(
    PositionComponent other,
    Direction? direction,
  ) {}

  Vector2 midPoint = Vector2.zero();

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    bool stopOtherMovement = true;
    bool stopMovement = other is GameComponent
        ? onBlockMovement(intersectionPoints, other)
        : true;
    if (stopMovement && other is BlockMovementCollision) {
      stopOtherMovement = other.onBlockMovement(intersectionPoints, this);
    }
    if (stopMovement && stopOtherMovement && other is! Sensor) {
      if (_shapeRectNormalized != null) {
        var reverseDisplacement = lastDisplacement.clone();

        midPoint = intersectionPoints.reduce(
          (value, element) => value + element,
        );
        midPoint /= intersectionPoints.length.toDouble();
        midPoint = midPoint - position;
        midPoint.lerp(_shapeRectNormalized!.center.toVector2(), 0.2);

        var direction = _collisionUtil.getDirectionCollision(
          _shapeRectNormalized!,
          midPoint,
        );

        reverseDisplacement = _adjustDisplacement(
          reverseDisplacement,
          direction,
        );

        position += reverseDisplacement * -1;
        stopFromCollision(
          isX: reverseDisplacement.x.abs() > 0,
          isY: reverseDisplacement.y.abs() > 0,
        );
        onBlockedMovement(other, direction);
      }

      super.onCollision(intersectionPoints, other);
    }
  }

  @override
  FutureOr<void> add(Component component) {
    if (component is ShapeHitbox) {
      _shapeRectNormalized = component.toRect();
    }
    return super.add(component);
  }

  Vector2 _adjustDisplacement(
    Vector2 reverseDisplacement,
    Direction? direction,
  ) {
    if (direction != null) {
      if ((direction == Direction.down || direction == Direction.up) &&
          reverseDisplacement.x.abs() > 0) {
        if (direction == lastDirectionVertical) {
          reverseDisplacement = reverseDisplacement.copyWith(x: 0);
        } else {
          reverseDisplacement.setZero();
        }
      } else if ((direction == Direction.left ||
              direction == Direction.right) &&
          reverseDisplacement.y.abs() > 0) {
        if (direction == lastDirectionHorizontal) {
          reverseDisplacement = reverseDisplacement.copyWith(y: 0);
        } else {
          reverseDisplacement.setZero();
        }
      }
    }
    return reverseDisplacement;
  }
}
