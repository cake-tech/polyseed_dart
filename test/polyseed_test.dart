import 'dart:convert';

import 'package:polyseed/polyseed.dart';
import 'package:polyseed/src/mnemonics/es_lang.dart';
import 'package:polyseed/src/mnemonics/jp_lang.dart';
import 'package:test/test.dart';

void main() {
  group('Polyseed', () {
    final coin = PolyseedCoin.POLYSEED_MONERO;
    final enLang = PolyseedLang.getByEnglishName("English");
    final expectedSeedString =
        "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp";
    final expectedKeyString =
        "cbbd142d38347773d44aa830f5f01442aa6d0d3bb48571884479531248e6fa1c";
    final expectedSerializedB64String =
        "UE9MWVNFRUQWAP7QTFMwyWZ55hIVJOa7aluTxzP/Y3c=";
    final expectedBirthday = 1693622412;
    final expectedLegacySeed =
        "avidly chlorine gave yeti ramped certain hybrid comb governing amply hinder pamphlet offend geometry narrate unopened robot epoxy annoyed glide ingested ascend were austere unopened";
    final expectedLegacySeedEs =
        "apoyo bestia desnudo revés meter beso este bonsái duelo algodón engaño llaga lámina diamante imperio pobre mortal cochino altar diva fábrica ángulo recurso aplicar algodón";

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
      expect(keyBytes.toHexString(), expectedKeyString);
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

    test('Normalize french seeds', () {
      final seedRaw =
          "merle bureau littoral vaisseau relatif exprimer voiture légal utile académie graffiti ultime substrat redouter oisillon soudure";

      expect(Polyseed.isValidSeed(seedRaw), true);
    });

    test('Normalize spanish seeds', () {
      final seedRaw =
          "remedio foca sujeto veneno bello humilde surco crear típico chacal célula empate moreno varón verde masa";

      expect(Polyseed.isValidSeed(seedRaw), true);
    });

    group('Convert to Legacy Seed', () {
      test('Generate a 25 Word english LegacySeed from a Seed', () {
        final seed = Polyseed.decode(expectedSeedString, enLang, coin);
        final keyBytes = seed.generateKey(coin, 32);
        final legacySeed = LegacySeedLang.getByName("English")
            .encodePhrase(keyBytes.toHexString());
        expect(legacySeed, expectedLegacySeed);
      });

      test('Generate a 25 Word spanish LegacySeed from a Seed', () {
        final seed = Polyseed.decode(expectedSeedString, enLang, coin);
        final keyBytes = seed.generateKey(coin, 32);
        final legacySeed = LegacySeedLang.getByEnglishName("Spanish")
            .encodePhrase(keyBytes.toHexString());
        expect(legacySeed, expectedLegacySeedEs);
      });

      test(
          'EdgeCase: Generate a 25 Word Spanish LegacySeed from a Seed with words smaller than the prefix length of the word list',
          () {
        final seed = Polyseed.decode(
            "remedio foca sujeto veneno bello humilde surco crear típico chacal célula empate moreno varón verde masa",
            esLang,
            coin);
        final keyBytes = seed.generateKey(coin, 32);
        final legacySeed = LegacySeedLang.getByEnglishName("Spanish")
            .encodePhrase(keyBytes.toHexString());
        expect(legacySeed,
            "remedio haz ébano lobo orden celda pezuña regreso ardilla estar acelga fallo punto nación hada quitar ancla obeso piedra pausa helio fuente joroba pista quitar");
      });

      test('Edge Case: Japanese seed with normal space separator', () {
        final seed =
            "せつぶん いせい てはい けんか たてる ねんきん くたびれる いよく やたい あいこくしん ちきゅう きたえる せたけ あひる かのう げつれい";

        final detectedLang = PolyseedLang.getByPhrase(seed);
        expect(detectedLang, jpLang);

        final isValidSeed = Polyseed.isValidSeed(seed);
        expect(isValidSeed, true);

        final key = Polyseed.decode(seed, jpLang, coin)
            .generateKey(coin, 32)
            .toHexString();

        expect(key,
            "340593b3fd0b2670b4727b6a9b64f3f817e2b97fcb26ea3ae8467234eb857f95");
      });
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
