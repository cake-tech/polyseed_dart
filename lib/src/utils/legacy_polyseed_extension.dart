import 'package:polyseed/src/mnemonics/legacy/legacy_seed_lang.dart';
import 'package:polyseed/src/polyseed.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/utils/string_uint8list_extension.dart';

extension LegacySeedConversion on Polyseed {
  String toLegacySeed(LegacySeedLang lang,
      {PolyseedCoin coin = PolyseedCoin.POLYSEED_MONERO, int keySize = 32}) {
    final key = generateKey(coin, keySize);
    return lang.encodePhrase(key.toHexString());
  }
}
