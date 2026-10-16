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
 * Ported from tevador/polyseed (src/birthday.h) to Dart by Cake Labs LLC.
 */

class PolyseedBirthday {
  /// The epoch for Polyseed birthdays. 1st November 2021 12:00 UTC
  static const epoch = 1635768000;

  /// The time step for [PolyseedBirthday]. 1/12 of the Gregorian year
  static const timeStep = 2629746;

  /// The number of bits used for the birthday
  static const int dateBits = 10;

  /// The bitmask used to extract the birthday
  static const dateBitMask = (1 << dateBits) - 1;

  /// Encodes a given epoch timestamp in seconds as a [PolyseedBirthday].
  ///
  /// If the given time is before the [PolyseedBirthday.epoch], or if it is
  /// equal to -1, then 0 will be returned.
  static int encode(int time) {
    if (time == -1 || time < epoch) {
      return 0;
    }
    return ((time - epoch) / timeStep).floor() & dateBitMask;
  }

  /// Decodes a encoded [PolyseedBirthday] into a valid epoch timestamp in seconds.
  static int decode(int birthday) => epoch + birthday * timeStep;
}
