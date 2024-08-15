import 'dart:convert';

import 'package:hashlib/hashlib.dart';
import 'package:polyseed/src/mnemonics/legacy/de_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/en_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/eo_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/es_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/fr_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/it_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/jbo_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/jp_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/nl_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/pt_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/ru_lang.dart';
import 'package:polyseed/src/mnemonics/legacy/zh_s_lang.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_extension.dart';

class LegacySeedLang {
  /// The native name of the language
  final String name;

  /// The english name of the language
  final String nameEnglish;

  /// The string seperator used to join and separate the phrase
  final String separator;

  final int prefixLength;

  /// The List of words available in the language
  final List<String> words;

  const LegacySeedLang(
      {required this.name,
      required this.nameEnglish,
      required this.separator,
      required this.prefixLength,
      required this.words});

  /// A list of all available [LegacySeedLang] instances
  static const languages = [
    deLegacyLang,
    enLegacyLang,
    eoLegacyLang,
    esLegacyLang,
    frLegacyLang,
    itLegacyLang,
    jboLegacyLang,
    jpLegacyLang,
    nlLegacyLang,
    ptLegacyLang,
    ruLegacyLang,
    zhsLegacyLang
  ];

  /// Get the [LegacySeedLang] by it's name eg. "Deutsch"
  static LegacySeedLang getByName(String name) =>
      languages.firstWhere((e) => e.name.toLowerCase() == name.toLowerCase());

  /// Get the [LegacySeedLang] by it's english name eg. "Chinese (Simplified)"
  static LegacySeedLang getByEnglishName(String englishName) =>
      languages.firstWhere((e) => e.nameEnglish.toLowerCase() == englishName.toLowerCase());

  /// Get the [LegacySeedLang] using the words of [phrase]
  static LegacySeedLang getByPhrase(String phrase) {
    for (var language in languages) {
      final phraseWords = phrase.split(language.separator);
      if (language.words.containsAll(phraseWords)) {
        return language;
      }
    }
    throw UnknownLangException();
  }

  /// Check if the given words of a [phrase] are from a valid [LegacySeedLang]
  static bool isValidPhrase(String phrase) {
    try {
      getByPhrase(phrase);
      return true;
    } on UnknownLangException catch (_) {
      return false;
    }
  }

  /// Encode a seed [secretSpendKey] into a valid seed phrase
  String encodePhrase(String secretSpendKey) {
    final out = <String>[];
    final n = words.length;

    for (var j = 0; j < secretSpendKey.length; j += 8) {
      secretSpendKey = secretSpendKey.substring(0, j) +
          _swapEndian_4byte(secretSpendKey.substring(j, j + 8)) +
          secretSpendKey.substring(j + 8);
    }

    for (var i = 0; i < secretSpendKey.length; i += 8) {
      final x = int.parse(secretSpendKey.substring(i, i + 8), radix: 16);
      final w1 = (x % n);
      final w2 = (x ~/ n + w1) % n;
      final w3 = ((x ~/ n) ~/ n + w2) % n;
      out.addAll([words[w1], words[w2], words[w3]]);
    }

    if (prefixLength > 0) {
      out.add(out[_getChecksumIndex(out, prefixLength)]);
    }

    return out.join(separator);
  }

  String _swapEndian_4byte(String str) {
    if (str.length != 8) {
      throw ArgumentError('Invalid input length: ${str.length}');
    }

    return str.substring(6, 8) +
        str.substring(4, 6) +
        str.substring(2, 4) +
        str.substring(0, 2);
  }

  int _getChecksumIndex(List<String> words, int prefixLen) {
    var trimmedWords = '';
    for (var i = 0; i < words.length; i++) {
      final actualPrefixLength =
          words[i].length > prefixLen ? prefixLen : words[i].length;
      trimmedWords += words[i].substring(0, actualPrefixLength);
    }

    var checksum = trimmedWords.crc32code(Encoding.getByName('utf-8'));
    var index = (checksum % words.length);
    return index;
  }
}
