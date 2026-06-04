// {@template image_repository}
// Contract for importing sprite images and exporting packed atlas
// artefacts (PNG image + JSON metadata) to the file system.
//
// Implementations live in the **data** layer and may depend on
// platform-specific file I/O or the `image` package for decoding.
// {@endtemplate}
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import '../entities/sprite_frame.dart';

/// Abstract repository for image import / export operations.
abstract class ImageRepository {
  /// Imports one or more image files and returns the decoded
  /// [SpriteFrame] entities.
  ///
  /// Each file in [files] is read from disk, decoded to raw RGBA
  /// pixels, hashed with SHA-256, and wrapped in a [SpriteFrame].
  ///
  /// Throws if any file cannot be read or decoded.
  Future<List<SpriteFrame>> importFrames(List<PlatformFile> files);

  /// Writes the packed atlas image to [outputPath] as a PNG file.
  ///
  /// [pngBytes] must contain a valid PNG-encoded image.
  Future<void> exportSheet(Uint8List pngBytes, String outputPath);

  /// Serialises [jsonData] and writes it to [outputPath].
  ///
  /// The output file is UTF-8 encoded JSON.
  Future<void> exportJson(Map<String, dynamic> jsonData, String outputPath);
}
