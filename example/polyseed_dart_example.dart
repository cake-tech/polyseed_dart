import 'package:polyseed/polyseed_dart.dart';
import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/polyseed_coin.dart';
import 'package:polyseed/src/utils/key_utils.dart';

void main() {
  var seed = polyseedCreate(0);
  var seedStr = polyseed_encode(seed, EnLang(), PolyseedCoin.POLYSEED_MONERO);
  print('Seed: $seedStr');

  var seed2 = polyseedDecode(seedStr, EnLang(), PolyseedCoin.POLYSEED_MONERO);
  print(
      'seed2: ${polyseed_encode(seed2, EnLang(), PolyseedCoin.POLYSEED_MONERO)}');

  var seedEnc = polyseed_crypt(seed, "CakeWallet");
  print(polyseed_is_encrypted(seedEnc));
  print(
      'seedEnc: ${polyseed_encode(seedEnc, EnLang(), PolyseedCoin.POLYSEED_MONERO)}');


  var seedDec = polyseed_crypt(seedEnc, "CakeWallet");
  print(polyseed_is_encrypted(seedDec));
  print(
      'seedEnc: ${polyseed_encode(seedDec, EnLang(), PolyseedCoin.POLYSEED_MONERO)}');

  var seedFeatherStr = "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp";
  var seedFeather = polyseedDecode(seedFeatherStr, EnLang(), PolyseedCoin.POLYSEED_MONERO);

  var key = polyseed_keygen(seedFeather, PolyseedCoin.POLYSEED_MONERO, 32);
  print(polyseed_get_birthday(seedFeather));
  print(keyToHexString(key));
}


