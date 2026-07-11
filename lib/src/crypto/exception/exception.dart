import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

/// exception related to monero crypto operations.
class MoneroCryptoException extends BaseDartMoneroPluginException {
  const MoneroCryptoException(super.message, {super.details});
  factory MoneroCryptoException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.cryptoError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroCryptoException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  MoneroSerializationIdentifiers get serializationIdentifier =>
      MoneroSerializationIdentifiers.cryptoError;
}
