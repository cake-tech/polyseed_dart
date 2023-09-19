import 'package:polyseed/polyseed_dart.dart';
import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/polyseed_data.dart';
import 'package:polyseed/src/utils/key_utils.dart';
import 'package:test/test.dart';

final enLang = EnLang();

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
          polyseedDecode(outcome.expectedSeedString, enLang, outcome.coin);
      expect(polyseed_get_birthday(seed), outcome.expectedBirthday);
    });
  });

  group('Encoding', () {
    test('', () {
      final outcome = polyseedExpectedOutcomes.first;
      final seed =
          polyseedDecode(outcome.expectedSeedString, enLang, outcome.coin);
      final seedStr = polyseed_encode(seed, enLang, outcome.coin);
      expect(seedStr, outcome.expectedSeedString);
    });
  });

  group('Key Generation', () {
    test('Generate a Key from a Seed', () {
      final outcome = polyseedExpectedOutcomes.first;
      final seed =
          polyseedDecode(outcome.expectedSeedString, enLang, outcome.coin);
      final keyBytes = polyseed_keygen(seed, outcome.coin, 32);
      expect(keyToHexString(keyBytes), outcome.expectedKeyString);
    });
  });

  test('Create, Encode, Decode', () {
    final coin = PolyseedCoin.POLYSEED_MONERO;
    PolyseedData seed;
    String seedStr;
      seed = polyseedCreate(0);
      seedStr = polyseed_encode(seed, enLang, coin);
      expect(polyseedDecode(seedStr, enLang, coin).birthday, seed.birthday);
  });

  test("Encrypt / Decrypt Seed", () {
    final outcome = polyseedExpectedOutcomes.first;
    final seed = polyseedDecode(outcome.expectedSeedString, enLang, outcome.coin);

    var seedEnc = polyseed_crypt(seed, "CakeWallet");
    expect(polyseed_is_encrypted(seedEnc), isTrue);

    var seedDec = polyseed_crypt(seedEnc, "CakeWallet");
    expect(polyseed_is_encrypted(seedDec), isFalse);

    final seedStrDec = polyseed_encode(seedDec, enLang, outcome.coin);
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
