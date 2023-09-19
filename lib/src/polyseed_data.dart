import 'dart:typed_data';

class PolyseedData {
  int birthday;
  int features;

  Uint8List secret;
  int checksum;

  PolyseedData(
      {required this.birthday,
      required this.features,
      required this.secret,
      required this.checksum});

  PolyseedData.empty()
      : birthday = 0,
        features = 0,
        secret = Uint8List(32),
        checksum = 0;
}
