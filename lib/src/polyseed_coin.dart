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
 * Ported from tevador/polyseed (src/polyseed.h) to Dart by Cake Labs LLC.
 */

enum PolyseedCoin {
  POLYSEED_MONERO,
  POLYSEED_AEON,
  POLYSEED_WOWNERO,
  POLYSEED_BELDEX;
  // Other coins should be added here sequentially.
  // The maximum supported value is 2047.
  // When adding a new coin, please open a pull request:
  // https://github.com/tevador/polyseed
  // https://github.com/cake-tech/polyseed_dart
}
