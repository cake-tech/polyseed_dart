import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/utils/key_utils.dart';
import 'package:test/test.dart';

void main() {
  final polyseedExpectedOutcomes = [
    PolyseedExpectedOutcome(
      expectedSeedString:
          "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp",
      expectedKeyString:
          "cbbd142d38347773d44aa830f5f01442aa6d0d3bb48571884479531248e6fa1c",
      expectedBirthday: 1693622412,
    ),
  ];

  group('Decoding', () {
    test('Decode and test for correct birthday', () {
      final outcome = polyseedExpectedOutcomes.first;
      final seed =
          Polyseed.decode(outcome.expectedSeedString, enLang, outcome.coin);
      expect(seed.birthday, outcome.expectedBirthday);
    });
  });

  group('Encoding', () {
    test('', () {
      final outcome = polyseedExpectedOutcomes.first;
      final seed =
          Polyseed.decode(outcome.expectedSeedString, enLang, outcome.coin);
      final seedStr = seed.encode(enLang, outcome.coin);
      expect(seedStr, outcome.expectedSeedString);
    });
  });

  group('Key Generation', () {
    test('Generate a Key from a Seed', () {
      final outcome = polyseedExpectedOutcomes.first;
      final seed =
          Polyseed.decode(outcome.expectedSeedString, enLang, outcome.coin);
      final keyBytes = seed.generateKey(outcome.coin, 32);
      expect(keyToHexString(keyBytes), outcome.expectedKeyString);
    });
  });

  test('Create, Encode, Decode', () {
    final coin = PolyseedCoin.POLYSEED_MONERO;
    Polyseed seed;
    String seedStr;
    seed = Polyseed.create();
    seedStr = seed.encode(enLang, coin);
    expect(Polyseed.decode(seedStr, enLang, coin).birthday, seed.birthday);
  });

  test("Encrypt / Decrypt Seed", () {
    final outcome = polyseedExpectedOutcomes.first;
    final seed =
        Polyseed.decode(outcome.expectedSeedString, enLang, outcome.coin);

    seed.crypt("CakeWallet");
    expect(seed.isEncrypted, isTrue);

    seed.crypt("CakeWallet");
    expect(seed.isEncrypted, isFalse);

    final seedStrDec = seed.encode(enLang, outcome.coin);
    expect(seedStrDec, outcome.expectedSeedString);
  });
}

class PolyseedExpectedOutcome {
  String expectedSeedString;
  String expectedKeyString;
  int expectedBirthday;
  PolyseedCoin coin;

  PolyseedExpectedOutcome({
    required this.expectedSeedString,
    required this.expectedKeyString,
    required this.expectedBirthday,
    this.coin = PolyseedCoin.POLYSEED_MONERO,
  });
}
