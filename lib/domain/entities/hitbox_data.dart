// {@template hitbox_type}
// The semantic type of a hitbox, each rendered with a distinct colour
// in the hitbox painter UI.
// {@endtemplate}
import 'package:equatable/equatable.dart';

/// Semantic hitbox categories.
///
/// Each type is associated with a distinct display colour in the
/// hitbox-painter overlay:
///
/// | Type     | Colour |
/// |----------|--------|
/// | [body]   | Green  |
/// | [attack] | Red    |
/// | [hurt]   | Blue   |
enum HitboxType {
  /// General collision boundary, rendered in **green**.
  body,

  /// Offensive hitbox (e.g. weapon swing), rendered in **red**.
  attack,

  /// Damage-receiving region, rendered in **blue**.
  hurt,
}

/// {@template hitbox_data}
/// An axis-aligned rectangular hitbox expressed in **normalised**
/// coordinates (0.0 – 1.0) relative to the sprite frame.
///
/// Normalised coordinates make the data resolution-independent, so the
/// same hitbox definitions work regardless of how the sprite is scaled
/// at runtime.
/// {@endtemplate}
class HitboxData extends Equatable {
  /// Creates a [HitboxData].
  ///
  /// * [id] — UUID that uniquely identifies this hitbox.
  /// * [type] — semantic category ([HitboxType]).
  /// * [x], [y] — top-left corner in normalised coordinates (0.0 – 1.0).
  /// * [w], [h] — width and height in normalised coordinates.
  const HitboxData({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Semantic type of this hitbox.
  final HitboxType type;

  /// Normalised x-coordinate of the top-left corner (0.0 – 1.0).
  final double x;

  /// Normalised y-coordinate of the top-left corner (0.0 – 1.0).
  final double y;

  /// Normalised width (0.0 – 1.0).
  final double w;

  /// Normalised height (0.0 – 1.0).
  final double h;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns `true` when all coordinates lie within the valid range
  /// `[0.0, 1.0]` and the hitbox does not extend beyond the frame
  /// boundary (i.e. `x + w <= 1.0` and `y + h <= 1.0`).
  bool get isValid =>
      x >= 0.0 &&
      x <= 1.0 &&
      y >= 0.0 &&
      y <= 1.0 &&
      w >= 0.0 &&
      w <= 1.0 &&
      h >= 0.0 &&
      h <= 1.0 &&
      x + w <= 1.0 &&
      y + h <= 1.0;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  HitboxData copyWith({
    String? id,
    HitboxType? type,
    double? x,
    double? y,
    double? w,
    double? h,
  }) {
    return HitboxData(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
    );
  }

  /// The [type] is serialised as its enum name (`body`, `attack`, `hurt`).
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
      };

  /// Creates a [HitboxData] from a JSON map.
  factory HitboxData.fromJson(Map<String, dynamic> json) {
    return HitboxData(
      id: json['id'] as String,
      type: HitboxType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HitboxType.body,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, type, x, y, w, h];

  @override
  String toString() => 'HitboxData(${type.name} @ ($x, $y) ${w}x$h)';
}
