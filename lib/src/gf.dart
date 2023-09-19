import 'dart:typed_data';

import 'package:polyseed/src/birthday.dart';
import 'package:polyseed/src/features.dart';
import 'package:polyseed/src/polyseed_data.dart';

import 'polyseed.dart';
import 'dart:math';

const int CHAR_BIT = 8;
const int SECRET_BITS = 150;
const int SECRET_BUFFER_SIZE = 32;

const int GF_BITS = 11;
const int GF_SIZE = 1 << GF_BITS;
const int GF_MASK = GF_SIZE - 1;
const int POLY_NUM_CHECK_DIGITS = 1;

const int SHARE_BITS = 10; /* bits of the secret per word */
const int DATA_WORDS = POLYSEED_NUM_WORDS - POLY_NUM_CHECK_DIGITS;

List<int> polyseed_mul2_table = [5, 7, 1, 3, 13, 15, 9, 11];
// POLYSEED_PRIVATE gf_elem polyseed_mul2_table[8] = {
// 5, 7, 1, 3, 13, 15, 9, 11
// };

class GFPoly {
  List<int> coeff = Uint16List(POLYSEED_NUM_WORDS);
}

int gf_elem_mul2(int x) {
  if (x < 1024) {
    return 2 * x;
  }
  return polyseed_mul2_table[x % 8] + 16 * ((x - 1024) ~/ 8);
}

int gf_poly_eval(GFPoly poly) {
  int result = poly.coeff[POLYSEED_NUM_WORDS - 1];
  for (int i = POLYSEED_NUM_WORDS - 2; i >= 0; --i) {
    result = gf_elem_mul2(result) ^ poly.coeff[i];
  }
  return result;
}

GFPoly gf_poly_encode(GFPoly message) {
  message.coeff[0] = gf_poly_eval(message);
  return message;
}

bool gf_poly_check(GFPoly message) => gf_poly_eval(message) == 0;

GFPoly polyseed_data_to_poly(PolyseedData data, GFPoly poly) {
  int extraVal = (data.features << DATE_BITS) | data.birthday;
  int extraBits = FEATURE_BITS + DATE_BITS;

  int wordBits = 0;
  int wordVal = 0;

  int secretIdx = 0;
  int secretVal = data.secret[secretIdx];
  int secretBits = CHAR_BIT;
  int seedRemBits = SECRET_BITS - CHAR_BIT;

  for (int i = 0; i < DATA_WORDS; ++i) {
    while (wordBits < SHARE_BITS) {
      if (secretBits == 0) {
        secretIdx++;
        secretBits = min(seedRemBits, CHAR_BIT);
        secretVal = data.secret[secretIdx];
        seedRemBits -= secretBits;
      }

      int chunkBits = min(secretBits, SHARE_BITS - wordBits);
      secretBits -= chunkBits;
      wordBits += chunkBits;
      wordVal <<= chunkBits;
      wordVal |= (secretVal >> secretBits) & ((1 << chunkBits) - 1);
    }
    wordVal <<= 1;
    extraBits--;
    wordVal |= (extraVal >> extraBits) & 1;
    poly.coeff[POLY_NUM_CHECK_DIGITS + i] = wordVal;
    wordVal = 0;
    wordBits = 0;
  }

  assert(seedRemBits == 0);
  assert(secretBits == 0);
  assert(extraBits == 0);

  return poly;
}

PolyseedData polyseed_poly_to_data(GFPoly poly) {
  int birthday = 0;
  int features = 0;
  Uint8List secret = Uint8List(SECRET_BUFFER_SIZE);
  int checksum = poly.coeff[0];

  int extraVal = 0;
  int extraBits = 0;

  int wordBits = 0;
  int wordVal = 0;

  int secretIdx = 0;
  int secretBits = 0;
  int seedBits = 0;

  for (int i = POLY_NUM_CHECK_DIGITS; i < POLYSEED_NUM_WORDS; ++i) {
    wordVal = poly.coeff[i];

    extraVal <<= 1;
    extraVal |= wordVal & 1;
    wordVal >>= 1;
    wordBits = GF_BITS - 1;
    extraBits++;

    while (wordBits > 0) {
      if (secretBits == CHAR_BIT) {
        secretIdx++;
        seedBits += secretBits;
        secretBits = 0;
      }

      int chunkBits = min(wordBits, CHAR_BIT - secretBits);
      wordBits -= chunkBits;
      int chunkMask = ((1 << chunkBits) - 1);
      if (chunkBits < CHAR_BIT) {
        secret[secretIdx] <<= chunkBits;
      }
      secret[secretIdx] |= (wordVal >> wordBits) & chunkMask;
      secretBits += chunkBits;
    }
  }

  seedBits += secretBits;

  assert(wordBits == 0);
  assert(seedBits == SECRET_BITS);
  assert(extraBits == FEATURE_BITS + DATE_BITS);

  birthday = extraVal & DATE_MASK;
  features = extraVal >> DATE_BITS;

  return PolyseedData(birthday: birthday,
      features: features,
      secret: secret,
      checksum: checksum);
}
