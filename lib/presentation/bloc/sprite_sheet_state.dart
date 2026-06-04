part of 'sprite_sheet_bloc.dart';

// ignore_for_file: depend_on_referenced_packages

abstract class SpriteSheetState extends Equatable {
  const SpriteSheetState();

  @override
  List<Object?> get props => [];
}

class SpriteSheetInitial extends SpriteSheetState {
  const SpriteSheetInitial();
}

class ImportingFrames extends SpriteSheetState {
  const ImportingFrames();
}

class FramesImported extends SpriteSheetState {
  final List<SpriteFrame> frames;
  final List<FrameAnnotation> annotations;

  const FramesImported(
    this.frames, {
    this.annotations = const [],
  });

  int get frameCount => frames.length;

  @override
  List<Object?> get props => [frames, annotations];
}

class Packing extends SpriteSheetState {
  const Packing();
}

class PackComplete extends SpriteSheetState {
  final PackResult packResult;
  final List<SpriteFrame> frames;
  final Uint8List pngBytes;
  final List<FrameAnnotation> annotations;

  const PackComplete(
    this.packResult,
    this.frames,
    this.pngBytes, {
    this.annotations = const [],
  });

  @override
  List<Object?> get props => [packResult, frames, pngBytes, annotations];
}

class Exporting extends SpriteSheetState {
  const Exporting();
}

class Exported extends SpriteSheetState {
  final String pngPath;
  final String jsonPath;

  const Exported(this.pngPath, this.jsonPath);

  @override
  List<Object?> get props => [pngPath, jsonPath];
}

class SpriteSheetError extends SpriteSheetState {
  final String message;

  const SpriteSheetError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProjectSaving extends SpriteSheetState {
  const ProjectSaving();
}

class ProjectLoading extends SpriteSheetState {
  const ProjectLoading();
}
