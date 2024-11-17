import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:monero_dart/src/crypto/multisig/const/const.dart';
import 'package:monero_dart/src/crypto/multisig/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/utils/multi_sig_kex_utils.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MultisigKexMessage {
  final MultisigKexMessageSerializable message;
  final int round;
  final List<MoneroPublicKey> pubKeys;
  final MoneroPrivateKey? messagePrivateKey;
  final MoneroPublicKey signingPubKey;
  factory MultisigKexMessage(MultisigKexMessageSerializable msg) {
    MultisigKexMessage kexMessage;
    final signingPublicKey = msg.signingPubKey;
    final round = msg.round;
    List<MoneroPublicKey> pubKeys = [];
    MoneroPrivateKey? msgPrivateKey;
    switch (msg.type) {
      case MoneroMultisigType.round1:
        final message = msg.cast<MultisigKexMessageSerializableRound1>();
        msgPrivateKey = message.msgPrivateKey;
        break;
      case MoneroMultisigType.general:
        final message = msg.cast<MultisigKexMessageSerializableRoundN>();
        pubKeys = message.msgPubKeys;
        break;
      default:
        throw MoneroMultisigAccountException("Invalid monero multisig type.",
            details: {"type": msg.type});
    }

    kexMessage = MultisigKexMessage._(
        message: msg,
        round: round,
        pubKeys: pubKeys.map((e) => MoneroCrypto.asValidPublicKey(e)).toList(),
        messagePrivateKey: msgPrivateKey,
        signingPubKey: MoneroCrypto.asValidPublicKey(signingPublicKey));
    final hash = MoneroMultisigKexUtils.generateMessageHash(
        msgPrivateKey: msgPrivateKey,
        signingPubKey: signingPublicKey,
        msgPubKeys: pubKeys,
        round: round);
    final verify = MoneroCrypto.checkSignature(
        hash: hash, publicKey: signingPublicKey.key, signature: msg.signature);
    if (!verify) {
      throw const MoneroMultisigAccountException(
          "Multisig kex message verification failed.");
    }
    return kexMessage;
  }
  MultisigKexMessage._(
      {required this.message,
      required this.round,
      required List<MoneroPublicKey> pubKeys,
      required this.messagePrivateKey,
      required this.signingPubKey})
      : pubKeys = pubKeys.immutable;
  factory MultisigKexMessage.generate(
      {required int round,
      required MoneroPrivateKey signingPrivateKey,
      required List<MoneroPublicKey> msgPubKeys,
      MoneroPrivateKey? msgPrivateKey}) {
    if (round <= 0) {
      throw const MoneroMultisigAccountException("Kex round must be > 0.");
    }
    if (round == 1) {
      if (msgPrivateKey == null) {
        throw const MoneroMultisigAccountException(
            "message private key must not be null in first round.");
      }
    } else {
      msgPubKeys =
          msgPubKeys.map((e) => MoneroCrypto.asValidPublicKey(e)).toList();
    }
    final signingPubKey = signingPrivateKey.publicKey;
    final msgHash = MoneroMultisigKexUtils.generateMessageHash(
        msgPrivateKey: msgPrivateKey,
        signingPubKey: signingPubKey,
        msgPubKeys: msgPubKeys,
        round: round);
    final signature = MoneroCrypto.generateSignature(
        hash: msgHash,
        publicKey: signingPubKey.key,
        secretKey: signingPrivateKey.key);
    MultisigKexMessageSerializable message;
    if (round == 1) {
      message = MultisigKexMessageSerializableRound1(
          msgPrivateKey: msgPrivateKey!,
          signingPubKey: signingPubKey,
          signature: signature);
    } else {
      message = MultisigKexMessageSerializableRoundN(
          msgPubKeys: msgPubKeys,
          round: round,
          signingPubKey: signingPubKey,
          signature: signature);
    }
    return MultisigKexMessage._(
        message: message,
        round: round,
        pubKeys: msgPubKeys,
        messagePrivateKey: msgPrivateKey,
        signingPubKey: signingPubKey);
  }
}

class MoneroMultisigType {
  final String name;
  const MoneroMultisigType._(this.name);
  static const MoneroMultisigType round1 = MoneroMultisigType._("round1");
  static const MoneroMultisigType general = MoneroMultisigType._("general");
  static MoneroMultisigType fromBase58(String message) {
    if (message.startsWith(MoneroMultisigConst.multisigKexMsgV2Magic1)) {
      return MoneroMultisigType.round1;
    }
    if (message.startsWith(MoneroMultisigConst.multisigKexMsgV2MagicN)) {
      return MoneroMultisigType.general;
    }
    throw MoneroMultisigAccountException("Unsuported multisig type.",
        details: {"message": message});
  }

  @override
  String toString() {
    return "MoneroMultisigType.$name";
  }

