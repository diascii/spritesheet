// {@template frame_annotation}
// Groups all hitbox-painter metadata for a single sprite frame.
//
// Each frame may optionally have an [anchor] point and zero or more
// [hitboxes]. Annotations are stored separately from the image data
// ([SpriteFrame]) so they can be edited, exported, and versioned
// independently.
// {@endtemplate}
import 'package:equatable/equatable.dart';

import 'anchor_data.dart';
import 'hitbox_data.dart';

/// Hitbox and anchor annotation data for a single frame.
class FrameAnnotation extends Equatable {
  /// Creates a [FrameAnnotation].
  ///
  /// * [frameId] — UUID of the associated [SpriteFrame].
  /// * [anchor] — optional pivot / registration point.
  /// * [hitboxes] — list of hitbox definitions (may be empty).
  const FrameAnnotation({
    required this.frameId,
    this.anchor,
    this.hitboxes = const <HitboxData>[],
  });

  /// UUID of the associated [SpriteFrame].
  final String frameId;

  /// Optional anchor / pivot point for this frame.
  ///
  /// `null` when the user has not yet placed an anchor.
  final AnchorData? anchor;

  /// Hitbox definitions attached to this frame.
  final List<HitboxData> hitboxes;

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns `true` when this annotation carries any meaningful data
  /// (i.e. an anchor is set or at least one hitbox exists).
  bool get hasData => anchor != null || hitboxes.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  /// Returns a copy with the given fields replaced.
  ///
  /// Set [clearAnchor] to `true` to explicitly remove the anchor,
  /// because passing `null` for [anchor] is interpreted as "keep the
  /// existing value".
  FrameAnnotation copyWith({
    String? frameId,
    AnchorData? anchor,
    bool clearAnchor = false,
    List<HitboxData>? hitboxes,
  }) {
    return FrameAnnotation(
      frameId: frameId ?? this.frameId,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
      hitboxes: hitboxes ?? this.hitboxes,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'frameId': frameId,
        'anchor': anchor?.toJson(),
        'hitboxes': hitboxes.map((h) => h.toJson()).toList(),
      };

  factory FrameAnnotation.fromJson(Map<String, dynamic> json) {
    return FrameAnnotation(
      frameId: json['frameId'] as String,
      anchor: json['anchor'] != null
          ? AnchorData.fromJson(json['anchor'] as Map<String, dynamic>)
          : null,
      hitboxes: (json['hitboxes'] as List?)
              ?.map((e) => HitboxData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [frameId, anchor, hitboxes];

  @override
  String toString() =>
      'FrameAnnotation(frameId: $frameId, anchor: $anchor, '
      '${hitboxes.length} hitboxes)';
}
