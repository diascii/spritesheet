import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/anchor_data.dart';
import '../../domain/entities/frame_annotation.dart';
import '../../domain/entities/hitbox_data.dart';
import '../../domain/entities/pack_result.dart';
import '../../domain/entities/sheet_config.dart';
import '../../domain/entities/sprite_frame.dart';
import '../../domain/usecases/export_sheet.dart';
import '../../domain/usecases/import_frames.dart';
import '../../domain/usecases/pack_sprites.dart';

part 'sprite_sheet_event.dart';
part 'sprite_sheet_state.dart';

class AssetBloc extends Bloc<SpriteSheetEvent, SpriteSheetState> {
  final ImportFrames _importFrames;
  final PackSprites _packSprites;
  final ExportSheet _exportSheet;

  List<SpriteFrame> _frames = [];
  List<FrameAnnotation> _annotations = [];
  PackResult? _packResult;
  Uint8List? _pngBytes;
  List<ui.Color>? palette;

  List<FrameAnnotation> get annotations => List.unmodifiable(_annotations);

  AssetBloc({
    required ImportFrames importFrames,
    required PackSprites packSprites,
    required ExportSheet exportSheet,
  })  : _importFrames = importFrames,
        _packSprites = packSprites,
        _exportSheet = exportSheet,
        super(const SpriteSheetInitial()) {
    on<ImportFramesEvent>(_onImportFrames);
    on<PackSpritesEvent>(_onPackSprites);
    on<ExportSheetEvent>(_onExportSheet);
    on<UpdateConfigEvent>(_onUpdateConfig);
    on<ClearFramesEvent>(_onClearFrames);
    on<ReorderFramesEvent>(_onReorderFrames);
    on<RemoveFrameEvent>(_onRemoveFrame);
    on<SetAnchorEvent>(_onSetAnchor);
    on<ClearAnchorEvent>(_onClearAnchor);
    on<AddHitboxEvent>(_onAddHitbox);
    on<UpdateHitboxEvent>(_onUpdateHitbox);
    on<RemoveHitboxEvent>(_onRemoveHitbox);
    on<SetFrameTagEvent>(_onSetFrameTag);
    on<LoadProjectDataEvent>(_onLoadProjectData);
  }

  Future<void> _onImportFrames(
    ImportFramesEvent event,
    Emitter<SpriteSheetState> emit,
  ) async {
    emit(const ImportingFrames());
    try {
      final frames = await _importFrames.execute();
      if (frames.isEmpty) {
        emit(const SpriteSheetInitial());
        return;
      }
      _frames = frames;
      _annotations = frames.map((f) => FrameAnnotation(frameId: f.id)).toList();
      emit(FramesImported(List.from(_frames), annotations: List.from(_annotations)));
    } catch (e) {
      emit(SpriteSheetError(e.toString()));
    }
  }

  Future<void> _onPackSprites(
    PackSpritesEvent event,
    Emitter<SpriteSheetState> emit,
  ) async {
    if (_frames.isEmpty) return;
    emit(const Packing());
    try {
      final output = await _packSprites.execute(_frames, event.config);
      _packResult = output.packResult;
      _pngBytes = output.pngBytes;
      emit(PackComplete(output.packResult, List.from(_frames), _pngBytes!, annotations: List.from(_annotations)));
    } catch (e) {
      emit(SpriteSheetError(e.toString()));
    }
  }

  Future<void> _onExportSheet(
    ExportSheetEvent event,
    Emitter<SpriteSheetState> emit,
  ) async {
    if (_packResult == null || _pngBytes == null) return;
    emit(const Exporting());
    try {
      final result = await _exportSheet.execute(
        packResult: _packResult!,
        pngBytes: _pngBytes!,
        config: event.config,
        annotations: _annotations,
        frames: _frames,
        outputDirectory: event.outputDirectory,
      );
      emit(Exported(result.pngPath, result.jsonPath));
    } catch (e) {
      emit(SpriteSheetError(e.toString()));
    }
  }

  void _onUpdateConfig(
    UpdateConfigEvent event,
    Emitter<SpriteSheetState> emit,
  ) {
    // Config is passed directly to pack/export events, so this
    // is handled at the UI level. Bloc just acknowledges it.
  }

  void _onClearFrames(
    ClearFramesEvent event,
    Emitter<SpriteSheetState> emit,
  ) {
    _frames = [];
    _annotations = [];
    _packResult = null;
    _pngBytes = null;
    emit(const SpriteSheetInitial());
  }

