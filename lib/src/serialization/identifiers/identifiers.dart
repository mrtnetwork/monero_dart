import 'package:blockchain_utils/blockchain_utils.dart';

enum MoneroSerializationIdentifiers implements SerializationIdentifier {
  moneroPluginError(16001),
  cryptoError(16002),
  multisigAccountError(16003),
  serializationError(16004),
  blockScannerError(16005),
  keyImage(16006),
  subIndex(16007);

  @override
  final int id;
  const MoneroSerializationIdentifiers(this.id);

  static MoneroSerializationIdentifiers fromIdentifier(int? value) {
    return values.firstWhere(
      (e) => e.id == value,
      orElse:
          () =>
              throw BuError(
                DefaultErrorType.notFound,
                "No matching MoneroSerializationIdentifiers found for the given value. null",
              ),
    );
  }

  @override
  bool isValid(int? tag) {
    return tag == id;
  }
}
