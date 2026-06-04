import 'dart:math' as math;

/// A simple axis-aligned rectangle used internally by the packing algorithm.
///
/// Stores integer coordinates and dimensions. Immutable after construction.
class PackRect {
  /// The x-coordinate of the rectangle's left edge.
  final int x;

  /// The y-coordinate of the rectangle's top edge.
  final int y;

  /// The width of the rectangle in pixels.
  final int width;

  /// The height of the rectangle in pixels.
  final int height;

  /// Creates a [PackRect] with the given position and dimensions.
  const PackRect(this.x, this.y, this.width, this.height);

  /// The x-coordinate of the rectangle's right edge (exclusive).
  int get right => x + width;

  /// The y-coordinate of the rectangle's bottom edge (exclusive).
  int get bottom => y + height;

  /// The total area of this rectangle in pixels².
  int get area => width * height;

  @override
  String toString() => 'PackRect($x, $y, $width, $height)';
}

/// An input rectangle to be placed by the bin packing algorithm.
///
/// Each input rect carries a unique [id] so callers can correlate placed
/// results back to their original sprite data.
class InputRect {
  /// A unique identifier for this rectangle (e.g. the sprite name).
  final String id;

  /// The width of the rectangle in pixels.
  final int width;

  /// The height of the rectangle in pixels.
  final int height;

