import 'dart:convert';
import 'dart:typed_data';

import 'package:polyseed/src/constants.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_utils.dart';

class PolyseedStorage {
  static const String header = "POLYSEED";
  static const int footer = 0x7000;
  static const int extraByte = 0xFF;

  static Uint8List _store16(Uint8List list, int index, int value) {
    list[index] = value;
    list[index + 1] = (value >> 8);
    return list;
  }

  static int _load16(Uint8List list, int index) =>
      list[index] | (list[index + 1] << 8);

  static Uint8List store(PolyseedData data) {
    final headerBytes = utf8.encode(header);
    var storage = Uint8List(32);
    var pos = header.length;

    storage.setRange(0, header.length, headerBytes);
    storage =
        _store16(storage, pos, (data.features << DATE_BITS) | data.birthday);
    pos += 2;
    storage.setRange(pos, pos + SECRET_SIZE, data.secret);
    pos += SECRET_SIZE;
    storage[pos] = extraByte;
    pos++;
    return _store16(storage, pos, footer | data.checksum);
  }

  static PolyseedData load(Uint8List storage) {
    final data = PolyseedData.empty();
    final headerBytes = utf8.encode(PolyseedStorage.header);
    var pos = header.length;

    if (storage.sublist(0, header.length).notEquals(headerBytes)) {
      throw InvalidSeedFormatException();
    }

    var v1 = _load16(storage, pos);
    data.birthday = v1 & DATE_MASK;
    v1 >>= DATE_BITS;
    if (v1 > FEATURE_MASK) {
      throw InvalidSeedFormatException();
    }
    data.features = v1;
    pos += 2;
    data.secret.fillRange(0, SECRET_SIZE, 0);
    data.secret
        .setRange(0, SECRET_SIZE, storage.sublist(pos, pos + SECRET_SIZE));
    if (data.secret[SECRET_SIZE - 1] & ~CLEAR_MASK != 0) {
      throw InvalidSeedFormatException();
    }
    pos += SECRET_SIZE;
    if (storage[pos] != PolyseedStorage.extraByte) {
      throw InvalidSeedFormatException();
    }
    pos++;
    var v2 = _load16(storage, pos);
    data.checksum = v2 & GF_MASK;
    v2 &= ~GF_MASK;
    if (v2 != PolyseedStorage.footer) {
      throw InvalidSeedFormatException();
    }

    return data;
  }
}
