import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:polyseed/src/polyseed_birthday.dart';
import 'package:polyseed/src/constants.dart';
import 'package:polyseed/src/gf_poly.dart';
import 'package:polyseed/src/mnemonics/polyseed_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/polyseed_features.dart';
import 'package:polyseed/src/polyseed_storage.dart';
import 'package:polyseed/src/utils/exceptions.dart';

class Polyseed {
  late PolyseedData _data;

  /// Create a random [Polyseed]
  Polyseed.create({int features = 0}) {
    // check features
    final seedFeatures = PolyseedFeatures.make(features);

    if (!PolyseedFeatures.isSupported(seedFeatures)) {
      throw UnsupportedSeedFeatureException();
    }

    // create seed
    final birthday = PolyseedBirthday.encode(
        (DateTime.now().millisecondsSinceEpoch / 1000).round());

    final random = Random.secure();
    final secret = Uint8List.fromList(
        List<int>.generate(SECRET_SIZE, (index) => random.nextInt(256)));
    secret[SECRET_SIZE - 1] &= CLEAR_MASK;

    final seed = PolyseedData(
        birthday: birthday,
        features: seedFeatures,
        secret: secret,
        checksum: 0);

    // encode polynomial
    final poly = GFPoly.fromPolyseedData(seed);

    // calculate checksum
    poly.encode();
    seed.checksum = poly.coeff[0];

    _data = seed;
  }

  /// Decode a seed phrase into [Polyseed]
  Polyseed.decode(String str, PolyseedLang lang, PolyseedCoin coin) {
    assert(coin.index < GF_SIZE);

    final words = str.split(lang.separator);
    final poly = GFPoly();

    // split into words
    if (words.length != POLYSEED_NUM_WORDS) {
      throw WordNumberException();
    }

    // decode words into polynomial coefficients
    poly.coeff = lang.decodePhrase(str);

    // finalize polynomial
    poly.coeff[POLY_NUM_CHECK_DIGITS] ^= coin.index;

    // validate checksum
    if (!poly.check()) throw ChecksumMismatchException;

    // decode polynomial into seed data
    var seed = poly.toPolyseedData();

    // check features
    if (!PolyseedFeatures.isSupported(seed.features)) {
      throw UnsupportedSeedFeatureException();
    }

    _data = seed;
  }

  /// Deserialize a [Uint8List] into a [Polyseed]
  ///
  /// To serialize the [Polyseed] use [save]
  Polyseed.load(Uint8List storage) {
    // deserialize data
    final seed = PolyseedStorage.load(storage);

    // encode polynomial with the existing checksum
    final poly = GFPoly.fromPolyseedData(seed, checksum: seed.checksum);

    // validate checksum
    if (!poly.check()) throw ChecksumMismatchException();

    // check features
    if (!PolyseedFeatures.isSupported(seed.features)) {
      throw UnsupportedSeedFeatureException();
    }

    _data = seed;
  }

  /// Check if the [Polyseed] was encrypted using [crypt]
  bool get isEncrypted => PolyseedFeatures.isEncrypted(_data.features);

  /// Get the decoded timestamp of the Polyseed's birthday
  int get birthday => PolyseedBirthday.decode(_data.birthday);

  /// Check if the [Polyseed] as a given feature mask enabled
  bool hasFeature(int feature) =>
      PolyseedFeatures.get(_data.features, feature) != 0;

  /// Encode to a valid Seed Phrase in the given [PolyseedLang]
  String encode(PolyseedLang lang, PolyseedCoin coin) {
    assert(coin.index < GF_SIZE);

    // encode polynomial with the existing checksum
    final poly = GFPoly.fromPolyseedData(_data, checksum: _data.checksum);

    // apply coin
    poly.coeff[POLY_NUM_CHECK_DIGITS] ^= coin.index;

    return lang.encodePhrase(poly.coeff);
  }

  /// Serialize the seed into a [Uint8List]
  ///
  /// To deserialize the [Polyseed] use [Polyseed.load]
  Uint8List save() => PolyseedStorage.store(_data);

  /// Encrypt or decrypt the [Polyseed] with the [password]
  void crypt(String password) {
    // derive an encryption mask
    final salt = Uint8List(16);
    salt.setRange(0, 13, utf8.encode("POLYSEED mask"));
    salt[14] = 0xff;
    salt[15] = 0xff;

    final mask = _deriveKey(utf8.encode(password) as Uint8List, salt, 32);

    // apply mask
    for (var i = 0; i < SECRET_SIZE; ++i) {
      _data.secret[i] ^= mask[i];
    }
    _data.secret[SECRET_SIZE - 1] &= CLEAR_MASK;
    _data.features ^= ENCRYPTED_MASK;

    // encode polynomial
    final poly = GFPoly.fromPolyseedData(_data);

    // calculate new checksum
    poly.encode();

    _data.checksum = poly.coeff[0];
  }

  /// Generate the secret spend key
  Uint8List generateKey(PolyseedCoin coin, int keySize) {
    assert(coin.index < GF_SIZE);

    var salt = Uint8List(32);
    salt.setRange(0, 12, utf8.encode("POLYSEED key"));
    salt[13] = 0xff;
    salt[14] = 0xff;
    salt[15] = 0xff;
    salt = _store32(salt, 16, coin.index); // domain separate by coin
    salt = _store32(salt, 20, _data.birthday); // domain separate by birthday
    salt = _store32(salt, 24, _data.features); // domain separate by features

    return _deriveKey(_data.secret, salt, keySize);
  }

  Uint8List _deriveKey(Uint8List password, Uint8List salt, int keySize) {
    var derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
    var params = Pbkdf2Parameters(salt, KDF_NUM_ITERATIONS, keySize);
    derivator.init(params);
    return derivator.process(password);
  }

  Uint8List _store32(Uint8List list, int index, int value) {
    list[index] = value;
    list[index + 1] = (value >> 8);
    list[index + 2] = (value >> 8);
    list[index + 3] = (value >> 8);
    return list;
  }
}
