import 'dart:convert';

import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/utils/key_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Polyseed', () {
    final coin = PolyseedCoin.POLYSEED_MONERO;
    final expectedSeedString =
        "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp";
    final expectedKeyString =
        "cbbd142d38347773d44aa830f5f01442aa6d0d3bb48571884479531248e6fa1c";
    final expectedSerializedB64String =
        "UE9MWVNFRUQWAP7QTFMwyWZ55hIVJOa7aluTxzP/Y3c=";
    final expectedBirthday = 1693622412;

    test('Decode and test for correct birthday', () {
      final seed = Polyseed.decode(expectedSeedString, enLang, coin);
      expect(seed.birthday, expectedBirthday);
    });

    test('Decode and encode seed', () {
      final seed = Polyseed.decode(expectedSeedString, enLang, coin);
      final seedStr = seed.encode(enLang, coin);
      expect(seedStr, expectedSeedString);
    });

    test('Generate a Key from a Seed', () {
      final seed = Polyseed.decode(expectedSeedString, enLang, coin);
      final keyBytes = seed.generateKey(coin, 32);
      expect(keyToHexString(keyBytes), expectedKeyString);
    });

    test("Encrypt / Decrypt Seed", () {
      final seed = Polyseed.decode(expectedSeedString, enLang, coin);

      seed.crypt("CakeWallet");
      expect(seed.isEncrypted, isTrue);

      seed.crypt("CakeWallet");
      expect(seed.isEncrypted, isFalse);

      final seedStrDec = seed.encode(enLang, coin);
      expect(seedStrDec, expectedSeedString);
    });

    test('Serialize Seed', () {
      final seed = Polyseed.decode(expectedSeedString, enLang, coin);
      final serializedSeed = seed.save();

      expect(base64.encode(serializedSeed), expectedSerializedB64String);
    });

    test('Deserialize Seed', () {
      final seed = Polyseed.load(base64.decode(expectedSerializedB64String));

      expect(seed.birthday, expectedBirthday);
    });

    test('Create, Encode, Decode, Serialize, Deserialize', () {
      final coin = PolyseedCoin.POLYSEED_MONERO;
      final seed = Polyseed.create();

      final seedStr = seed.encode(enLang, coin);
      expect(Polyseed.decode(seedStr, enLang, coin).birthday, seed.birthday);

      final serializedSeed = seed.save();
      expect(Polyseed.load(serializedSeed).birthday, seed.birthday);
    });
  });
}

class PolyseedExpectedOutcome {
  String expectedSeedString;
  String expectedKeyString;
  String expectedSerializedB64String;
  int expectedBirthday;
  PolyseedCoin coin;

  PolyseedExpectedOutcome({
    required this.expectedSeedString,
    required this.expectedKeyString,
    required this.expectedSerializedB64String,
    required this.expectedBirthday,
    this.coin = PolyseedCoin.POLYSEED_MONERO,
  });
}
