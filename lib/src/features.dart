const int FEATURE_BITS = 5;
const int FEATURE_MASK = (1 << FEATURE_BITS) - 1;
const int INTERNAL_FEATURES = 2;
const int USER_FEATURES = 3;
const int USER_FEATURES_MASK = (1 << USER_FEATURES) - 1;
const int ENCRYPTED_MASK = 16;
int reservedFeatures = FEATURE_MASK ^ ENCRYPTED_MASK;

int makeFeatures(int userFeatures) => userFeatures & USER_FEATURES_MASK;

int getFeatures(int features, int mask) =>
    features & (mask & USER_FEATURES_MASK);

bool isEncrypted(int features) => (features & ENCRYPTED_MASK) != 0;

bool polyseedFeaturesSupported(int features) =>
    (features & reservedFeatures) == 0;

int polyseedEnableFeatures(int mask) {
  int numEnabled = 0;
  reservedFeatures = FEATURE_MASK ^ ENCRYPTED_MASK;
  for (int i = 0; i < USER_FEATURES; ++i) {
    int fmask = 1 << i;
    if ((mask & fmask) != 0) {
      reservedFeatures ^= fmask;
      numEnabled++;
    }
  }
  return numEnabled;
}