  /// Creates an [InputRect] with the given [id], [width], and [height].
  const InputRect({
    required this.id,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'InputRect($id, $width×$height)';
}

/// A rectangle that has been successfully placed within the bin.
///
/// Contains the original [id] plus the computed position ([x], [y]) and
/// dimensions ([width], [height]).
class PlacedRect {
  /// The identifier matching the original [InputRect.id].
  final String id;

  /// The x-coordinate where this rectangle was placed.
  final int x;

  /// The y-coordinate where this rectangle was placed.
  final int y;

  /// The width of the placed rectangle.
  final int width;

  /// The height of the placed rectangle.
  final int height;

  /// Creates a [PlacedRect] with the given placement data.
  const PlacedRect({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'PlacedRect($id, $x, $y, $width×$height)';
}

/// The placement heuristic used to select the best free rectangle for each
/// incoming sprite.
///
/// Each heuristic produces a two-component score; the combination with the
/// lowest primary score (then lowest secondary) wins.
enum PackHeuristic {
  /// Best Short Side Fit — minimises the shorter leftover side.
  bestShortSideFit,

  /// Best Long Side Fit — minimises the longer leftover side.
  bestLongSideFit,

  /// Best Area Fit — minimises wasted area in the chosen free rectangle.
  bestAreaFit,

  /// Bottom-Left — places rectangles as close to the top-left origin as
  /// possible (lowest y first, then lowest x).
  bottomLeft,
}

/// The result of a bin packing operation.
///
/// Contains all successfully [placed] rectangles, a list of [failed] IDs that
/// could not fit, and the tightly-bounded [canvasWidth] / [canvasHeight].
class PackOutput {
  /// The rectangles that were successfully placed.
  final List<PlacedRect> placed;

  /// The IDs of input rectangles that could not be placed.
  final List<String> failed;

  /// The minimal canvas width that tightly bounds all placed rectangles.
  final int canvasWidth;

  /// The minimal canvas height that tightly bounds all placed rectangles.
  final int canvasHeight;

  /// Creates a [PackOutput] with the given results.
  const PackOutput({
    required this.placed,
    required this.failed,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  String toString() =>
      'PackOutput(placed: ${placed.length}, failed: ${failed.length}, '
      '$canvasWidth×$canvasHeight)';
}

/// A MaxRects 2-D bin packing implementation.
///
/// Based on the MAXRECTS algorithm described in
/// *"A Thousand Ways to Pack the Bin — A Practical Approach to
/// Two-Dimensional Rectangle Bin Packing"* by Jukka Jylänki (2010).
///
/// The algorithm maintains a list of maximal free rectangles that describe
/// the remaining empty space inside the bin. When a new rectangle is placed,
/// every free rectangle that overlaps with it is split into up to four
/// non-overlapping sub-rectangles, and any free rectangle that is fully
/// contained within another is pruned away.
///
/// Usage:
/// ```dart
/// final output = MaxRectsBinPack.pack(
///   [InputRect(id: 'a', width: 64, height: 64)],
///   256, 256,
/// );
/// ```
///
/// This is a **pure Dart** class with no Flutter or `dart:ui` dependencies.
class MaxRectsBinPack {
  /// The total width of the bin in pixels.
  final int binWidth;

  /// The total height of the bin in pixels.
  final int binHeight;

  /// Rectangles that have already been placed into the bin.
  final List<PackRect> _usedRects = [];

  /// Maximal free rectangles representing the remaining empty space.
  final List<PackRect> _freeRects = [];

  /// Creates a [MaxRectsBinPack] with the given bin dimensions.
  ///
  /// The free-rect list is initialised with a single rectangle spanning the
  /// entire bin.
  MaxRectsBinPack(this.binWidth, this.binHeight) {
    _freeRects.add(PackRect(0, 0, binWidth, binHeight));
  }

  // ---------------------------------------------------------------------------
  // Public static entry point
  // ---------------------------------------------------------------------------

  /// Packs the given [rects] into a bin of size [binWidth] × [binHeight].
  ///
  /// Returns a [PackOutput] containing all placed rectangles, any IDs that
  /// failed to fit, and the tightly-bounded canvas dimensions.
  ///
  /// The optional [heuristic] controls how the algorithm selects the best
  /// free rectangle for each input rect. Defaults to
  /// [PackHeuristic.bestShortSideFit].
  static PackOutput pack(
    List<InputRect> rects,
    int binWidth,
    int binHeight, {
    PackHeuristic heuristic = PackHeuristic.bestShortSideFit,
  }) {
    final packer = MaxRectsBinPack(binWidth, binHeight);
    final remaining = List<InputRect>.of(rects);
    final placed = <PlacedRect>[];
    final failed = <String>[];

    while (remaining.isNotEmpty) {
      // Track the best candidate across all remaining rects × free rects.
      int bestScore1 = _maxInt;
      int bestScore2 = _maxInt;
      int bestRectIndex = -1;
      PackRect? bestNode;

      for (int i = 0; i < remaining.length; i++) {
        final input = remaining[i];
        final (node, score1, score2) = packer._findBest(
          input.width,
          input.height,
          heuristic,
        );

        if (node != null &&
            (score1 < bestScore1 ||
                (score1 == bestScore1 && score2 < bestScore2))) {
          bestScore1 = score1;
          bestScore2 = score2;
          bestRectIndex = i;
          bestNode = node;
        }
      }

      // No valid placement found — all remaining rects fail.
      if (bestRectIndex == -1 || bestNode == null) {
        for (final r in remaining) {
          failed.add(r.id);
        }
        break;
      }

      // Place the winning rect.
      final winner = remaining.removeAt(bestRectIndex);
      placed.add(PlacedRect(
        id: winner.id,
        x: bestNode.x,
        y: bestNode.y,
        width: bestNode.width,
        height: bestNode.height,
      ));
      packer._placeRect(bestNode);
    }

    // Compute tight bounding box.
    int canvasWidth = 0;
    int canvasHeight = 0;
    for (final p in placed) {
      canvasWidth = math.max(canvasWidth, p.x + p.width);
      canvasHeight = math.max(canvasHeight, p.y + p.height);
    }

    return PackOutput(
      placed: placed,
      failed: failed,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// A sentinel "infinite" score used for comparisons.
  static const int _maxInt = 0x1FFFFFFFFFFFFF; // max JS safe integer

  /// Finds the best free rectangle for an item of [width] × [height] using the
  /// given [heuristic].
  ///
  /// Returns a tuple of (bestNode, primaryScore, secondaryScore). If no free
  /// rect can fit the item, returns `(null, _maxInt, _maxInt)`.
  (PackRect?, int, int) _findBest(
    int width,
    int height,
    PackHeuristic heuristic,
  ) {
    int bestScore1 = _maxInt;
    int bestScore2 = _maxInt;
    PackRect? bestNode;

    for (final freeRect in _freeRects) {
      // Check if the rect fits (no rotation).
      if (width <= freeRect.width && height <= freeRect.height) {
        final (s1, s2) = _score(width, height, freeRect, heuristic);
        if (s1 < bestScore1 || (s1 == bestScore1 && s2 < bestScore2)) {
          bestScore1 = s1;
          bestScore2 = s2;
          bestNode = PackRect(freeRect.x, freeRect.y, width, height);
        }
      }
    }

    return (bestNode, bestScore1, bestScore2);
  }

  /// Dispatches to the correct scoring function for the given [heuristic].
  (int, int) _score(
    int width,
    int height,
    PackRect freeRect,
    PackHeuristic heuristic,
  ) {
    return switch (heuristic) {
      PackHeuristic.bestShortSideFit => _scoreBSSF(width, height, freeRect),
      PackHeuristic.bestLongSideFit => _scoreBLSF(width, height, freeRect),
      PackHeuristic.bestAreaFit => _scoreBAF(width, height, freeRect),
      PackHeuristic.bottomLeft => _scoreBL(width, height, freeRect),
    };
  }

  /// Best Short Side Fit.
  ///
  /// Primary: min of the two leftover side differences.
  /// Secondary: max of the two leftover side differences.
  (int, int) _scoreBSSF(int width, int height, PackRect freeRect) {
    final leftoverH = (freeRect.width - width).abs();
    final leftoverV = (freeRect.height - height).abs();
    return (math.min(leftoverH, leftoverV), math.max(leftoverH, leftoverV));
  }

  /// Best Long Side Fit.
  ///
  /// Primary: max of the two leftover side differences.
  /// Secondary: min of the two leftover side differences.
  (int, int) _scoreBLSF(int width, int height, PackRect freeRect) {
    final leftoverH = (freeRect.width - width).abs();
    final leftoverV = (freeRect.height - height).abs();
    return (math.max(leftoverH, leftoverV), math.min(leftoverH, leftoverV));
  }

  /// Best Area Fit.
  ///
  /// Primary: wasted area (free rect area minus item area).
  /// Secondary: min of the two leftover side differences.
  (int, int) _scoreBAF(int width, int height, PackRect freeRect) {
    final areaFit = freeRect.area - width * height;
    final leftoverH = (freeRect.width - width).abs();
    final leftoverV = (freeRect.height - height).abs();
    return (areaFit, math.min(leftoverH, leftoverV));
  }

  /// Bottom-Left heuristic.
  ///
  /// Primary: y-coordinate of the free rect (prefer top of canvas / lower y).
  /// Secondary: x-coordinate of the free rect.
  (int, int) _scoreBL(int width, int height, PackRect freeRect) {
    return (freeRect.y, freeRect.x);
  }

  /// Records [node] as a placed rectangle and updates the free-rect list.
  ///
  /// Every existing free rectangle that overlaps with [node] is split into
  /// up to four non-overlapping sub-rectangles. Afterwards, any free rect
  /// fully contained within another is pruned.
  void _placeRect(PackRect node) {
    _usedRects.add(node);

    // Split every free rect that overlaps with the placed node.
    final newFreeRects = <PackRect>[];
    for (final freeRect in _freeRects) {
      newFreeRects.addAll(_splitFreeRect(freeRect, node));
    }
    _freeRects
      ..clear()
      ..addAll(newFreeRects);

    _pruneFreeRects();
  }

  /// Splits [freeRect] around [placedRect] and returns the resulting pieces.
  ///
  /// If the two rectangles do not overlap, [freeRect] is returned unchanged.
  /// Otherwise, up to four axis-aligned strips are carved from the
  /// non-overlapping portions of [freeRect]. Only strips with positive width
  /// **and** height are included.
  List<PackRect> _splitFreeRect(PackRect freeRect, PackRect placedRect) {
    // No overlap check — if they don't intersect, keep the free rect as-is.
    if (placedRect.x >= freeRect.right ||
        placedRect.right <= freeRect.x ||
        placedRect.y >= freeRect.bottom ||
        placedRect.bottom <= freeRect.y) {
      return [freeRect];
    }

    final result = <PackRect>[];

    // Left strip: portion of freeRect to the left of placedRect.
    if (placedRect.x > freeRect.x) {
      final w = placedRect.x - freeRect.x;
      if (w > 0 && freeRect.height > 0) {
        result.add(PackRect(freeRect.x, freeRect.y, w, freeRect.height));
      }
    }

    // Right strip: portion of freeRect to the right of placedRect.
    if (placedRect.right < freeRect.right) {
      final newX = placedRect.right;
      final w = freeRect.right - newX;
      if (w > 0 && freeRect.height > 0) {
        result.add(PackRect(newX, freeRect.y, w, freeRect.height));
      }
    }

    // Top strip: portion of freeRect above placedRect.
    if (placedRect.y > freeRect.y) {
      final h = placedRect.y - freeRect.y;
      if (freeRect.width > 0 && h > 0) {
        result.add(PackRect(freeRect.x, freeRect.y, freeRect.width, h));
      }
    }

    // Bottom strip: portion of freeRect below placedRect.
    if (placedRect.bottom < freeRect.bottom) {
      final newY = placedRect.bottom;
      final h = freeRect.bottom - newY;
      if (freeRect.width > 0 && h > 0) {
        result.add(PackRect(freeRect.x, newY, freeRect.width, h));
      }
    }

    return result;
  }

  /// Removes any free rectangle that is fully contained within another.
  ///
  /// This is an O(n²) pass but the free-rect count stays manageable in
  /// practice because the algorithm continuously consolidates overlapping
  /// regions.
  void _pruneFreeRects() {
    for (int i = 0; i < _freeRects.length; i++) {
      for (int j = i + 1; j < _freeRects.length; j++) {
        if (_isContainedIn(_freeRects[i], _freeRects[j])) {
          _freeRects.removeAt(i);
          i--;
          break;
        }
        if (_isContainedIn(_freeRects[j], _freeRects[i])) {
          _freeRects.removeAt(j);
          j--;
        }
      }
    }
  }

  /// Returns `true` if [inner] is fully contained within [outer].
  static bool _isContainedIn(PackRect inner, PackRect outer) {
    return inner.x >= outer.x &&
        inner.y >= outer.y &&
        inner.right <= outer.right &&
        inner.bottom <= outer.bottom;
  }
}
