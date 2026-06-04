// {@template sheet_config}
// User-configurable settings that control how sprite frames are packed
// into an atlas.
//
// Validation rules:
// * [sheetName] must not be empty.
// * [maxTextureSize] must be either `2048` or `4096`.
// * [framePadding] must be in the range `0` – `16`.
// {@endtemplate}
import 'package:equatable/equatable.dart';

/// Configuration for the sprite-sheet packing process.
class SheetConfig extends Equatable {
  /// Creates a [SheetConfig] with sensible defaults.
  const SheetConfig({
    this.sheetName = 'spritesheet',
    this.maxTextureSize = 2048,
    this.framePadding = 1,
    this.trimEnabled = true,
    this.targetEngine = 'flame',
  });

  /// Base name used for the exported atlas image and JSON files.
  final String sheetName;

  /// Maximum width **and** height of the atlas texture in pixels.
  ///
  /// Must be either `2048` or `4096` to remain compatible with common
  /// GPU texture-size limits.
  final int maxTextureSize;

  /// Padding (in pixels) inserted between adjacent frames in the atlas.
  ///
  /// Valid range: `0` – `16`.
  final int framePadding;

  /// Whether to trim transparent edges from frames before packing.
  final bool trimEnabled;

  /// Identifier of the target game engine (e.g. `'flame'`, `'unity'`).
  ///
  /// Determines the format of the exported JSON metadata.
  final String targetEngine;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns `true` when all fields satisfy their constraints.
  ///
  /// * [sheetName] is not empty.
  /// * [maxTextureSize] is `2048` or `4096`.
  /// * [framePadding] is in `0` – `16`.
  bool get isValid =>
      sheetName.isNotEmpty &&
      (maxTextureSize == 2048 || maxTextureSize == 4096) &&
      framePadding >= 0 &&
      framePadding <= 16;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  SheetConfig copyWith({
    String? sheetName,
    int? maxTextureSize,
    int? framePadding,
    bool? trimEnabled,
    String? targetEngine,
  }) {
    return SheetConfig(
      sheetName: sheetName ?? this.sheetName,
      maxTextureSize: maxTextureSize ?? this.maxTextureSize,
      framePadding: framePadding ?? this.framePadding,
      trimEnabled: trimEnabled ?? this.trimEnabled,
      targetEngine: targetEngine ?? this.targetEngine,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'sheetName': sheetName,
        'maxTextureSize': maxTextureSize,
        'framePadding': framePadding,
        'trimEnabled': trimEnabled,
        'targetEngine': targetEngine,
      };

  factory SheetConfig.fromJson(Map<String, dynamic> json) {
    return SheetConfig(
      sheetName: json['sheetName'] as String? ?? 'spritesheet',
      maxTextureSize: json['maxTextureSize'] as int? ?? 2048,
      framePadding: json['framePadding'] as int? ?? 1,
      trimEnabled: json['trimEnabled'] as bool? ?? true,
      targetEngine: json['targetEngine'] as String? ?? 'flame',
    );
  }

  @override
  List<Object?> get props => [
        sheetName,
        maxTextureSize,
        framePadding,
        trimEnabled,
        targetEngine,
      ];

  @override
  String toString() =>
      'SheetConfig($sheetName, max: $maxTextureSize, pad: $framePadding, '
      'trim: $trimEnabled, engine: $targetEngine)';
}
