part of 'sprite_sheet_bloc.dart';

abstract class SpriteSheetEvent extends Equatable {
  const SpriteSheetEvent();

  @override
  List<Object?> get props => [];
}

class ImportFramesEvent extends SpriteSheetEvent {
  const ImportFramesEvent();
}

class PackSpritesEvent extends SpriteSheetEvent {
  final SheetConfig config;

  const PackSpritesEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ExportSheetEvent extends SpriteSheetEvent {
  final SheetConfig config;
  final String outputDirectory;

  const ExportSheetEvent({
    required this.config,
    required this.outputDirectory,
  });

  @override
  List<Object?> get props => [config, outputDirectory];
}

class UpdateConfigEvent extends SpriteSheetEvent {
  final SheetConfig config;

  const UpdateConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ClearFramesEvent extends SpriteSheetEvent {
  const ClearFramesEvent();
}

class ReorderFramesEvent extends SpriteSheetEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderFramesEvent({required this.oldIndex, required this.newIndex});

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class RemoveFrameEvent extends SpriteSheetEvent {
  final String frameId;

  const RemoveFrameEvent({required this.frameId});

  @override
  List<Object?> get props => [frameId];
}

class SetFrameTagEvent extends SpriteSheetEvent {
  final String frameId;
  final String? tag;

  const SetFrameTagEvent({required this.frameId, this.tag});

  @override
  List<Object?> get props => [frameId, tag];
}

class LoadProjectDataEvent extends SpriteSheetEvent {
  final List<SpriteFrame> frames;
  final List<FrameAnnotation> annotations;
  final List<ui.Color>? palette;

  const LoadProjectDataEvent({
    required this.frames,
    required this.annotations,
    this.palette,
  });

  @override
  List<Object?> get props => [frames, annotations, palette];
}

class SetAnchorEvent extends SpriteSheetEvent {
  final String frameId;
  final double x;
  final double y;

  const SetAnchorEvent({
    required this.frameId,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [frameId, x, y];
}

class ClearAnchorEvent extends SpriteSheetEvent {
  final String frameId;

  const ClearAnchorEvent({required this.frameId});

  @override
  List<Object?> get props => [frameId];
}

class AddHitboxEvent extends SpriteSheetEvent {
  final String frameId;
  final HitboxType type;
  final double x;
  final double y;
  final double w;
  final double h;

  const AddHitboxEvent({
    required this.frameId,
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  @override
  List<Object?> get props => [frameId, type, x, y, w, h];
}

class UpdateHitboxEvent extends SpriteSheetEvent {
  final String hitboxId;
  final HitboxType? type;
  final double? x;
  final double? y;
  final double? w;
  final double? h;

  const UpdateHitboxEvent({
    required this.hitboxId,
    this.type,
    this.x,
    this.y,
    this.w,
    this.h,
  });

  @override
  List<Object?> get props => [hitboxId, type, x, y, w, h];
}

class RemoveHitboxEvent extends SpriteSheetEvent {
  final String hitboxId;

  const RemoveHitboxEvent({required this.hitboxId});

  @override
  List<Object?> get props => [hitboxId];
}

class AddDrawnFrameEvent extends SpriteSheetEvent {
  final Uint8List rgbaBytes;
  final int width;
  final int height;

  const AddDrawnFrameEvent({
    required this.rgbaBytes,
    required this.width,
    required this.height,
  });

}
