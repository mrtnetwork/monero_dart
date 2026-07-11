import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/identifiers/identifiers.dart';

/// exception for multisig account generating operations.
class MoneroMultisigAccountException extends BaseDartMoneroPluginException {
  const MoneroMultisigAccountException(super.message, {super.details});
  factory MoneroMultisigAccountException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.multisigAccountError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroMultisigAccountException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  MoneroSerializationIdentifiers get serializationIdentifier =>
      MoneroSerializationIdentifiers.multisigAccountError;
}
