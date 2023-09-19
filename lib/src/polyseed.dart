import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:polyseed/src/birthday.dart';
import 'package:polyseed/src/features.dart';
import 'package:polyseed/src/gf.dart';
import 'package:polyseed/src/mnemonics/polyseed_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/storage.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/key_utils.dart';
import 'package:polyseed/src/utils/lang_utils.dart';

const int POLYSEED_NUM_WORDS = 16;

PolyseedData polyseedCreate(int features) {
  final seed = PolyseedData.empty();
  /* check features */
  seed.features = makeFeatures(features);

  if (!polyseedFeaturesSupported(seed.features)) {
    throw UnsupportedSeedFeatureException();
  }

  /* create seed */
  seed.birthday =
      birthdayEncode((DateTime.now().millisecondsSinceEpoch / 1000).round());

  final random = Random.secure();
  seed.secret = Uint8List.fromList(
      List<int>.generate(SECRET_SIZE, (index) => random.nextInt(256)));
  seed.secret[SECRET_SIZE - 1] &= CLEAR_MASK;

  /* encode polynomial */
  var poly = GFPoly();
  poly = polyseed_data_to_poly(seed, poly);

  /* calculate checksum */
  poly = gf_poly_encode(poly);
  seed.checksum = poly.coeff[0];

  return seed;
}

int polyseed_get_birthday(PolyseedData data) => birthdayDecode(data.birthday);

int polyseed_get_feature(PolyseedData seed, int mask) =>
    getFeatures(seed.features, mask);

String polyseed_encode(
    PolyseedData data, PolyseedLang lang, PolyseedCoin coin) {
  assert(coin.index < GF_SIZE);

  /* encode polynomial with the existing checksum */
  var poly = GFPoly();
  poly.coeff[0] = data.checksum;
  poly = polyseed_data_to_poly(data, poly);

  /* apply coin */
  poly.coeff[POLY_NUM_CHECK_DIGITS] ^= coin.index;

  var tmp = "";
  var w = 0;

  String getWord(i) => lang.words[poly.coeff[i]];

  /* output words */
  for (w = 0; w < POLYSEED_NUM_WORDS - 1; ++w) {
    tmp += getWord(w) + lang.separator;
  }
  tmp += getWord(w);

  return tmp;
}

PolyseedData polyseedDecode(String str, PolyseedLang lang, PolyseedCoin coin) {
  assert(coin.index < GF_SIZE);

  final words = str.split(lang.separator);
  final poly = GFPoly();

  /* split into words */
  if (words.length != POLYSEED_NUM_WORDS) {
    throw WordNumberException();
  }

  /* decode words into polynomial coefficients */
  poly.coeff = polyseed_phrase_decode(words);

  /* finalize polynomial */
  poly.coeff[POLY_NUM_CHECK_DIGITS] ^= coin.index;

  /* checksum */
  if (!gf_poly_check(poly)) {
    throw ChecksumMismatchException;
  }

  /* decode polynomial into seed data */
  var seed = polyseed_poly_to_data(poly);

  /* check features */
  if (!polyseedFeaturesSupported(seed.features)) {
    throw UnsupportedSeedFeatureException();
  }

  return seed;
}

Uint8List store32(Uint8List list, int index, int value) {
  list[index] = value;
  list[index + 1] = (value >> 8);
  list[index + 2] = (value >> 8);
  list[index + 3] = (value >> 8);
  return list;
}

Uint8List polyseed_keygen(PolyseedData seed, PolyseedCoin coin, int keySize) {
  assert(coin.index < GF_SIZE);

  var salt = Uint8List(32);
  salt.setRange(0, 12, utf8.encode("POLYSEED key"));
  salt[13] = 0xff;
  salt[14] = 0xff;
  salt[15] = 0xff;
  salt = store32(salt, 16, coin.index); /* domain separate by coin */
  salt = store32(salt, 20, seed.birthday); /* domain separate by birthday */
  salt = store32(salt, 24, seed.features); /* domain separate by features */

  return generateKey(seed.secret, salt, keySize);
}

PolyseedData polyseed_load(Uint8List storage) {
  var poly = GFPoly();

  /* deserialize data */
  final seed = polyseedDataLoad(storage);

  /* encode polynomial with the existing checksum */
  poly.coeff[0] = seed.checksum;
  poly = polyseed_data_to_poly(seed, poly);

  /* checksum */
  if (!gf_poly_check(poly)) {
    throw ChecksumMismatchException();
  }

  /* check features */
  if (!polyseedFeaturesSupported(seed.features)) {
    throw UnsupportedSeedFeatureException();
  }

  return seed;
}

PolyseedData polyseed_crypt(PolyseedData seed, String password) {
  /* derive an encryption mask */
  var mask = Uint8List(32);

  final salt = Uint8List(16);
  salt.setRange(0, 13, utf8.encode("POLYSEED mask"));
  salt[14] = 0xff;
  salt[15] = 0xff;

  mask = generateKey(utf8.encode(password) as Uint8List, salt, 32);

  /* apply mask */
  for (int i = 0; i < SECRET_SIZE; ++i) {
    seed.secret[i] ^= mask[i];
  }
  seed.secret[SECRET_SIZE - 1] &= CLEAR_MASK;

  seed.features ^= ENCRYPTED_MASK;

  /* encode polynomial */
  var poly = GFPoly();
  poly = polyseed_data_to_poly(seed, poly);

  /* calculate new checksum */
  poly = gf_poly_encode(poly);

  seed.checksum = poly.coeff[0];

  return seed;
}

bool polyseed_is_encrypted(PolyseedData seed) => isEncrypted(seed.features);
