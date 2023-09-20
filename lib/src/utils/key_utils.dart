String keyToHexString(List<int> key) {
  StringBuffer keyStream = StringBuffer();
  for (int i in key) {
    keyStream.write(i.toRadixString(16).padLeft(2, '0'));
  }
  return keyStream.toString();
}
