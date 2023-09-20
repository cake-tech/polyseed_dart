import 'package:polyseed/src/constants.dart';

class PolyseedBirthday {
  static const epoch = 1635768000; /* 1st November 2021 12:00 UTC */
  static const timeStep = 2629746; /* 1/12 of the Gregorian year */

  static int encode(int time) {
    if (time == -1 || time < epoch) {
      return 0;
    }
    return ((time - epoch) / timeStep).floor() & DATE_MASK;
  }

  static int decode(int birthday) => epoch + birthday * timeStep;
}
