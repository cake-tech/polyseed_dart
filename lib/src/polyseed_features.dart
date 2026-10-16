/*
 * Copyright (c) 2020-2026 tevador <tevador@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Ported from tevador/polyseed (src/features.c) to Dart by Cake Labs LLC.
 */

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
