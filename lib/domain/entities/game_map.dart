import 'package:equatable/equatable.dart';
import 'entity_behavior.dart';
import 'package:uuid/uuid.dart';

class MapLayer extends Equatable {
  final String id;
  final String name;
  final List<String?> tiles; // Array of SpriteFrame IDs, null if empty
  final List<bool> solids; // Array of booleans, true if solid

  const MapLayer({
    required this.id,
    required this.name,
    required this.tiles,
    required this.solids,
  });

  MapLayer copyWith({
    String? id,
    String? name,
    List<String?>? tiles,
    List<bool>? solids,
  }) {
    return MapLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      tiles: tiles ?? this.tiles,
      solids: solids ?? this.solids,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tiles': tiles,
      'solids': solids,
    };
  }

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    final tilesList = (json['tiles'] as List).map((e) => e as String?).toList();
    final solidsList = json['solids'] != null 
        ? (json['solids'] as List).map((e) => e as bool).toList()
        : List.filled(tilesList.length, false);
    return MapLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      tiles: tilesList,
      solids: solidsList,
    );
  }

  @override
  List<Object?> get props => [id, name, tiles, solids];
}

class MapEntity extends Equatable {
  final String id;
  final String frameId;
  final String type;
  final double x;
  final double y;
  final double hitboxWidth;
  final double hitboxHeight;
  final bool isSolid;
  final List<EntityBehavior> behaviors;

  const MapEntity({
    required this.id,
    required this.frameId,
    required this.type,
    required this.x,
    required this.y,
    this.hitboxWidth = 32.0,
    this.hitboxHeight = 32.0,
    this.isSolid = false,
    this.behaviors = const [],
  });

  MapEntity copyWith({
    String? id,
    String? frameId,
    String? type,
    double? x,
    double? y,
    double? hitboxWidth,
    double? hitboxHeight,
    bool? isSolid,
    List<EntityBehavior>? behaviors,
  }) {
    return MapEntity(
      id: id ?? this.id,
      frameId: frameId ?? this.frameId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      hitboxWidth: hitboxWidth ?? this.hitboxWidth,
      hitboxHeight: hitboxHeight ?? this.hitboxHeight,
      isSolid: isSolid ?? this.isSolid,
      behaviors: behaviors ?? this.behaviors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frameId': frameId,
      'type': type,
      'x': x,
      'y': y,
      'hitboxWidth': hitboxWidth,
      'hitboxHeight': hitboxHeight,
      'isSolid': isSolid,
      'behaviors': behaviors.map((b) => b.toJson()).toList(),
    };
  }

  factory MapEntity.fromJson(Map<String, dynamic> json) {
    return MapEntity(
      id: json['id'] as String,
      frameId: json['frameId'] as String,
      type: json['type'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      hitboxWidth: (json['hitboxWidth'] as num?)?.toDouble() ?? 32.0,
      hitboxHeight: (json['hitboxHeight'] as num?)?.toDouble() ?? 32.0,
      isSolid: json['isSolid'] as bool? ?? false,
      behaviors: json['behaviors'] != null
          ? (json['behaviors'] as List).map((b) => EntityBehavior.fromJson(b)).toList()
          : [],
    );
  }

  @override
  List<Object?> get props => [id, frameId, type, x, y, hitboxWidth, hitboxHeight, isSolid, behaviors];
}

class GameMap extends Equatable {
  final String id;
  final String name;
  final int width; // In tiles
  final int height; // In tiles
  final int tileSize; // In pixels (e.g., 16, 32)
  final List<MapLayer> layers;
  final List<MapEntity> entities;

  const GameMap({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.tileSize,
    required this.layers,
    required this.entities,
  });

  factory GameMap.create({
    required String name,
    required int width,
    required int height,
    required int tileSize,
  }) {
    return GameMap(
      id: const Uuid().v4(),
      name: name,
      width: width,
      height: height,
      tileSize: tileSize,
      layers: [
        MapLayer(
          id: const Uuid().v4(),
          name: 'Layer 1',
          tiles: List.filled(width * height, null),
          solids: List.filled(width * height, false),
        ),
      ],
      entities: [],
    );
  }

  GameMap copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    int? tileSize,
    List<MapLayer>? layers,
    List<MapEntity>? entities,
  }) {
    return GameMap(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      tileSize: tileSize ?? this.tileSize,
      layers: layers ?? this.layers,
      entities: entities ?? this.entities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'tileSize': tileSize,
      'layers': layers.map((e) => e.toJson()).toList(),
      'entities': entities.map((e) => e.toJson()).toList(),
    };
  }

  factory GameMap.fromJson(Map<String, dynamic> json) {
    return GameMap(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      tileSize: json['tileSize'] as int,
      layers: (json['layers'] as List).map((e) => MapLayer.fromJson(e)).toList(),
      entities: json['entities'] != null 
          ? (json['entities'] as List).map((e) => MapEntity.fromJson(e)).toList() 
          : [],
    );
  }

  @override
  List<Object?> get props => [id, name, width, height, tileSize, layers, entities];
}
