import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'downloader_stub.dart' if (dart.library.html) 'web_downloader.dart';

void downloadFileForWeb(Uint8List bytes, String filename) {
  if (kIsWeb) {
    downloadOnWeb(bytes, filename);
  }
}
