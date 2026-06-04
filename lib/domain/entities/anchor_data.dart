// {@template anchor_data}
// A normalised anchor (pivot / registration) point for a sprite frame.
//
// Coordinates are expressed in the range `0.0` – `1.0`, where
// `(0.0, 0.0)` is the top-left corner and `(1.0, 1.0)` is the
// bottom-right corner of the frame.
//
// The anchor is the point around which the sprite is positioned and
// rotated at runtime.
// {@endtemplate}
import 'package:equatable/equatable.dart';

/// Normalised anchor / pivot point for a sprite frame.
class AnchorData extends Equatable {
  /// Creates an [AnchorData] with the given normalised coordinates.
  const AnchorData({
    required this.x,
    required this.y,
  });

  /// Normalised x-coordinate (0.0 – 1.0).
  final double x;

  /// Normalised y-coordinate (0.0 – 1.0).
  final double y;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns `true` when both [x] and [y] lie within `[0.0, 1.0]`.
  bool get isValid => x >= 0.0 && x <= 1.0 && y >= 0.0 && y <= 1.0;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  AnchorData copyWith({
    double? x,
    double? y,
  }) {
    return AnchorData(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Converts this anchor to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  /// Creates an [AnchorData] from a JSON map.
  factory AnchorData.fromJson(Map<String, dynamic> json) {
    return AnchorData(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [x, y];

  @override
  String toString() => 'AnchorData($x, $y)';
}
