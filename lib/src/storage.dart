import 'dart:convert';
import 'dart:typed_data';

import 'package:polyseed/src/birthday.dart';
import 'package:polyseed/src/features.dart';
import 'package:polyseed/src/gf.dart';
import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_utils.dart';

const String STORAGE_HEADER = "POLYSEED";
const int HEADER_SIZE = 8;
const int EXTRA_BYTE = 0xFF;
const int STORAGE_FOOTER = 0x7000;

const int SECRET_BUFFER_SIZE = 32;
const int SECRET_BITS = 150;
const int SECRET_SIZE = 19; // (SECRET_BITS + CHAR_BIT - 1) / CHAR_BIT; /* 19 */
const int CLEAR_BITS = 2; // (SECRET_SIZE) * (CHAR_BIT) - (SECRET_BITS); /* 2 */
const int CLEAR_MASK =
    ~(((1 << (CLEAR_BITS)) - 1) << (CHAR_BIT - (CLEAR_BITS)));
const int TOTAL_BITS = GF_BITS * POLYSEED_NUM_WORDS;

Uint8List store16(Uint8List list, int index, int value) {
  list[index] = value;
  list[index + 1] = (value >> 8);
  return list;
}

int load16(Uint8List list, int index) {
  return list[index] | (list[index + 1] << 8);
}

Uint8List polyseedDataStore(PolyseedData data) {
  Uint8List storage = Uint8List(32);
  int pos = 0;

  List<int> headerBytes = utf8.encode(STORAGE_HEADER);
  storage.setRange(pos, pos + HEADER_SIZE, headerBytes);
  pos += HEADER_SIZE;
  storage = store16(storage, pos, (data.features << DATE_BITS) | data.birthday);
  pos += 2;
  storage.setRange(pos, pos + SECRET_SIZE, data.secret);
  pos += SECRET_SIZE;
  storage[pos] = EXTRA_BYTE;
  pos++;
  return store16(storage, pos, STORAGE_FOOTER | data.checksum);
}

PolyseedData polyseedDataLoad(Uint8List storage) {
  PolyseedData data = PolyseedData.empty();
  int pos = 0;
  List<int> headerBytes = utf8.encode(STORAGE_HEADER);
  if (storage.sublist(pos, pos + HEADER_SIZE).notEquals(headerBytes)) {
    throw InvalidSeedFormatException();
  }

  pos += HEADER_SIZE;
  int v1 = load16(storage, pos);
  data.birthday = v1 & DATE_MASK;
  v1 >>= DATE_BITS;
  if (v1 > FEATURE_MASK) {
    throw InvalidSeedFormatException();
  }
  data.features = v1;
  pos += 2;
  data.secret.fillRange(0, SECRET_SIZE, 0);
  data.secret.setRange(0, SECRET_SIZE, storage.sublist(pos, pos + SECRET_SIZE));
  if (data.secret[SECRET_SIZE - 1] & ~CLEAR_MASK != 0) {
    throw InvalidSeedFormatException();
  }
  pos += SECRET_SIZE;
  if (storage[pos] != EXTRA_BYTE) {
    throw InvalidSeedFormatException();
  }
  pos++;
  int v2 = load16(storage, pos);
  data.checksum = v2 & GF_MASK;
  v2 &= ~GF_MASK;
  if (v2 != STORAGE_FOOTER) {
    throw InvalidSeedFormatException();
  }

  return data;
}
