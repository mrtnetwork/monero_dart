import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:monero_dart/monero_dart.dart';

class MoneroBlockScannerException extends BaseDartMoneroPluginException {
  const MoneroBlockScannerException(super.message, {super.details});
  factory MoneroBlockScannerException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.blockScannerError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroBlockScannerException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  MoneroSerializationIdentifiers get serializationIdentifier =>
      MoneroSerializationIdentifiers.blockScannerError;
  static MoneroBlockScannerException failed(
    String operation, {
    Map<String, String?>? details,
    String? reason,
  }) {
    return MoneroBlockScannerException(
      "Block scan failed during $operation",
      details: {"reason": reason, ...details ?? {}}.notNullValue,
    );
  }
}
