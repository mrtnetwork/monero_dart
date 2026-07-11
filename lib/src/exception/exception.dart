import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:monero_dart/src/block_processor/exception/exception.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/exception/exception.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

abstract class BaseDartMoneroPluginException extends IException {
  const BaseDartMoneroPluginException(super.message, {super.details});
  factory BaseDartMoneroPluginException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final decode = CborTagSerializable.decodeTaggedValueWithInfo(
      expectedTags: MoneroSerializationIdentifiers.values,
      cborBytes: bytes,
      cborObject: obj,
    );
    final identifier = decode.identifier;
    return switch (identifier) {
      MoneroSerializationIdentifiers.moneroPluginError =>
        DartMoneroPluginException.deserialize(obj: decode.tag),
      MoneroSerializationIdentifiers.cryptoError =>
        MoneroCryptoException.deserialize(obj: decode.tag),
      MoneroSerializationIdentifiers.multisigAccountError =>
        MoneroMultisigAccountException.deserialize(obj: decode.tag),
      MoneroSerializationIdentifiers.serializationError =>
        MoneroSerializationException.deserialize(obj: decode.tag),
      MoneroSerializationIdentifiers.blockScannerError =>
        MoneroBlockScannerException.deserialize(obj: decode.tag),
      _ =>
        throw CborSerializableException.incorrectTagValue(tag: decode.tag.tags),
    };
  }
  @override
  MoneroSerializationIdentifiers get serializationIdentifier;

  @override
  BlockchainNetwork get relatedNetwork => BlockchainNetwork.monero;
}

class DartMoneroPluginException extends BaseDartMoneroPluginException {
  const DartMoneroPluginException(super.message, {super.details});
  factory DartMoneroPluginException.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.moneroPluginError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return DartMoneroPluginException(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  MoneroSerializationIdentifiers get serializationIdentifier =>
      MoneroSerializationIdentifiers.moneroPluginError;
}