  String getTypePrefix() {
    switch (this) {
      case MoneroMultisigType.round1:
        return MoneroMultisigConst.multisigKexMsgV2Magic1;
      case MoneroMultisigType.general:
        return MoneroMultisigConst.multisigKexMsgV2MagicN;
      default:
        throw const MoneroMultisigAccountException(
            "Invalid monero multisig type.");
    }
  }
}

abstract class MultisigKexMessageSerializable extends MoneroSerialization {
  MoneroMultisigType get type;
  abstract final MoneroPublicKey signingPubKey;
  abstract final MECSignature signature;
  abstract final int round;
  const MultisigKexMessageSerializable();

  MultisigKexMessage toMessage() {
    return MultisigKexMessage(this);
  }

  String toBase58() {
    final prefix = type.getTypePrefix();
    final b58 = Base58XmrEncoder.encode(serialize());
    return "$prefix$b58";
  }

  factory MultisigKexMessageSerializable.fromBase58(String data) {
    final type = MoneroMultisigType.fromBase58(data);
    data = data.substring(MoneroMultisigConst.prefixLength);
    final List<int> bytes = Base58XmrDecoder.decode(data);
    switch (type) {
      case MoneroMultisigType.round1:
        return MultisigKexMessageSerializableRound1.deserialize(bytes);
      case MoneroMultisigType.general:
        return MultisigKexMessageSerializableRoundN.deserialize(bytes);
      default:
        throw MoneroMultisigAccountException("Invalid monero multisig type.",
            details: {"type": type.name});
    }
  }

  T cast<T extends MultisigKexMessageSerializable>() {
    if (this is! T) {
      throw MoneroMultisigAccountException(
          "MultisigKexMessageSerializable casting failed.",
          details: {"excepted": "$T", "type": type.name});
    }
    return this as T;
  }
}

class MultisigKexMessageSerializableRound1
    extends MultisigKexMessageSerializable {
  final MoneroPrivateKey msgPrivateKey;
  @override
  final MoneroPublicKey signingPubKey;
  @override
  final MECSignature signature;
  @override
  MoneroMultisigType get type => MoneroMultisigType.round1;
  @override
  int get round => 1;
  const MultisigKexMessageSerializableRound1(
      {required this.msgPrivateKey,
      required this.signingPubKey,
      required this.signature});
  factory MultisigKexMessageSerializableRound1.deserialize(List<int> bytes,
      {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MultisigKexMessageSerializableRound1.fromStruct(decode);
  }
  factory MultisigKexMessageSerializableRound1.fromStruct(
      Map<String, dynamic> json) {
    return MultisigKexMessageSerializableRound1(
        msgPrivateKey: MoneroPrivateKey.fromBytes(json.asBytes("private_key")),
        signingPubKey:
            MoneroPublicKey.fromBytes(json.asBytes("signing_pubkey")),
        signature: MECSignature.fromStruct(json.asMap("signature")));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "private_key"),
      LayoutConst.fixedBlob32(property: "signing_pubkey"),
      MECSignature.layout(property: "signature"),
    ]);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "private_key": msgPrivateKey.key,
      "signing_pubkey": signingPubKey.key,
      "signature": signature.toLayoutStruct()
    };
  }
}

class MultisigKexMessageSerializableRoundN
    extends MultisigKexMessageSerializable {
  @override
  final int round;
  final List<MoneroPublicKey> msgPubKeys;
  @override
  final MoneroPublicKey signingPubKey;
  @override
  final MECSignature signature;
  @override
  MoneroMultisigType get type => MoneroMultisigType.general;
  MultisigKexMessageSerializableRoundN(
      {required List<MoneroPublicKey> msgPubKeys,
      required int round,
      required this.signingPubKey,
      required this.signature})
      : msgPubKeys = msgPubKeys.immutable,
        round = round.asUint32;

  factory MultisigKexMessageSerializableRoundN.deserialize(List<int> bytes,
      {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MultisigKexMessageSerializableRoundN.fromStruct(decode);
  }
  factory MultisigKexMessageSerializableRoundN.fromStruct(
      Map<String, dynamic> json) {
    return MultisigKexMessageSerializableRoundN(
        round: json.as("round"),
        msgPubKeys: json
            .asListBytes("msg_pubkeys")!
            .map((e) => MoneroPublicKey.fromBytes(e))
            .toList(),
        signingPubKey:
            MoneroPublicKey.fromBytes(json.asBytes("signing_pubkey")),
        signature: MECSignature.fromStruct(json.asMap("signature")));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintInt(property: "round"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "msg_pubkeys"),
      LayoutConst.fixedBlob32(property: "signing_pubkey"),
      MECSignature.layout(property: "signature"),
    ]);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "round": round,
      "msg_pubkeys": msgPubKeys.map((e) => e.key).toList(),
      "signing_pubkey": signingPubKey.key,
      "signature": signature.toLayoutStruct()
    };
  }
}
