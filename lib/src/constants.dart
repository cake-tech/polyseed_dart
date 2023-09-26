import 'package:polyseed/src/polyseed.dart';

const int SECRET_BITS = 150;
const int SECRET_SIZE = 19; // (SECRET_BITS + CHAR_BIT - 1) / CHAR_BIT;

const int CLEAR_BITS = 2; // (SECRET_SIZE) * (CHAR_BIT) - (SECRET_BITS);
const int CLEAR_MASK = ~(((1 << (CLEAR_BITS)) - 1) << (charBit - (CLEAR_BITS)));

const int charBit = 8; // the number of bits in char

const int POLY_NUM_CHECK_DIGITS = 1;

const int SHARE_BITS = 10; // bits of the secret per word
const int DATA_WORDS = Polyseed.numberOfWords - POLY_NUM_CHECK_DIGITS;

const DATE_BITS = 10;
const DATE_MASK = (1 << DATE_BITS) - 1;
