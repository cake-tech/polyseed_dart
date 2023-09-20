import 'package:polyseed/src/mnemonics.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_utils.dart';

class PolyseedLang {
  final String name;
  final String nameEnglish;
  final String separator;
  final bool isSorted;
  final bool hasPrefix;
  final bool hasAccents;
  final bool compose;
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

  static PolyseedLang getByIndex(int i) => languages[i];

  static PolyseedLang getByName(String name) =>
      languages.firstWhere((e) => e.name == name);

  static PolyseedLang getByEnglishName(String englishName) =>
      languages.firstWhere((e) => e.nameEnglish == englishName);

  static PolyseedLang getByPhrase(String phrase) {
    for (var language in languages) {
      final phraseWords = phrase.split(language.separator);
      if (language.words.containsAll(phraseWords)) {
        return language;
      }
    }
    throw UnknownLangException();
  }

  List<int> decodePhrase(String phrase) {
    final phraseWords = phrase.split(separator);
    return phraseWords.map((e) => words.indexOf(e)).toList();
  }

  String encode(List<int> seedCoeff) =>
      seedCoeff.map((e) => words[e]).join(separator);
}
