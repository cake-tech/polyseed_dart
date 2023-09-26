import 'dart:typed_data';

extension StoreToList on Uint8List {
  void store32(int index, int value) {
    this[index] = value;
    this[index + 1] = (value >> 8);
    this[index + 2] = (value >> 8);
    this[index + 3] = (value >> 8);
  }

  void store16(int index, int value) {
    this[index] = value;
    this[index + 1] = (value >> 8);
  }

  int load16(int index) => this[index] | (this[index + 1] << 8);
}
