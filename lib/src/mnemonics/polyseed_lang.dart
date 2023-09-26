import 'package:polyseed/src/mnemonics/cs_lang.dart';
import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/mnemonics/es_lang.dart';
import 'package:polyseed/src/mnemonics/fr_lang.dart';
import 'package:polyseed/src/mnemonics/it_lang.dart';
import 'package:polyseed/src/mnemonics/jp_lang.dart';
import 'package:polyseed/src/mnemonics/ko_lang.dart';
import 'package:polyseed/src/mnemonics/pt_lang.dart';
import 'package:polyseed/src/mnemonics/zh_s_lang.dart';
import 'package:polyseed/src/mnemonics/zh_t_lang.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_extension.dart';

class PolyseedLang {
  /// The native name of the language
  final String name;

  /// The english name of the language
  final String nameEnglish;

  /// The string seperator used to join and separate the phrase
  final String separator;

  final bool isSorted;
  final bool hasPrefix;
  final bool hasAccents;
  final bool compose;

  /// The List of BIP-32 words available in the language
  final List<String> words;

  const PolyseedLang(
      {required this.name,
      required this.nameEnglish,
      required this.separator,
      required this.isSorted,
      required this.hasPrefix,
      required this.hasAccents,
      required this.compose,
      required this.words});

  /// A list of all available [PolyseedLang] instances
  static const languages = [
    csLang,
    enLang,
    esLang,
    frLang,
    itLang,
    jpLang,
    koLang,
    ptLang,
    zhsLang,
    zhtLang
  ];

  /// Get the [PolyseedLang] by it's name eg. "español"
  static PolyseedLang getByName(String name) =>
      languages.firstWhere((e) => e.name == name);

  /// Get the [PolyseedLang] by it's english name eg. "Chinese (Simplified)"
  static PolyseedLang getByEnglishName(String englishName) =>
      languages.firstWhere((e) => e.nameEnglish == englishName);

  /// Get the [PolyseedLang] using the words of [phrase]
  static PolyseedLang getByPhrase(String phrase) {
    for (var language in languages) {
      final phraseWords = phrase.split(language.separator);
      if (language.words.containsAll(phraseWords)) {
        return language;
      }
    }
    throw UnknownLangException();
  }

  /// Check if the given words of a [phrase] are from a valid BIP-32 [PolyseedLang]
  static bool isValidPhrase(String phrase) {
    try {
      getByPhrase(phrase);
      return true;
    } on UnknownLangException catch (_) {
      return false;
    }
  }

  /// Decode a valid seed [phrase] into it's coefficients
  List<int> decodePhrase(String phrase) =>
      phrase.split(separator).map((e) => words.indexOf(e)).toList();

  /// Encode a seed [coefficients] into a valid seed phrase
  String encodePhrase(List<int> coefficients) =>
      coefficients.map((e) => words[e]).join(separator);
}
