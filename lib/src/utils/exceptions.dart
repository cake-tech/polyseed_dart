abstract class PolyseedException implements Exception {
  const PolyseedException([this.message]);

  final String? message;

  @override
  String toString() {
    String report = 'PolyseedException';
    if (message is String) return '$report: $message';
    return report;
  }
}

class WordNumberException extends PolyseedException {
  WordNumberException() : super("Wrong number of words in the phrase");
}

class UnknownLangException extends PolyseedException {
  UnknownLangException() : super("Unknown language or unsupported words");
}

class ChecksumMismatchException extends PolyseedException {
  ChecksumMismatchException() : super("Checksum mismatch");
}

class UnsupportedSeedFeatureException extends PolyseedException {
  UnsupportedSeedFeatureException() : super("Unsupported seed features");
}

class InvalidSeedFormatException extends PolyseedException {
  InvalidSeedFormatException() : super("Invalid seed format");
}
