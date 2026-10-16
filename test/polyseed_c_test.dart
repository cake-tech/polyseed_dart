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
 * Ported from tevador/polyseed (tests/tests.c) to Dart by Cake Labs LLC.
 */

/*
 * The C tests inject deterministic dependencies (random bytes, time, PBKDF2).
 * Dart has no dependency injection, so:
 *  - seeds are created with [createSeed], which mirrors [Polyseed.create] but
 *    takes the random bytes and the time as arguments
 *  - the assertions of the `pbkdf2_dummy*` functions on the PBKDF2 password
 *    and salt are checked by comparing the derived key against an independent
 *    PBKDF2 computation over the expected password and salt
 *  - the allocation, memzero and inject tests have no Dart equivalent
 */
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:polyseed/polyseed.dart';
import 'package:polyseed/src/gf_poly.dart';
import 'package:polyseed/src/polyseed_birthday.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/polyseed_features.dart';
import 'package:polyseed/src/polyseed_storage.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

const seedTime1 = 1638446400; // Dec 2021
const seedTime2 = 3118651200; // Oct 2068
const seedTime3 = 4305268800; // Jun 2106

const featureFoo = 1;
const featureBar = 2;
const featureQux = 4;

const phraseEn1 = "raven tail swear infant grief assist regular lamp "
    "duck valid someone little harsh puppy airport language";
const phraseEn2 = "rave tail swea infan grie assi regul lamp "
    "duck vali some litt hars pupp airp langua";
const phraseEn3 = "ravexxx tail swea infan grie assi regul lamp "
    "duck vali some litt hars pupp airp langua";
const phraseEn4 = "raven tail swear infantile grief assist regular lamp "
    "duck valid someone little harsh puppy airport language";
const phraseEn5 = "raven tail swear infant grief assist regular lamp "
    "duck valid someone little harsh puppy airport language ";

// tests.c stores the accented phrases decomposed (NFD)
final phraseEs1 = unorm.nfd("eje fin parte célebre tabú pestaña lienzo puma "
    "prisión hora regalo lengua existir lápiz lote sonoro");
const phraseEs2 = "eje fin parte celebre tabu pestana lienzo puma "
    "prision hora regalo lengua existir lapiz lote sonoro";
const phraseEs3 = "eje fin part cele tabu pest lien puma "
    "pris hora rega leng exis lapi lote sono";
const phraseEs4 = "ejexxx fin part cele tabu pest lien puma "
    "pris hora rega leng exis lapi lote sono";
const phraseEs5 = "eje fin part cele tab pest lien puma "
    "pris hora rega leng exis lapi lote sono";
final phraseEs6 = unorm.nfd("eje fin part céle tabú pestañ lien puma "
    "prisió hora rega leng exis lápi lote sono");

const phraseEsMult = "impo sort usua cabi venu nobl oliv clim "
    "cont barr marc auto prod vaca torn fati";

const phraseZhMult = "殊 福 女 塞 答 追 看 拌 "
    "招 梯 享 箭 童 血 群 腿";

const phraseGarbage1 = "xxx xxx";
final phraseGarbage2 = List.filled(120, "xxx").join(" ");

/// serialized polyseed that will produce a very long phrase in Korean
final storeLongPhrase = Uint8List.fromList([
  0x50, 0x4f, 0x4c, 0x59, 0x53, 0x45, 0x45, 0x44, //
  0x08, 0x00, 0xc6, 0xcc, 0x79, 0x60, 0x39, 0x22,
  0xf1, 0xb9, 0x60, 0x8b, 0x22, 0xc3, 0x90, 0xe7,
  0x79, 0x0e, 0x4c, 0x70, 0x39, 0xff, 0x36, 0x76,
]);

const testPass = "password";

const randBytes1 = [
  0xdd, 0x76, 0xe7, 0x35, 0x9a, 0x0d, 0xed, 0x37, //
  0xcd, 0x0f, 0xf0, 0xf3, 0xc8, 0x29, 0xa5, 0xae,
  0x01, 0x67, 0xf3,
];

const randBytes2 = [
  0x5a, 0x2b, 0x02, 0xdf, 0x7d, 0xb2, 0x1f, 0xcb, //
  0xe6, 0xec, 0x6d, 0xf1, 0x37, 0xd5, 0x4c, 0x7b,
  0x20, 0xfd, 0x2b,
];

