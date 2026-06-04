import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class HashUtil {
  String hashBytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }
}
