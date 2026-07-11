import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/identifiers/identifiers.dart';

class MoneroSerializationException extends BaseDartMoneroPluginException {
  const MoneroSerializationException(super.message, {super.details});
  factory MoneroSerializationException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.serializationError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroSerializationException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  MoneroSerializationIdentifiers get serializationIdentifier =>
      MoneroSerializationIdentifiers.serializationError;
}
