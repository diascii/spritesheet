// {@template sprite_frame}
// A single sprite image imported into the packer workspace.
//
// Each frame carries its raw decoded RGBA pixels ([imageBytes]), an
// optional [trimRect] describing the bounding box of non-transparent
// content, and a content [hash] (SHA-256) used for duplicate detection.
//
// **Equality** is based on [id], [name], [width], [height], [hash],
// and [order] — *not* on [imageBytes] or [trimRect], because byte-level
// comparison would be prohibitively expensive for large sprite sets.
// {@endtemplate}
import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'int_rect.dart';

/// Represents a single sprite frame in the packer workspace.
class SpriteFrame extends Equatable {
  /// Creates a [SpriteFrame].
  ///
  /// * [id] — a UUID that uniquely identifies this frame.
  /// * [name] — original file name (without path).
  /// * [width], [height] — pixel dimensions of the source image.
  /// * [imageBytes] — raw decoded RGBA pixel data.
  /// * [trimRect] — optional tight bounding box of non-transparent pixels.
  /// * [hash] — SHA-256 hex string of [imageBytes].
  /// * [order] — explicit sort order, defaults to `0`.
  const SpriteFrame({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.imageBytes,
    this.trimRect,
    required this.hash,
    this.order = 0,
    this.tag,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Original file name of the imported image.
  final String name;

  /// Width of the source image in pixels.
  final int width;

  /// Height of the source image in pixels.
  final int height;

  /// Raw decoded RGBA pixel data.
  ///
  /// The length is always `width * height * 4`.
  final Uint8List imageBytes;

  /// Bounding box of non-transparent pixels, or `null` if the frame has
  /// not been trimmed (or is fully transparent).
  final IntRect? trimRect;

  /// SHA-256 hex digest of [imageBytes], used for duplicate detection.
  final String hash;

  /// Explicit sort order. Frames are packed in ascending [order].
  final int order;

  /// Optional tag representing the animation state (e.g. 'Idle', 'Run').
  final String? tag;

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// Alias for [width] — the full source width.
  int get sourceWidth => width;

  /// Alias for [height] — the full source height.
  int get sourceHeight => height;

  /// Width used for atlas placement: the trimmed width if available,
  /// otherwise the full source width.
  int get effectiveWidth => trimRect?.width ?? width;

  /// Height used for atlas placement: the trimmed height if available,
  /// otherwise the full source height.
  int get effectiveHeight => trimRect?.height ?? height;

  /// Whether this frame has been trimmed (i.e. [trimRect] is set).
  bool get isTrimmed => trimRect != null;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Returns a copy of this frame with the given fields replaced.
  ///
  /// Set [clearTrimRect] to `true` to explicitly set [trimRect] to `null`,
  /// since passing `null` for [trimRect] would otherwise be interpreted as
  /// "keep the existing value".
  SpriteFrame copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    Uint8List? imageBytes,
    IntRect? trimRect,
    bool clearTrimRect = false,
    String? hash,
    int? order,
    String? tag,
    bool clearTag = false,
  }) {
    return SpriteFrame(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      imageBytes: imageBytes ?? this.imageBytes,
      trimRect: clearTrimRect ? null : (trimRect ?? this.trimRect),
      hash: hash ?? this.hash,
      order: order ?? this.order,
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'imageBytes': base64Encode(imageBytes),
        'trimRect': trimRect?.toJson(),
        'hash': hash,
        'order': order,
        if (tag != null) 'tag': tag,
      };

  factory SpriteFrame.fromJson(Map<String, dynamic> json) {
    return SpriteFrame(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      imageBytes: base64Decode(json['imageBytes'] as String),
      trimRect: json['trimRect'] != null
          ? IntRect.fromJson(json['trimRect'] as Map<String, dynamic>)
          : null,
      hash: json['hash'] as String,
      order: json['order'] as int? ?? 0,
      tag: json['tag'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  /// Props used for equality — intentionally excludes [imageBytes] and
  /// [trimRect] for performance reasons.
  @override
  List<Object?> get props => [id, name, width, height, hash, order, tag];

  @override
  String toString() =>
      'SpriteFrame(id: $id, name: $name, ${width}x$height, order: $order, tag: $tag)';
}