const randBytes3 = [
  0x67, 0xb9, 0x36, 0xdf, 0xa4, 0xda, 0x6a, 0xe8, //
  0xd3, 0xb3, 0xcd, 0xb3, 0xb9, 0x37, 0xf4, 0x02,
  0x7b, 0x0e, 0x3b,
];

// expected PBKDF2 inputs asserted by pbkdf2_dummy1, pbkdf2_dummy2 and pbkdf2_dummy3
const keyPw1 = "dd76e7359a0ded37cd0ff0f3c829a5ae01673300000000000000000000000000";
const keySalt1 = "504f4c5953454544206b657900ffffff00000000010000000000000000000000";
const keyPw2 = "5a2b02df7db21fcbe6ec6df137d54c7b20fd2b00000000000000000000000000";
const keySalt2 = "504f4c5953454544206b657900ffffff00000000330200000000000000000000";
const keyPw3 = "67b936dfa4da6ae8d3b3cdb3b937f4027b0e3b00000000000000000000000000";
const keySalt3 = "504f4c5953454544206b657900ffffff01000000f70300000100000000000000";
const maskPw = "70617373776f7264";
const maskSalt = "504f4c5953454544206d61736b00ffff";

const testKeyLen = 32;

Uint8List fromHex(String hex) => Uint8List.fromList(
    List.generate(hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));

Uint8List pbkdf2(Uint8List pw, Uint8List salt, int keyLen) {
  final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(salt, 10000, keyLen));
  return derivator.process(pw);
}

/// Mirrors [Polyseed.create] with injected random bytes and time
Polyseed createSeed(List<int> randBytes, int time, [int features = 0]) {
  final seedFeatures = PolyseedFeatures.make(features);
  if (!PolyseedFeatures.isSupported(seedFeatures)) {
    throw UnsupportedSeedFeatureException();
  }

  final secret = Uint8List.fromList(randBytes);
  secret[GFPoly.secretSize - 1] &= PolyseedStorage.clearMask;

  final data = PolyseedData(
      birthday: PolyseedBirthday.encode(time), features: seedFeatures, secret: secret, checksum: 0);
  final poly = GFPoly.fromPolyseedData(data);
  poly.encode();
  data.checksum = poly.coefficients[0];

  return Polyseed.load(PolyseedStorage.store(data));
}

/// Equivalent of polyseed_decode: detect the language, then decode
(PolyseedLang, Polyseed) decode(String phrase, PolyseedCoin coin) {
  final lang = PolyseedLang.getByPhrase(phrase);
  return (lang, Polyseed.decode(phrase, lang, coin));
}

PolyseedLang getLang(String name) => PolyseedLang.getByEnglishName(name);

void checkKey(Polyseed seed, PolyseedCoin coin, String pw, String salt) {
  expect(seed.generateKey(coin, testKeyLen).toHexString(),
      pbkdf2(fromHex(pw), fromHex(salt), testKeyLen).toHexString());
}

void checkFeatures(Polyseed seed, bool foo, bool bar, bool qux) {
  expect(seed.hasFeature(featureFoo), foo);
  expect(seed.hasFeature(featureBar), bar);
  expect(seed.hasFeature(featureQux), qux);
}

void checkBirthday(Polyseed seed, int time) {
  expect(seed.birthday, lessThanOrEqualTo(time));
  expect(seed.birthday + 2630000, greaterThan(time));
}

final throwsLang = throwsA(isA<UnknownLangException>());
final throwsNumWords = throwsA(isA<WordNumberException>());
final throwsChecksum = throwsA(isA<ChecksumMismatchException>());
final throwsUnsupported = throwsA(isA<UnsupportedSeedFeatureException>());

