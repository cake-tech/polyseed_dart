import 'package:polyseed/src/constants.dart';

class PolyseedFeatures {
  static int reservedFeatures = FEATURE_MASK ^ ENCRYPTED_MASK;

  static bool isSupported(int features) => (features & reservedFeatures) == 0;

  static bool isEncrypted(int features) => (features & ENCRYPTED_MASK) != 0;

  static int make(int userFeatures) => userFeatures & USER_FEATURES_MASK;

  static int get(int features, int mask) =>
      features & (mask & USER_FEATURES_MASK);

  static int enable(int mask) {
    var numEnabled = 0;
    reservedFeatures = FEATURE_MASK ^ ENCRYPTED_MASK;
    for (var i = 0; i < USER_FEATURES; ++i) {
      final fmask = 1 << i;
      if ((mask & fmask) != 0) {
        reservedFeatures ^= fmask;
        numEnabled++;
      }
    }
    return numEnabled;
  }
}
