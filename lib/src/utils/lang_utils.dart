import 'package:polyseed/src/mnemonics/cs_lang.dart';
import 'package:polyseed/src/mnemonics/en_lang.dart';
import 'package:polyseed/src/mnemonics/es_lang.dart';
import 'package:polyseed/src/mnemonics/fr_lang.dart';
import 'package:polyseed/src/mnemonics/it_lang.dart';
import 'package:polyseed/src/mnemonics/jp_lang.dart';
import 'package:polyseed/src/mnemonics/ko_lang.dart';
import 'package:polyseed/src/mnemonics/polyseed_lang.dart';
import 'package:polyseed/src/mnemonics/pt_lang.dart';
import 'package:polyseed/src/mnemonics/zh_s_lang.dart';
import 'package:polyseed/src/mnemonics/zh_t_lang.dart';
import 'package:polyseed/src/utils/exceptions.dart';
import 'package:polyseed/src/utils/list_utils.dart';

final languages = [
  CsLang(),
  EnLang(),
  EsLang(),
  FrLang(),
  ItLang(),
  JpLang(),
  KoLang(),
  PtLang(),
  ZhSLang(),
  ZhTLang()
];

int polyseed_get_num_langs() => languages.length;

PolyseedLang polyseed_get_lang(int i) => languages[i];

String polyseed_get_lang_name(PolyseedLang lang) => lang.name;

String polyseed_get_lang_name_en(PolyseedLang lang) => lang.nameEn;

// ToDo?
// const int NUM_CHARS_PREFIX = 4;
//
// typedef int polyseed_cmp(const void* a, const void* b);
//
// int lang_search(PolyseedLang lang, String word,
// polyseed_cmp* cmp) {
// if (lang->is_sorted) {
// const char** match = bsearch(&word, &lang->words[0],
// POLYSEED_LANG_SIZE, sizeof(const char*), cmp);
// if (match != NULL) {
// return match - &lang->words[0];
// }
// return -1;
// }
// else {
// for (int j = 0; j < POLYSEED_LANG_SIZE; ++j) {
// if (0 == cmp(&word, &lang->words[j])) {
// return j;
// }
// }
// return -1;
// }
// }
//
// static int compare_str(const char* key, const char* elm) {
// for (;;) {
// if (*key == '\0' || *key != *elm) {
// break;
// }
// ++key;
// ++elm;
// }
// return (*key > *elm) - (*key < *elm);
// }
//
// static int compare_str_wrap(const void* a, const void* b) {
// const char* key = *(const char**)a;
// const char* elm = *(const char**)b;
// return compare_str(key, elm);
// }
//
// static int compare_prefix(const char* key, const char* elm, int n) {
// for (int i = 1; ; ++i) {
// if (*key == '\0') {
// break;
// }
// if (i >= n && key[1] == '\0') {
// break;
// }
// if (*key != *elm) {
// break;
// }
// ++key;
// ++elm;
// }
// return (*key > *elm) - (*key < *elm);
// }
//
// static int compare_prefix_wrap(const void* a, const void* b) {
// const char* key = *(const char**)a;
// const char* elm = *(const char**)b;
// return compare_prefix(key, elm, NUM_CHARS_PREFIX);
// }
//
// static int compare_str_noaccent(const char* key, const char* elm) {
// for (;;) {
// while (*key < 0) { /* skip non-ASCII */
// ++key;
// }
// while (*elm < 0) { /* skip non-ASCII */
// ++elm;
// }
// if (*key == '\0' || *key != *elm) {
// break;
// }
// ++key;
// ++elm;
// }
// return (*key > *elm) - (*key < *elm);
// }
//
// static int compare_str_noaccent_wrap(const void* a, const void* b) {
// const char* key = *(const char**)a;
// const char* elm = *(const char**)b;
// return compare_str_noaccent(key, elm);
// }
//
// static int compare_prefix_noaccent(const char* key, const char* elm, int n) {
// for (int i = 1; ; ++i) {
// while (*key < 0) { /* skip non-ASCII */
// ++key;
// }
// while (*elm < 0) { /* skip non-ASCII */
// ++elm;
// }
// if (*key == '\0') {
// break;
// }
// if (i >= n && key[1] == '\0') {
// break;
// }
// if (*key != *elm) {
// break;
// }
// ++key;
// ++elm;
// }
// while (*key < 0) { /* skip non-ASCII */
// ++key;
// }
// while (*elm < 0) { /* skip non-ASCII */
// ++elm;
// }
// return (*key > *elm) - (*key < *elm);
// }
//
// static int compare_prefix_noaccent_wrap(const void* a, const void* b) {
// const char* key = *(const char**)a;
// const char* elm = *(const char**)b;
// return compare_prefix_noaccent(key, elm, NUM_CHARS_PREFIX);
// }
//
// static polyseed_cmp* get_comparer(PolyseedLang lang) {
// if (lang->has_prefix) {
// if (lang->has_accents) {
// return &compare_prefix_noaccent_wrap;
// }
// else {
// return &compare_prefix_wrap;
// }
// }
// else {
// if (lang->has_accents) {
// return &compare_str_noaccent_wrap;
// }
// else {
// return &compare_str_wrap;
// }
// }
// }
//
// int polyseed_lang_find_word(PolyseedLang lang, String word) {
// polyseed_cmp* cmp = get_comparer(lang);
// return lang_search(lang, word, cmp);
// }

PolyseedLang polyseed_get_phrase_lang(List <String> phrase) {
for (var language in languages) {
if (language.words.containsAll(phrase)) {
return language;
}
}
throw UnknownLangException();
}

List<int> polyseed_phrase_decode(List <String> phrase) {
  final lang = polyseed_get_phrase_lang(phrase);
  return phrase.map((e) => lang.words.indexOf(e)).toList();
}

// ToDo
// void polyseed_lang_check(const polyseed_lang* lang) {
// /* check the language is sorted correctly */
// if (lang->is_sorted) {
// polyseed_cmp* cmp = get_comparer(lang);
// const char* prev = lang->words[0];
// for (int i = 1; i < POLYSEED_LANG_SIZE; ++i) {
// const char* word = lang->words[i];
// assert(("incorrectly sorted wordlist", cmp(&prev, &word) < 0));
// prev = word;
// }
// }
// /* all words must be in NFKD */
// for (int i = 0; i < POLYSEED_LANG_SIZE; ++i) {
// polyseed_str norm;
// const char* word = lang->words[i];
// UTF8_DECOMPOSE(word, norm);
// assert(("incorrectly normalized wordlist", !strcmp(word, norm)));
// }
// /* accented languages must be composed */
// assert(!lang->has_accents || lang->compose);
// /* normalized separator must be a space */
// polyseed_str separator;
// UTF8_DECOMPOSE(lang->separator, separator);
// assert(!strcmp(" ", separator));
// }
