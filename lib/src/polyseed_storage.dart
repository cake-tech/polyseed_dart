/*
 * Copyright (c) 2020-2026 tevador <tevador@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Ported from tevador/polyseed (src/storage.c) to Dart by Cake Labs LLC.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:polyseed/src/gf_poly.dart';
import 'package:polyseed/src/polyseed_birthday.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/polyseed_features.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_extension.dart';
import 'package:polyseed/src/utils/store_uint8list_extension.dart';

class PolyseedStorage {
  static const String header = "POLYSEED";
  static const int footer = 0x7000;
  static const int extraByte = 0xFF;

  static const int _clearBits = 2; // (SECRET_SIZE) * (CHAR_BIT) - (SECRET_BITS)
  static const int clearMask =
      ~(((1 << (_clearBits)) - 1) << (8 - (_clearBits)));

  static Uint8List store(PolyseedData data) {
    final headerBytes = utf8.encode(header);
    final storage = Uint8List(32);
    var pos = header.length;

    storage.setRange(0, header.length, headerBytes);
    storage.store16(
        pos, (data.features << PolyseedBirthday.dateBits) | data.birthday);
    pos += 2;

    storage.setRange(pos, pos + GFPoly.secretSize, data.secret);
    pos += GFPoly.secretSize;

    storage[pos] = extraByte;
    pos++;

    storage.store16(pos, footer | data.checksum);
    return storage;
  }

  static PolyseedData load(Uint8List storage) {
    final data = PolyseedData.empty();
    final headerBytes = utf8.encode(PolyseedStorage.header);
    var pos = header.length;

    if (storage.sublist(0, header.length).notEquals(headerBytes)) {
      throw InvalidSeedFormatException();
    }

    var v1 = storage.load16(pos);
    data.birthday = v1 & PolyseedBirthday.dateBitMask;
    v1 >>= PolyseedBirthday.dateBits;

    if (v1 > PolyseedFeatures.featuresBitMask) {
      throw InvalidSeedFormatException();
    }

    data.features = v1;
    pos += 2;
    data.secret.fillRange(0, GFPoly.secretSize, 0);
    data.secret.setRange(
        0, GFPoly.secretSize, storage.sublist(pos, pos + GFPoly.secretSize));

    if (data.secret[GFPoly.secretSize - 1] & ~clearMask != 0) {
      throw InvalidSeedFormatException();
    }

    pos += GFPoly.secretSize;
    if (storage[pos] != PolyseedStorage.extraByte) {
      throw InvalidSeedFormatException();
    }

    pos++;
    var v2 = storage.load16(pos);
    data.checksum = v2 & GFPoly.bitMask;
    v2 &= ~GFPoly.bitMask;

    if (v2 != PolyseedStorage.footer) throw InvalidSeedFormatException();

    return data;
  }
}
