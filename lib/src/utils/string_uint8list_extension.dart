import 'dart:typed_data';

extension ToHexString on Uint8List {
  String toHexString() {
    final keyStream = StringBuffer();
    for (var i in this) {
      keyStream.write(i.toRadixString(16).padLeft(2, '0'));
    }
    return keyStream.toString();
  }
}