  void _onReorderFrames(
    ReorderFramesEvent event,
    Emitter<SpriteSheetState> emit,
  ) {
    if (event.oldIndex >= _frames.length || event.newIndex > _frames.length) return;
    final frame = _frames.removeAt(event.oldIndex);
    final newIndex = event.newIndex > event.oldIndex ? event.newIndex - 1 : event.newIndex;
    _frames.insert(newIndex, frame);

    final a = _annotations.removeAt(event.oldIndex);
    _annotations.insert(newIndex, a);

    _packResult = null;
    _pngBytes = null;
    emit(FramesImported(List.from(_frames), annotations: List.from(_annotations)));
  }

  void _onRemoveFrame(
    RemoveFrameEvent event,
    Emitter<SpriteSheetState> emit,
  ) {
    final idx = _frames.indexWhere((f) => f.id == event.frameId);
    if (idx == -1) return;
    _frames.removeAt(idx);
    _annotations.removeAt(idx);
    _packResult = null;
    _pngBytes = null;

    if (_frames.isEmpty) {
      emit(const SpriteSheetInitial());
    } else {
      emit(FramesImported(List.from(_frames), annotations: List.from(_annotations)));
    }
  }

  void _onSetFrameTag(SetFrameTagEvent event, Emitter<SpriteSheetState> emit) {
    final idx = _frames.indexWhere((f) => f.id == event.frameId);
    if (idx == -1) return;
    _frames[idx] = _frames[idx].copyWith(tag: event.tag, clearTag: event.tag == null || event.tag!.isEmpty);
    _emitFrames();
  }

  void _onSetAnchor(SetAnchorEvent event, Emitter<SpriteSheetState> emit) {
    final idx = _annotations.indexWhere((a) => a.frameId == event.frameId);
    if (idx == -1) return;
    _annotations[idx] = _annotations[idx].copyWith(
      anchor: AnchorData(x: event.x, y: event.y),
    );
    _emitFrames();
  }

  void _onClearAnchor(ClearAnchorEvent event, Emitter<SpriteSheetState> emit) {
    final idx = _annotations.indexWhere((a) => a.frameId == event.frameId);
    if (idx == -1) return;
    _annotations[idx] = _annotations[idx].copyWith(clearAnchor: true);
    _emitFrames();
  }

  void _onAddHitbox(AddHitboxEvent event, Emitter<SpriteSheetState> emit) {
    final idx = _annotations.indexWhere((a) => a.frameId == event.frameId);
    if (idx == -1) return;
    final hitbox = HitboxData(
      id: const Uuid().v4(),
      type: event.type,
      x: event.x,
      y: event.y,
      w: event.w,
      h: event.h,
    );
    _annotations[idx] = _annotations[idx].copyWith(
      hitboxes: [..._annotations[idx].hitboxes, hitbox],
    );
    _emitFrames();
  }

  void _onUpdateHitbox(UpdateHitboxEvent event, Emitter<SpriteSheetState> emit) {
    for (var i = 0; i < _annotations.length; i++) {
      final hbIdx = _annotations[i].hitboxes.indexWhere((h) => h.id == event.hitboxId);
      if (hbIdx == -1) continue;
      final updated = _annotations[i].hitboxes[hbIdx].copyWith(
        type: event.type,
        x: event.x,
        y: event.y,
        w: event.w,
        h: event.h,
      );
      final list = List<HitboxData>.of(_annotations[i].hitboxes);
      list[hbIdx] = updated;
      _annotations[i] = _annotations[i].copyWith(hitboxes: list);
      _emitFrames();
      return;
    }
  }

  void _onRemoveHitbox(RemoveHitboxEvent event, Emitter<SpriteSheetState> emit) {
    for (var i = 0; i < _annotations.length; i++) {
      final list = _annotations[i].hitboxes.where((h) => h.id != event.hitboxId).toList();
      if (list.length == _annotations[i].hitboxes.length) continue;
      _annotations[i] = _annotations[i].copyWith(hitboxes: list);
      _emitFrames();
      return;
    }
  }

  // ignore: invalid_use_of_visible_for_testing_member
  void emitState(SpriteSheetState state) => emit(state);

  void _emitFrames() {
    if (_frames.isEmpty) return;
    if (_packResult != null && _pngBytes != null) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(PackComplete(_packResult!, List.from(_frames), _pngBytes!, annotations: List.from(_annotations)));
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(FramesImported(List.from(_frames), annotations: List.from(_annotations)));
    }
  }

  void _onLoadProjectData(LoadProjectDataEvent event, Emitter<SpriteSheetState> emit) {
    _frames = event.frames;
    _annotations = event.annotations;
    palette = event.palette;
    if (_frames.isEmpty) {
      emit(const SpriteSheetInitial());
    } else {
      emit(FramesImported(List.from(_frames), annotations: List.from(_annotations)));
    }
  }
}
