// {@template frame_placement}
// Describes the position and dimensions of a single frame within a
// packed sprite-sheet atlas.
//
// When a frame has been trimmed, [trimmed] is `true` and
// [spriteSourceX] / [spriteSourceY] record the pixel offset of the
// trimmed region relative to the original frame's top-left corner.
// [sourceWidth] and [sourceHeight] always reflect the **original**
// (un-trimmed) dimensions so that consumers can reconstruct the full
// frame if needed.
// {@endtemplate}
import 'package:equatable/equatable.dart';

/// The placement of a single frame in the packed atlas.
class FramePlacement extends Equatable {
  /// Creates a [FramePlacement].
  ///
  /// * [frameId] — UUID of the corresponding [SpriteFrame].
  /// * [frameName] — human-readable name (usually the original filename).
  /// * [x], [y] — top-left position in the atlas canvas.
  /// * [width], [height] — dimensions of the placed region.
  /// * [trimmed] — whether transparent edges were removed.
  /// * [sourceWidth], [sourceHeight] — original image dimensions.
  /// * [spriteSourceX], [spriteSourceY] — offset of the trimmed region
  ///   within the original image.
  const FramePlacement({
    required this.frameId,
    required this.frameName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.trimmed = false,
    required this.sourceWidth,
    required this.sourceHeight,
    this.spriteSourceX = 0,
    this.spriteSourceY = 0,
  });

  /// UUID of the source [SpriteFrame].
  final String frameId;

  /// Human-readable frame name (e.g. original filename).
  final String frameName;

  /// Horizontal position (px) in the atlas.
  final int x;

  /// Vertical position (px) in the atlas.
  final int y;

  /// Width of the placed region (px).
  final int width;

  /// Height of the placed region (px).
  final int height;

  /// Whether this frame was trimmed before packing.
  final bool trimmed;

  /// Original (un-trimmed) image width (px).
  final int sourceWidth;

  /// Original (un-trimmed) image height (px).
  final int sourceHeight;

  /// Horizontal offset of the trimmed region within the original image.
  final int spriteSourceX;

  /// Vertical offset of the trimmed region within the original image.
  final int spriteSourceY;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'frameId': frameId,
        'frameName': frameName,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'trimmed': trimmed,
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
        'spriteSourceX': spriteSourceX,
        'spriteSourceY': spriteSourceY,
      };

  factory FramePlacement.fromJson(Map<String, dynamic> json) {
    return FramePlacement(
      frameId: json['frameId'] as String,
      frameName: json['frameName'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      trimmed: json['trimmed'] as bool? ?? false,
      sourceWidth: json['sourceWidth'] as int,
      sourceHeight: json['sourceHeight'] as int,
      spriteSourceX: json['spriteSourceX'] as int? ?? 0,
      spriteSourceY: json['spriteSourceY'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        frameId,
        frameName,
        x,
        y,
        width,
        height,
        trimmed,
        sourceWidth,
        sourceHeight,
        spriteSourceX,
        spriteSourceY,
      ];

  @override
  String toString() =>
      'FramePlacement($frameName @ ($x, $y) ${width}x$height)';
}
