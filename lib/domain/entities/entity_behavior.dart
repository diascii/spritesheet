import 'package:equatable/equatable.dart';

sealed class EntityBehavior extends Equatable {
  const EntityBehavior();

  Map<String, dynamic> toJson();

  factory EntityBehavior.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'playerControl':
        return PlayerControlBehavior.fromJson(json);
      case 'patrol':
        return PatrolBehavior.fromJson(json);
      case 'chase':
        return ChaseBehavior.fromJson(json);
      case 'dialog':
        return DialogBehavior.fromJson(json);
      case 'static':
        return StaticBehavior.fromJson(json);
      case 'projectile':
        return ProjectileBehavior.fromJson(json);
      case 'gridMovement':
        return GridMovementBehavior.fromJson(json);
      case 'interactable':
        return InteractableBehavior.fromJson(json);
      default:
        throw Exception('Unknown behavior type: $type');
    }
  }
}

class PlayerControlBehavior extends EntityBehavior {
  final double speed;
  final String? idleTag;
  final String? walkTag;

  const PlayerControlBehavior({this.speed = 100.0, this.idleTag, this.walkTag});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playerControl',
        'speed': speed,
        'idleTag': idleTag,
        'walkTag': walkTag,
      };

  factory PlayerControlBehavior.fromJson(Map<String, dynamic> json) {
    return PlayerControlBehavior(
      speed: (json['speed'] as num?)?.toDouble() ?? 100.0,
      idleTag: json['idleTag'] as String?,
      walkTag: json['walkTag'] as String?,
    );
  }

  @override
  List<Object?> get props => [speed, idleTag, walkTag];
}

class PatrolBehavior extends EntityBehavior {
  final double speed;
  final double patrolDistanceX;
  final double patrolDistanceY;
  final double pauseDuration;

