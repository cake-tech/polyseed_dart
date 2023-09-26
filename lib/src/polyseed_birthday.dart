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
