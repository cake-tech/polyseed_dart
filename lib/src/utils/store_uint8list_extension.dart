import 'dart:typed_data';

extension StoreToList on Uint8List {
  void store32(int index, int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'value must fit in a uint32');
    this[index] = value;
    this[index + 1] = (value >> 8);
    this[index + 2] = (value >> 16);
    this[index + 3] = (value >> 24);
  }

  void store16(int index, int value) {
    this[index] = value;
    this[index + 1] = (value >> 8);
  }

  int load16(int index) => this[index] | (this[index + 1] << 8);
}
