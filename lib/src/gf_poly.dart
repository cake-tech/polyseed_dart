import 'dart:math';
import 'dart:typed_data';

import 'package:polyseed/src/constants.dart';
import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/polyseed_features.dart';

class GFPoly {
  List<int> coefficients = Uint16List(Polyseed.numberOfWords);

  final List<int> _mul2Table = [5, 7, 1, 3, 13, 15, 9, 11];
  final int secretBufferSize = 32;

  static const int bits = 11;
  static const int size = 1 << bits;
  static const int bitMask = size - 1;

  GFPoly();

  GFPoly.fromPolyseedData(PolyseedData data, {int? checksum}) {
    if (checksum != null) coefficients[0] = checksum;

    final extraVal = (data.features << DATE_BITS) | data.birthday;
    var extraBits = PolyseedFeatures.featureBits + DATE_BITS;

    var secretIdx = 0;
    var secretVal = data.secret[secretIdx];
    var secretBits = charBit;
    var seedRemBits = SECRET_BITS - charBit;

    for (var i = 0; i < DATA_WORDS; ++i) {
      var wordBits = 0;
      var wordVal = 0;
      while (wordBits < SHARE_BITS) {
        if (secretBits == 0) {
          secretIdx++;
          secretBits = min(seedRemBits, charBit);
          secretVal = data.secret[secretIdx];
          seedRemBits -= secretBits;
        }

        final chunkBits = min(secretBits, SHARE_BITS - wordBits);
        secretBits -= chunkBits;
        wordBits += chunkBits;
        wordVal <<= chunkBits;
        wordVal |= (secretVal >> secretBits) & ((1 << chunkBits) - 1);
      }
      wordVal <<= 1;
      extraBits--;
      wordVal |= (extraVal >> extraBits) & 1;
      coefficients[POLY_NUM_CHECK_DIGITS + i] = wordVal;
    }

    assert(seedRemBits == 0);
    assert(secretBits == 0);
    assert(extraBits == 0);
  }

  bool check() => eval() == 0;

  int eval() {
    var result = coefficients[Polyseed.numberOfWords - 1];
    for (var i = Polyseed.numberOfWords - 2; i >= 0; --i) {
      result = _elemMul2(result) ^ coefficients[i];
    }
    return result;
  }

  int _elemMul2(int x) {
    if (x < 1024) return 2 * x;

    return _mul2Table[x % 8] + 16 * ((x - 1024) ~/ 8);
  }

  void encode() => coefficients[0] = eval();

  PolyseedData toPolyseedData() {
    final secret = Uint8List(secretBufferSize);
    final checksum = coefficients[0];

    var extraVal = 0;
    var extraBits = 0;

    var wordBits = 0;
    var wordVal = 0;

    var secretIdx = 0;
    var secretBits = 0;
    var seedBits = 0;

    for (int i = POLY_NUM_CHECK_DIGITS; i < Polyseed.numberOfWords; ++i) {
      wordVal = coefficients[i];

      extraVal <<= 1;
      extraVal |= wordVal & 1;
      wordVal >>= 1;
      wordBits = bits - 1;
      extraBits++;

      while (wordBits > 0) {
        if (secretBits == charBit) {
          secretIdx++;
          seedBits += secretBits;
          secretBits = 0;
        }

        final chunkBits = min(wordBits, charBit - secretBits);
        wordBits -= chunkBits;
        final chunkMask = ((1 << chunkBits) - 1);
        if (chunkBits < charBit) {
          secret[secretIdx] <<= chunkBits;
        }
        secret[secretIdx] |= (wordVal >> wordBits) & chunkMask;
        secretBits += chunkBits;
      }
    }

    seedBits += secretBits;

    assert(wordBits == 0);
    assert(seedBits == SECRET_BITS);
    assert(extraBits == PolyseedFeatures.featureBits + DATE_BITS);

    return PolyseedData(
        birthday: extraVal & DATE_MASK,
        features: extraVal >> DATE_BITS,
        secret: secret,
        checksum: checksum);
  }
}
