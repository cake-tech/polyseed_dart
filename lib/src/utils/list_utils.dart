extension EqualList on List {
  bool equals(List list) {
    if (length != list.length) return false;
    return every((item) => list.contains(item));
  }

  bool notEquals(List list) => !equals(list);

  bool containsAll(List list) {
    for (var value in list) {
      if (!contains(value)) {
        return false;
      }
    }
    return true;
  }
}