void main() {
  const monero = PolyseedCoin.POLYSEED_MONERO;
  const aeon = PolyseedCoin.POLYSEED_AEON;

  tearDown(() => PolyseedFeatures.enable(0));

  group('languages', () {
    test('num_langs', () => expect(PolyseedLang.languages, isNotEmpty));

    for (final lang in PolyseedLang.languages) {
      test('get_lang_name ${lang.nameEnglish}', () {
        expect(lang.name, isNotEmpty);
        expect(lang.nameEnglish, isNotEmpty);
      });
    }
  });

  group('seed 1', () {
    late Polyseed seed1;
    late Uint8List store1;

    setUp(() {
      seed1 = createSeed(randBytes1, seedTime1);
      store1 = seed1.save();
    });

    void checkKey1(Polyseed seed) => checkKey(seed, monero, keyPw1, keySalt1);

    test('birthday1', () => checkBirthday(seed1, seedTime1));

    test('features1', () {
      checkFeatures(seed1, false, false, false);
      expect(() => Polyseed.create(features: featureFoo), throwsUnsupported);
      expect(() => Polyseed.create(features: featureBar), throwsUnsupported);
      expect(() => Polyseed.create(features: featureQux), throwsUnsupported);
    });

    test('keygen1', () => checkKey1(seed1));

    test('store_load1', () => checkKey1(Polyseed.load(store1)));

    test('format', () {
      for (var i = 0; i < store1.length; ++i) {
        for (var j = 0; j < 8; ++j) {
          // flip j-th bit of the i-th byte
          final corrupted = Uint8List.fromList(store1);
          corrupted[i] ^= 1 << j;
          expect(() => Polyseed.load(corrupted), throwsA(isA<PolyseedException>()),
              reason: 'byte $i, bit $j');
        }
      }
    },
        skip:
            "F-08: the storage header check ignores the byte order, e.g. 'POLYSEED' -> 'PODYSEED' loads");

    test('encode_en', () => expect(seed1.encode(getLang("English"), monero), phraseEn1));

    test('load_encode_en',
        () => expect(Polyseed.load(store1).encode(getLang("English"), monero), phraseEn1));

    test('load_encode_ko', () {
      final phrase = Polyseed.load(storeLongPhrase).encode(getLang("Korean"), monero);
      expect(phrase.split(" "), hasLength(Polyseed.numberOfWords));
    });

    test('decode_en', () {
      final (lang, seed) = decode(phraseEn1, monero);
      expect(lang, getLang("English"));
      checkKey1(seed);
    });

    test('decode_en_prefix', () {
      final (lang, seed) = decode(phraseEn2, monero);
      expect(lang, getLang("English"));
      checkKey1(seed);
    }, skip: "F-06: 4-letter prefixes are not supported");

    test('decode_en_suffix1', () => expect(() => decode(phraseEn3, monero), throwsLang));

    test('decode_en_suffix2', () => expect(() => decode(phraseEn4, monero), throwsLang));

    test('decode_en_space', () {
      final (lang, seed) = decode(phraseEn5, monero);
      expect(lang, getLang("English"));
      checkKey1(seed);
    });

    test('decode_en_coin', () => expect(() => decode(phraseEn1, aeon), throwsChecksum));

    for (final lang in PolyseedLang.languages) {
      test('roundtrip1 ${lang.nameEnglish}', () {
        final phrase = seed1.encode(lang, monero);
        final (langOut, seed) = decode(phrase, monero);
        expect(langOut, lang);
        checkFeatures(seed, false, false, false);
        checkKey1(seed);
      });
    }
  });

  group('seed 2', () {
    late Polyseed seed2;

    setUp(() => seed2 = createSeed(randBytes2, seedTime2));

    void checkKey2(Polyseed seed) => checkKey(seed, monero, keyPw2, keySalt2);

    test('birthday2', () => checkBirthday(seed2, seedTime2));

    test('features2', () {
      checkFeatures(seed2, false, false, false);
      expect(PolyseedFeatures.enable(featureFoo | featureBar | featureQux), 3);
      checkFeatures(Polyseed.create(features: featureFoo), true, false, false);
      checkFeatures(Polyseed.create(features: featureBar), false, true, false);
      checkFeatures(Polyseed.create(features: featureQux), false, false, true);
      expect(PolyseedFeatures.enable(0), 0);
    });

    test('keygen2', () => checkKey2(seed2));

    test('store_load2', () => checkKey2(Polyseed.load(seed2.save())));

    test('encode_es', () => expect(seed2.encode(getLang("Spanish"), monero), phraseEs1));

    test('decode_es', () {
      final (lang, seed) = decode(seed2.encode(getLang("Spanish"), monero), monero);
      expect(lang, getLang("Spanish"));
      checkKey2(seed);
    });

    test('decode_es_noaccent', () {
      final (lang, seed) = decode(phraseEs2, monero);
      expect(lang, getLang("Spanish"));
      checkKey2(seed);
    }, skip: "F-06: accent-insensitive input is not supported");

    test('decode_es_prefix1', () {
      final (lang, seed) = decode(phraseEs3, monero);
      expect(lang, getLang("Spanish"));
      checkKey2(seed);
    }, skip: "F-06: 4-letter prefixes are not supported");

    test('decode_es_suffix', () => expect(() => decode(phraseEs4, monero), throwsLang));

    test('decode_es_prefix2', () => expect(() => decode(phraseEs5, monero), throwsLang));

    test('decode_es_prefix3', () {
      final (lang, seed) = decode(phraseEs6, monero);
      expect(lang, getLang("Spanish"));
      checkKey2(seed);
    }, skip: "F-06: 4-letter prefixes are not supported");

    test('decode_es_mult1', () {
      // POLYSEED_ERR_MULT_LANG: the phrase is valid in more than one language
      expect(() => decode(phraseEsMult, monero), throwsA(isA<PolyseedException>()));
    },
        skip:
            "F-10b: phrases valid in multiple languages are not detected (only passes today because prefixes are rejected)");

    test('decode_es_mult2', () {
      Polyseed.decode(phraseEsMult, getLang("Spanish"), monero);
    }, skip: "F-06: 4-letter prefixes are not supported");

    test('decode_zh_mult1', () {
      decode(phraseZhMult, monero);
    });

    test('decode_zh_mult2', () {
      final seedS = Polyseed.decode(phraseZhMult, getLang("Chinese (Simplified)"), monero);
      final seedT = Polyseed.decode(phraseZhMult, getLang("Chinese (Traditional)"), monero);
      expect(seedS.save(), seedT.save());
    });
  });

  group('seed 3', () {
    late Polyseed seed3;

    setUp(() {
      expect(PolyseedFeatures.enable(featureFoo | featureQux), 2);
      seed3 = createSeed(randBytes3, seedTime3, featureFoo);
    });

    void checkKey3(Polyseed seed) => checkKey(seed, aeon, keyPw3, keySalt3);

    test('features3a', () {
      Polyseed.create(features: featureFoo);
      expect(() => Polyseed.create(features: featureBar), throwsUnsupported);
      Polyseed.create(features: featureQux);
    });

    test('features3b', () => checkFeatures(seed3, true, false, false));

    test('birthday3', () => checkBirthday(seed3, seedTime3));

    test('keygen3', () => checkKey3(seed3));

    test('store_load3', () => checkKey3(Polyseed.load(seed3.save())));

    for (final lang in PolyseedLang.languages) {
      test('roundtrip3 ${lang.nameEnglish}', () {
        final phrase = seed3.encode(lang, aeon);
        final (langOut, seed) = decode(phrase, aeon);
        expect(langOut, lang);
        checkFeatures(seed, true, false, false);
        checkKey3(seed);
      });
    }

    test('encrypt / decrypt', () {
      final plain = seed3.save();

      expect(seed3.isEncrypted, isFalse);
      seed3.crypt(testPass);
      expect(seed3.isEncrypted, isTrue);

      // pbkdf2_dummy3: the mask is derived from the password and mask salt
      final mask = pbkdf2(fromHex(maskPw), fromHex(maskSalt), 32);
      final encrypted = seed3.save();
      for (var i = 0; i < GFPoly.secretSize; ++i) {
        var expected = plain[10 + i] ^ mask[i];
        if (i == GFPoly.secretSize - 1) expected &= PolyseedStorage.clearMask;
        expect(encrypted[10 + i], expected, reason: 'secret byte $i');
      }

      final phrase = seed3.encode(getLang("English"), aeon);

      final (_, seed) = decode(phrase, aeon);
      expect(seed.isEncrypted, isTrue);
      seed.crypt(testPass);
      expect(seed.isEncrypted, isFalse);
      checkKey3(seed);
    });
  });

  group('garbage', () {
    // Polyseed.decode requires an explicit language, the word count is
    // checked before the words are looked up
    test('decode_garbage1', () {
      expect(() => Polyseed.decode(phraseGarbage1, getLang("English"), monero), throwsNumWords);
    });

    test('decode_garbage2', () {
      expect(() => Polyseed.decode(phraseGarbage2, getLang("English"), monero), throwsNumWords);
    });
  });

  test('pbkdf2 mask password', () {
    expect(utf8.encode(testPass), fromHex(maskPw));
  });
}
