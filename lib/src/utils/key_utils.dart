import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';

const int KDF_NUM_ITERATIONS = 10000;

Uint8List generateKey(Uint8List password, Uint8List salt, int keySize) {
  var derivator = KeyDerivator('SHA-256/HMAC/PBKDF2');
  var params = Pbkdf2Parameters(salt, KDF_NUM_ITERATIONS, keySize);
  derivator.init(params);
  return derivator.process(password);
}

String keyToHexString(List<int> key) {
  StringBuffer keyStream = StringBuffer();
  for (int i in key) {
    keyStream.write(i.toRadixString(16).padLeft(2, '0'));
  }
  return keyStream.toString();
}
