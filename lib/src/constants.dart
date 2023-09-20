const int POLYSEED_NUM_WORDS = 16;
const int KDF_NUM_ITERATIONS = 10000;

const int SECRET_BUFFER_SIZE = 32;
const int SECRET_BITS = 150;
const int SECRET_SIZE = 19; // (SECRET_BITS + CHAR_BIT - 1) / CHAR_BIT; /* 19 */

const int CLEAR_BITS = 2; // (SECRET_SIZE) * (CHAR_BIT) - (SECRET_BITS); /* 2 */
const int CLEAR_MASK =
    ~(((1 << (CLEAR_BITS)) - 1) << (CHAR_BIT - (CLEAR_BITS)));

const int CHAR_BIT = 8;

const int GF_BITS = 11;
const int GF_SIZE = 1 << GF_BITS;
const int GF_MASK = GF_SIZE - 1;
const int POLY_NUM_CHECK_DIGITS = 1;

const int SHARE_BITS = 10; /* bits of the secret per word */
const int DATA_WORDS = POLYSEED_NUM_WORDS - POLY_NUM_CHECK_DIGITS;

const DATE_BITS = 10;
const DATE_MASK = (1 << DATE_BITS) - 1;

const int FEATURE_BITS = 5;
const int FEATURE_MASK = (1 << FEATURE_BITS) - 1;
const int INTERNAL_FEATURES = 2;
const int USER_FEATURES = 3;
const int USER_FEATURES_MASK = (1 << USER_FEATURES) - 1;
const int ENCRYPTED_MASK = 16;
