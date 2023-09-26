import 'dart:math';
import 'dart:typed_data';

import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/polyseed_birthday.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/polyseed_features.dart';

class GFPoly {
  List<int> coefficients = Uint16List(Polyseed.numberOfWords);

  final List<int> _mul2Table = [5, 7, 1, 3, 13, 15, 9, 11];
  final int _charBit = 8; // the number of bits in char
  final int _secretBufferSize = 32;
  final int _secretBits = 150;
  final int _shareBits = 10; // bits of the secret per word
  final int _dataWords = Polyseed.numberOfWords - _numberOfCheckDigits;

  static const int _numberOfCheckDigits = 1;
  static const int _bits = 11;
  static const int size = 1 << _bits;
  static const int bitMask = size - 1;
  static const int secretSize = 19; // (SECRET_BITS + CHAR_BIT - 1) / CHAR_BIT;

  GFPoly();

  GFPoly.fromPolyseedData(PolyseedData data, {int? checksum}) {
    if (checksum != null) coefficients[0] = checksum;

    final extraVal =
        (data.features << PolyseedBirthday.dateBits) | data.birthday;
    var extraBits = PolyseedFeatures.featureBits + PolyseedBirthday.dateBits;

    var secretIdx = 0;
    var secretVal = data.secret[secretIdx];
    var secretBits = _charBit;
    var seedRemBits = _secretBits - _charBit;

    for (var i = 0; i < _dataWords; ++i) {
      var wordBits = 0;
      var wordVal = 0;
      while (wordBits < _shareBits) {
        if (secretBits == 0) {
          secretIdx++;
          secretBits = min(seedRemBits, _charBit);
          secretVal = data.secret[secretIdx];
          seedRemBits -= secretBits;
        }

        final chunkBits = min(secretBits, _shareBits - wordBits);
        secretBits -= chunkBits;
        wordBits += chunkBits;
        wordVal <<= chunkBits;
        wordVal |= (secretVal >> secretBits) & ((1 << chunkBits) - 1);
      }
      wordVal <<= 1;
      extraBits--;
      wordVal |= (extraVal >> extraBits) & 1;
      coefficients[_numberOfCheckDigits + i] = wordVal;
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

  void finalize(int value) => coefficients[_numberOfCheckDigits] ^= value;

  PolyseedData toPolyseedData() {
    final secret = Uint8List(_secretBufferSize);
    final checksum = coefficients[0];

    var extraVal = 0;
    var extraBits = 0;

    var wordBits = 0;
    var wordVal = 0;

    var secretIdx = 0;
    var secretBits = 0;
    var seedBits = 0;

    for (int i = _numberOfCheckDigits; i < Polyseed.numberOfWords; ++i) {
      wordVal = coefficients[i];

      extraVal <<= 1;
      extraVal |= wordVal & 1;
      wordVal >>= 1;
      wordBits = _bits - 1;
      extraBits++;

      while (wordBits > 0) {
        if (secretBits == _charBit) {
          secretIdx++;
          seedBits += secretBits;
          secretBits = 0;
        }

        final chunkBits = min(wordBits, _charBit - secretBits);
        wordBits -= chunkBits;
        final chunkMask = ((1 << chunkBits) - 1);
        if (chunkBits < _charBit) {
          secret[secretIdx] <<= chunkBits;
        }
        secret[secretIdx] |= (wordVal >> wordBits) & chunkMask;
        secretBits += chunkBits;
      }
    }

    seedBits += secretBits;

    assert(wordBits == 0);
    assert(seedBits == _secretBits);
    assert(
        extraBits == PolyseedFeatures.featureBits + PolyseedBirthday.dateBits);

    return PolyseedData(
        birthday: extraVal & PolyseedBirthday.dateBitMask,
        features: extraVal >> PolyseedBirthday.dateBits,
        secret: secret,
        checksum: checksum);
  }
}
