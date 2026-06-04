import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'package:file_picker/file_picker.dart';

class ImageDecodeResult {
  final Uint8List rgbaBytes;
  final int width;
  final int height;
  final String fileName;

  const ImageDecodeResult({
    required this.rgbaBytes,
    required this.width,
    required this.height,
    required this.fileName,
  });
}

class ImageDecoder {
  Future<ImageDecodeResult> decodeFile(PlatformFile file) {
    return compute(_decodeIsolate, file);
  }
}

ImageDecodeResult _decodeIsolate(PlatformFile file) {
  final Uint8List fileBytes;
  if (kIsWeb) {
    fileBytes = file.bytes!;
  } else {
    fileBytes = File(file.path!).readAsBytesSync();
  }
  
  final image = img.decodeImage(fileBytes);

  if (image == null) {
    throw ArgumentError('Failed to decode image: ${file.name}');
  }

  final name = file.name;
  final rgba = image.numChannels >= 4
      ? Uint8List.fromList(image.getBytes())
      : _padToRgba(image);

  return ImageDecodeResult(
    rgbaBytes: rgba,
    width: image.width,
    height: image.height,
    fileName: name,
  );
}

Uint8List _padToRgba(img.Image src) {
  final srcBytes = src.getBytes();
  final pixelCount = src.width * src.height;
  final expected4 = pixelCount * 4;

  if (srcBytes.length == expected4) return Uint8List.fromList(srcBytes);

  final dst = Uint8List(expected4);
  for (var i = 0; i < pixelCount; i++) {
    dst[i * 4] = srcBytes[i * 3];
    dst[i * 4 + 1] = srcBytes[i * 3 + 1];
    dst[i * 4 + 2] = srcBytes[i * 3 + 2];
    dst[i * 4 + 3] = 255;
  }
  return dst;
}
