// {@template int_rect}
// An immutable, pure-Dart integer rectangle.
//
// Used throughout the sprite-sheet packer to represent pixel-aligned
// bounding boxes (trim rects, atlas regions, etc.) without depending
// on `dart:ui` or any Flutter imports.
// {@endtemplate}
import 'package:equatable/equatable.dart';

/// An axis-aligned rectangle whose position and size are expressed as
/// integers.
///
/// The origin ([x], [y]) is the **top-left** corner. [width] and
/// [height] extend rightward and downward respectively.
class IntRect extends Equatable {
  /// Creates an [IntRect] from its top-left corner and size.
  ///
  /// [width] and [height] must be non-negative.
  const IntRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  })  : assert(width >= 0, 'width must be non-negative'),
        assert(height >= 0, 'height must be non-negative');

  /// Horizontal position of the top-left corner in pixels.
  final int x;

  /// Vertical position of the top-left corner in pixels.
  final int y;

  /// Width of the rectangle in pixels (≥ 0).
  final int width;

  /// Height of the rectangle in pixels (≥ 0).
  final int height;

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// The x-coordinate of the right edge (exclusive).
  int get right => x + width;

  /// The y-coordinate of the bottom edge (exclusive).
  int get bottom => y + height;

  /// Total area in square pixels.
  int get area => width * height;

  // ---------------------------------------------------------------------------
  // Geometric queries
  // ---------------------------------------------------------------------------

  /// Returns `true` if this rectangle overlaps [other].
  ///
  /// Two rectangles that share only an edge (zero-area overlap) are
  /// **not** considered overlapping.
  bool overlaps(IntRect other) {
    return x < other.right &&
        right > other.x &&
        y < other.bottom &&
        bottom > other.y;
  }

  /// Returns `true` if the point ([px], [py]) lies inside this rectangle.
  ///
  /// Points on the top and left edges are included; points on the right
  /// and bottom edges are excluded.
  bool contains(int px, int py) {
    return px >= x && px < right && py >= y && py < bottom;
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  factory IntRect.fromJson(Map<String, dynamic> json) {
    return IntRect(
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  @override
  List<Object?> get props => [x, y, width, height];

  @override
  String toString() => 'IntRect(x: $x, y: $y, w: $width, h: $height)';
}