  const PatrolBehavior({
    this.speed = 50.0,
    this.patrolDistanceX = 0.0,
    this.patrolDistanceY = 0.0,
    this.pauseDuration = 1.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'patrol',
        'speed': speed,
        'patrolDistanceX': patrolDistanceX,
        'patrolDistanceY': patrolDistanceY,
        'pauseDuration': pauseDuration,
      };

  factory PatrolBehavior.fromJson(Map<String, dynamic> json) {
    return PatrolBehavior(
      speed: (json['speed'] as num?)?.toDouble() ?? 50.0,
      patrolDistanceX: (json['patrolDistanceX'] as num?)?.toDouble() ?? 0.0,
      patrolDistanceY: (json['patrolDistanceY'] as num?)?.toDouble() ?? 0.0,
      pauseDuration: (json['pauseDuration'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [speed, patrolDistanceX, patrolDistanceY, pauseDuration];
}

class ChaseBehavior extends EntityBehavior {
  final double speed;
  final double detectionRadius;
  final double loseRadius;

  const ChaseBehavior({
    this.speed = 75.0,
    this.detectionRadius = 150.0,
    this.loseRadius = 250.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'chase',
        'speed': speed,
        'detectionRadius': detectionRadius,
        'loseRadius': loseRadius,
      };

  factory ChaseBehavior.fromJson(Map<String, dynamic> json) {
    return ChaseBehavior(
      speed: (json['speed'] as num?)?.toDouble() ?? 75.0,
      detectionRadius: (json['detectionRadius'] as num?)?.toDouble() ?? 150.0,
      loseRadius: (json['loseRadius'] as num?)?.toDouble() ?? 250.0,
    );
  }

  @override
  List<Object?> get props => [speed, detectionRadius, loseRadius];
}

class DialogBehavior extends EntityBehavior {
  final List<DialogLine> lines;
  final bool repeatable;

  const DialogBehavior({this.lines = const [], this.repeatable = true});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'dialog',
        'lines': lines.map((l) => l.toJson()).toList(),
        'repeatable': repeatable,
      };

  factory DialogBehavior.fromJson(Map<String, dynamic> json) {
    return DialogBehavior(
      lines: (json['lines'] as List?)?.map((j) => DialogLine.fromJson(j)).toList() ?? [],
      repeatable: json['repeatable'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [lines, repeatable];
}

class DialogLine extends Equatable {
  final String speaker;
  final String text;
  final List<DialogChoice>? choices;

  const DialogLine({required this.speaker, required this.text, this.choices});

  Map<String, dynamic> toJson() => {
        'speaker': speaker,
        'text': text,
        'choices': choices?.map((c) => c.toJson()).toList(),
      };

  factory DialogLine.fromJson(Map<String, dynamic> json) {
    return DialogLine(
      speaker: json['speaker'] as String,
      text: json['text'] as String,
      choices: (json['choices'] as List?)?.map((j) => DialogChoice.fromJson(j)).toList(),
    );
  }

  @override
  List<Object?> get props => [speaker, text, choices];
}

class DialogChoice extends Equatable {
  final String text;
  final String? setVariable;
  final dynamic setValue;
  final String? jumpToSceneId;

  const DialogChoice({required this.text, this.setVariable, this.setValue, this.jumpToSceneId});

  Map<String, dynamic> toJson() => {
        'text': text,
        'setVariable': setVariable,
        'setValue': setValue,
        'jumpToSceneId': jumpToSceneId,
      };

  factory DialogChoice.fromJson(Map<String, dynamic> json) {
    return DialogChoice(
      text: json['text'] as String,
      setVariable: json['setVariable'] as String?,
      setValue: json['setValue'],
      jumpToSceneId: json['jumpToSceneId'] as String?,
    );
  }

  @override
  List<Object?> get props => [text, setVariable, setValue, jumpToSceneId];
}

class StaticBehavior extends EntityBehavior {
  final bool isPickup;
  final String? variableName;
  final int incrementAmount;
  final bool destroyOnPickup;

  const StaticBehavior({
    this.isPickup = false,
    this.variableName,
    this.incrementAmount = 1,
    this.destroyOnPickup = true,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'static',
        'isPickup': isPickup,
        'variableName': variableName,
        'incrementAmount': incrementAmount,
        'destroyOnPickup': destroyOnPickup,
      };

  factory StaticBehavior.fromJson(Map<String, dynamic> json) {
    return StaticBehavior(
      isPickup: json['isPickup'] as bool? ?? false,
      variableName: json['variableName'] as String?,
      incrementAmount: json['incrementAmount'] as int? ?? 1,
      destroyOnPickup: json['destroyOnPickup'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [isPickup, variableName, incrementAmount, destroyOnPickup];
}

class ProjectileBehavior extends EntityBehavior {
  final double speed;
  final double lifetime;
  final int damage;

  const ProjectileBehavior({
    this.speed = 300.0,
    this.lifetime = 2.0,
    this.damage = 10,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'projectile',
        'speed': speed,
        'lifetime': lifetime,
        'damage': damage,
      };

  factory ProjectileBehavior.fromJson(Map<String, dynamic> json) {
    return ProjectileBehavior(
      speed: (json['speed'] as num?)?.toDouble() ?? 300.0,
      lifetime: (json['lifetime'] as num?)?.toDouble() ?? 2.0,
      damage: json['damage'] as int? ?? 10,
    );
  }

  @override
  List<Object?> get props => [speed, lifetime, damage];
}

class GridMovementBehavior extends EntityBehavior {
  final double speed; // Tiles per second

  const GridMovementBehavior({this.speed = 4.0});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gridMovement',
        'speed': speed,
      };

  factory GridMovementBehavior.fromJson(Map<String, dynamic> json) {
    return GridMovementBehavior(
      speed: (json['speed'] as num?)?.toDouble() ?? 4.0,
    );
  }

  @override
  List<Object?> get props => [speed];
}

class InteractableBehavior extends EntityBehavior {
  final String triggerAction; // e.g., 'dialog', 'battle'
  final String targetId; // Reference to what to trigger

  const InteractableBehavior({
    required this.triggerAction,
    this.targetId = '',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'interactable',
        'triggerAction': triggerAction,
        'targetId': targetId,
      };

  factory InteractableBehavior.fromJson(Map<String, dynamic> json) {
    return InteractableBehavior(
      triggerAction: json['triggerAction'] as String? ?? 'dialog',
      targetId: json['targetId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [triggerAction, targetId];
}
