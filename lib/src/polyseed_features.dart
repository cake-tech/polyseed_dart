class PolyseedFeatures {
  static const int featureBits = 5;
  static const int internalFeatureBits = 2;
  static const int userFeatures = 3;
  static const int featuresBitMask = (1 << featureBits) - 1;
  static const int userFeaturesBitMask = (1 << userFeatures) - 1;
  static const int encryptedBitMask = 16;

  static int reservedFeatures = featuresBitMask ^ encryptedBitMask;

  static bool isSupported(int features) => (features & reservedFeatures) == 0;

  static bool isEncrypted(int features) => (features & encryptedBitMask) != 0;

  static int make(int userFeatures) => userFeatures & userFeaturesBitMask;

  static int get(int features, int mask) =>
      features & (mask & userFeaturesBitMask);

  static int enable(int mask) {
    var numEnabled = 0;
    reservedFeatures = featuresBitMask ^ encryptedBitMask;
    for (var i = 0; i < userFeatures; ++i) {
      final fmask = 1 << i;
      if ((mask & fmask) != 0) {
        reservedFeatures ^= fmask;
        numEnabled++;
      }
    }
    return numEnabled;
  }
}
