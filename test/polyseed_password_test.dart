import 'dart:convert';

import 'package:polyseed/polyseed.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

void main() {
  const phrase =
      "unaware yard donate shallow slot sing oil oxygen loyal bench near hill surround forum execute lamp";
  final coin = PolyseedCoin.POLYSEED_MONERO;
  final english = PolyseedLang.getByEnglishName("English");

  String encryptedPhrase(String password) {
    final seed = Polyseed.decode(phrase, english, coin);
    seed.crypt(password);
    return seed.encode(english, coin);
  }

  test('precomposed and decomposed passphrases encrypt the same phrase', () {
    const precomposed = 'contraseña';
    final decomposed = unorm.nfkd(precomposed);
    expect(decomposed, isNot(precomposed));
    expect(encryptedPhrase(precomposed), encryptedPhrase(decomposed));
  });

  test('Hangul and kana passphrases match their NFKD form', () {
    for (final password in ['비밀번호', 'パスワード', 'pässwörd']) {
      final decomposed = unorm.nfkd(password);
      expect(decomposed, isNot(password));
      expect(encryptedPhrase(password), encryptedPhrase(decomposed));
    }
  });

  test('an ASCII passphrase longer than 575 bytes uses the first 575', () {
    final prefix = 'a' * 575;
    expect(encryptedPhrase(prefix), encryptedPhrase('${prefix}b'));
  });

  test('NFKD output longer than 575 bytes is rejected', () {
    final password = 'ñ' * 200;
    expect(utf8.encode(unorm.nfkd(password)).length, greaterThan(575));
    expect(
      () => encryptedPhrase(password),
      throwsA(isA<PasswordTooLongException>()),
    );
  });
}
