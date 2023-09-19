const EPOCH = 1635768000;  /* 1st November 2021 12:00 UTC */
const TIME_STEP = 2629746; /* 30.436875 days = 1/12 of the Gregorian year */

const DATE_BITS = 10;
const DATE_MASK = (1 << DATE_BITS) - 1;


int birthdayEncode(int time) {
  if (time == -1 || time < EPOCH) {
    return 0;
  }
  return ((time - EPOCH) / TIME_STEP).floor() & DATE_MASK;
}

int birthdayDecode(int birthday) => EPOCH + birthday * TIME_STEP;
