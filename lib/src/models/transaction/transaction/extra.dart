import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class _TxExtraConst {
  static const int nonceMaxCount = 255;
  static const int txExtraNoncePaymentId = 0x00;
  static const int txExtraNonceEncryptedPaymentId = 0x01;
  static const int paymentIdWithPrefixLength = 9;
}

class TxExtraTypes {
  final String name;
  final int value;
  const TxExtraTypes._({required this.name, required this.value});
  static const TxExtraTypes padding =
      TxExtraTypes._(name: "padding", value: 0x00);
  static const TxExtraTypes publicKey =
      TxExtraTypes._(name: "publickey", value: 0x01);
  static const TxExtraTypes nonce = TxExtraTypes._(name: "nonce", value: 0x02);
  static const TxExtraTypes mergeMiningTag =
      TxExtraTypes._(name: "mergeMiningTag", value: 0x03);
  static const TxExtraTypes additionalPubKeys =
      TxExtraTypes._(name: "additionalPublicKeys", value: 0x04);
  static const TxExtraTypes mysteriousMinergate =
      TxExtraTypes._(name: "mysteriousMinergate", value: 0xDE);
  static const List<TxExtraTypes> values = [
    publicKey,
    additionalPubKeys,
    nonce,
    padding,
    mergeMiningTag,
    mysteriousMinergate
  ];
  static TxExtraTypes fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException("Invalid tx extra type.",
            details: {"type": name}));
  }
}

abstract class TxExtra extends MoneroVariantSerialization {
  final TxExtraTypes type;
  const TxExtra(this.type);
  factory TxExtra.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = TxExtraTypes.fromName(decode.variantName);
    switch (type) {
      case TxExtraTypes.publicKey:
        return TxExtraPublicKey.fromStruct(decode.value);
      case TxExtraTypes.nonce:
        return TxExtraNonce.fromStruct(decode.value);
      case TxExtraTypes.additionalPubKeys:
        return TxExtraAdditionalPubKeys.fromStruct(decode.value);
      default:
        throw UnimplementedError("does not implemented");
    }
  }
  factory TxExtra.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return TxExtra.fromStruct(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
          layout: TxExtraPublicKey.layout,
          property: TxExtraTypes.publicKey.name,
          index: TxExtraTypes.publicKey.value),
      LazyVariantModel(
          layout: TxExtraNonce.layout,
          property: TxExtraTypes.nonce.name,
          index: TxExtraTypes.nonce.value),
      LazyVariantModel(
          layout: TxExtraAdditionalPubKeys.layout,
          property: TxExtraTypes.additionalPubKeys.name,
          index: TxExtraTypes.additionalPubKeys.value),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    throw UnimplementedError();
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    throw UnimplementedError();
  }

  @override
  String get variantName => type.name;
  T cast<T extends TxExtra>() {
    if (this is! T) {
      throw DartMoneroPluginException("Casting tx extra failed.",
          details: {"expected": "$T", "type": type.name});
    }
    return this as T;
  }
}

class TxExtraPadding extends TxExtra {
  final int size;
  TxExtraPadding({required this.size}) : super(TxExtraTypes.padding);
}

class TxExtraPublicKey extends TxExtra {
  final List<int> publicKey;
  TxExtraPublicKey(List<int> publicKey)
      : publicKey =
            publicKey.exc(Ed25519KeysConst.pubKeyByteLen).asImmutableBytes,
        super(TxExtraTypes.publicKey);
  factory TxExtraPublicKey.fromStruct(Map<String, dynamic> json) {
    return TxExtraPublicKey(json.asBytes("publicKey"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([LayoutConst.fixedBlob32(property: "publicKey")],
        property: property);
  }

  MoneroPublicKey asPublicKey() {
    return MoneroPublicKey.fromBytes(publicKey);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"publicKey": publicKey};
  }
}

class TxExtraNonce extends TxExtra {
  final List<int> nonce;
  TxExtraNonce(List<int> nonce)
      : nonce = nonce
            .max(_TxExtraConst.nonceMaxCount, name: 'nonce')
            .asImmutableBytes,
        super(TxExtraTypes.nonce);
  factory TxExtraNonce.fromStruct(Map<String, dynamic> json) {
    return TxExtraNonce(json.asBytes("nonce"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.vecU8(property: "nonce", lengthSizeLayout: LayoutConst.u8()),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  factory TxExtraNonce.encryptedPaymentId(List<int> encryptedPaymentId) {
    final pId =
        encryptedPaymentId.asBytes.exc(8, name: "exncrypted payment id");
    return TxExtraNonce([_TxExtraConst.txExtraNonceEncryptedPaymentId, ...pId]);
  }
  factory TxExtraNonce.paymentId(List<int> paymentId) {
    final pId = paymentId.asBytes.exc(8, name: "payment id");
    return TxExtraNonce([_TxExtraConst.txExtraNoncePaymentId, ...pId]);
  }
  List<int>? get hasEncryptedPaymentId {
    if (nonce.length != _TxExtraConst.paymentIdWithPrefixLength) return null;
    if (nonce[0] != _TxExtraConst.txExtraNonceEncryptedPaymentId) return null;
    return nonce.sublist(1);
  }

  List<int>? get hasPaymentId {
    if (nonce.length != _TxExtraConst.paymentIdWithPrefixLength) return null;
    if (nonce[0] != _TxExtraConst.txExtraNoncePaymentId) return null;
    return nonce.sublist(1);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"nonce": nonce};
  }
}

class TxExtraMergeMiningTag extends TxExtra {
  final BigInt depth;
  final List<int> merkleRoot;
  TxExtraMergeMiningTag({required BigInt depth, required List<int> merkleRoot})
      : depth = depth.asUint64,
        merkleRoot = merkleRoot.asImmutableBytes.exc(32, name: "merkle root"),
        super(TxExtraTypes.mergeMiningTag);
}

class TxExtraAdditionalPubKeys extends TxExtra {
  final List<List<int>> pubKeys;
  TxExtraAdditionalPubKeys(List<List<int>> data)
      : pubKeys = data
            .map((e) => e.exc(Ed25519KeysConst.pubKeyByteLen).asImmutableBytes)
            .toImutableList,
        super(TxExtraTypes.additionalPubKeys);
  factory TxExtraAdditionalPubKeys.fromStruct(Map<String, dynamic> json) {
    return TxExtraAdditionalPubKeys(json.asListBytes("pubKeys")!);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "pubKeys")
    ]);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"pubKeys": pubKeys};
  }

  List<MoneroPublicKey> asPublicKeys() {
    return pubKeys.map((e) => MoneroPublicKey.fromBytes(e)).toList();
  }
}

/// mysterious_minergate
class TxExtraMysteriousMinergate extends TxExtra {
  final String data;
  TxExtraMysteriousMinergate(this.data) : super(TxExtraTypes.nonce);
}
