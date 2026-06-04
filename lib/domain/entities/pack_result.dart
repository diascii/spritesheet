// {@template pack_result}
// The result of running the rectangle-packing algorithm on a set of
// sprite frames.
//
// Contains all [placements] with their atlas coordinates, the final
// [canvasWidth] × [canvasHeight], and an optional list of
// [overflowFrameIds] for frames that did not fit within the maximum
// texture size.
//
// When multi-page packing is supported, [pageIndex] identifies which
// atlas page this result belongs to.
// {@endtemplate}
import 'package:equatable/equatable.dart';

import 'frame_placement.dart';

/// Result of a single atlas packing pass.
class PackResult extends Equatable {
  /// Creates a [PackResult].
  const PackResult({
    required this.placements,
    required this.canvasWidth,
    required this.canvasHeight,
    this.pageIndex = 0,
    this.overflowFrameIds = const <String>[],
  });

  /// Ordered list of frame placements within the atlas.
  final List<FramePlacement> placements;

  /// Width of the packed atlas canvas in pixels.
  final int canvasWidth;

  /// Height of the packed atlas canvas in pixels.
  final int canvasHeight;

  /// Zero-based page index when using multi-page packing.
  final int pageIndex;

  /// IDs of frames that could not fit within the maximum texture size.
  ///
  /// Empty when all frames were placed successfully.
  final List<String> overflowFrameIds;

  // ---------------------------------------------------------------------------
  // Derived metrics
  // ---------------------------------------------------------------------------

  /// Total area of the atlas canvas in square pixels.
  int get totalArea => canvasWidth * canvasHeight;

  /// Sum of the areas of all placed frames.
  int get usedArea => placements.fold<int>(
        0,
        (sum, p) => sum + p.width * p.height,
      );

  /// Packing efficiency as a ratio in the range `0.0` – `1.0`.
  ///
  /// A value of `1.0` means every pixel in the atlas is occupied by a
  /// placed frame. Returns `0.0` when [totalArea] is zero.
  double get efficiency => totalArea == 0 ? 0.0 : usedArea / totalArea;

  /// Whether any frames overflowed (did not fit in the atlas).
  bool get hasOverflow => overflowFrameIds.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'placements': placements.map((p) => p.toJson()).toList(),
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'pageIndex': pageIndex,
        'overflowFrameIds': overflowFrameIds,
      };

  factory PackResult.fromJson(Map<String, dynamic> json) {
    return PackResult(
      placements: (json['placements'] as List?)
              ?.map((e) => FramePlacement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      canvasWidth: json['canvasWidth'] as int,
      canvasHeight: json['canvasHeight'] as int,
      pageIndex: json['pageIndex'] as int? ?? 0,
      overflowFrameIds: (json['overflowFrameIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  List<Object?> get props => [
        placements,
        canvasWidth,
        canvasHeight,
        pageIndex,
        overflowFrameIds,
      ];

  @override
  String toString() =>
      'PackResult(page: $pageIndex, ${canvasWidth}x$canvasHeight, '
      '${placements.length} placed, ${overflowFrameIds.length} overflow)';
}
