import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../utils/downloader.dart';

import '../../domain/entities/sprite_frame.dart';
import '../../domain/repositories/image_repository.dart';
import '../sources/hash_util.dart';
import '../sources/image_decoder.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ImageDecoder _imageDecoder;
  final HashUtil _hashUtil;
  final Uuid _uuid;

  ImageRepositoryImpl({
    required ImageDecoder imageDecoder,
    required HashUtil hashUtil,
    Uuid? uuid,
  })  : _imageDecoder = imageDecoder,
        _hashUtil = hashUtil,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<SpriteFrame>> importFrames(List<PlatformFile> files) async {
    if (files.isEmpty) return [];

    final results = await Future.wait(
      files.map((p) => _imageDecoder.decodeFile(p)),
    );

    final frames = <SpriteFrame>[];
    final seenHashes = <String>{};

    for (final r in results) {
      final hash = _hashUtil.hashBytes(r.rgbaBytes);
      if (seenHashes.contains(hash)) continue;

      seenHashes.add(hash);
      frames.add(SpriteFrame(
        id: _uuid.v4(),
        name: r.fileName,
        width: r.width,
        height: r.height,
        imageBytes: r.rgbaBytes,
        hash: hash,
      ));
    }

    return frames;
  }

  @override
  Future<void> exportSheet(Uint8List pngBytes, String outputPath) async {
    if (kIsWeb) {
      final filename = outputPath.split(RegExp(r'[\\/]')).last;
      downloadFileForWeb(pngBytes, filename);
    } else {
      final file = File(outputPath);
      await file.writeAsBytes(pngBytes);
    }
  }

  @override
  Future<void> exportJson(Map<String, dynamic> jsonData, String outputPath) async {
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(jsonData);
    
    if (kIsWeb) {
      final bytes = utf8.encode(jsonString);
      final filename = outputPath.split(RegExp(r'[\\/]')).last;
      downloadFileForWeb(Uint8List.fromList(bytes), filename);
    } else {
      final file = File(outputPath);
      await file.writeAsString(jsonString);
    }
  }
}
