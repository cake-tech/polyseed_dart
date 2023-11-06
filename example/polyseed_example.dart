import 'dart:convert';

import 'package:polyseed/polyseed.dart';
import 'package:polyseed/src/utils/key_utils.dart';

void main() {
  var lang = PolyseedLang.getByName("English");

  var seed = Polyseed.create();
  var seedStr = seed.encode(lang, PolyseedCoin.POLYSEED_MONERO);
  print('Seed: $seedStr');

  var seed2 = Polyseed.decode(seedStr, lang, PolyseedCoin.POLYSEED_MONERO);
  print('seed2: ${seed2.encode(lang, PolyseedCoin.POLYSEED_MONERO)}');

  seed.crypt("CakeWallet");
  print(seed.isEncrypted); // true
  print('encrypted: ${seed.encode(lang, PolyseedCoin.POLYSEED_MONERO)}');

  seed.crypt("CakeWallet");
  print(seed.isEncrypted); // false
  print('decrypted: ${seed.encode(lang, PolyseedCoin.POLYSEED_MONERO)}');

  var seedFeatherStr =
      "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp";
  var seedFeather =
      Polyseed.decode(seedFeatherStr, lang, PolyseedCoin.POLYSEED_MONERO);

  var key = seedFeather.generateKey(PolyseedCoin.POLYSEED_MONERO, 32);
  print(seedFeather.birthday); // 1693622412
  print(keyToHexString(
      key)); // cbbd142d38347773d44aa830f5f01442aa6d0d3bb48571884479531248e6fa1c
  print(base64.encode(
      seedFeather.save())); //UE9MWVNFRUQWAP7QTFMwyWZ55hIVJOa7aluTxzP/Y3c=

  var seedLoaded = Polyseed.load(
      base64.decode("UE9MWVNFRUQWAP7QTFMwyWZ55hIVJOa7aluTxzP/Y3c="));
  print("seedLoaded: ${seedLoaded.encode(lang, PolyseedCoin.POLYSEED_MONERO)}");
}
