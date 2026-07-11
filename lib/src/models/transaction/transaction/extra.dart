import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/layouts/tx_extra_pading.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class TxExtraConst {
  static const int nonceMaxCount = 255;
  static const int txPaddingMaxCount = 255;
  static const int txExtraNoncePaymentId = 0x00;
  static const int txExtraNonceEncryptedPaymentId = 0x01;
  static const int paymentIdWithPrefixLength = 9;
}

enum TxExtraTypes {
  padding(name: "padding", value: 0x00),

  publicKey(name: "publickey", value: 0x01),
  nonce(name: "nonce", value: 0x02),
  mergeMiningTag(name: "mergeMiningTag", value: 0x03),
  additionalPubKeys(name: "additionalPublicKeys", value: 0x04),
  mysteriousMinergate(name: "mysteriousMinergate", value: 0xDE);

  final String name;
  final int value;
  const TxExtraTypes({required this.name, required this.value});
  static TxExtraTypes fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () => throw ItemNotFoundException(name: "TxExtraTypes", value: name),
    );
  }
}

abstract class TxExtra extends MoneroVariantSerialization {
  final TxExtraTypes type;
  const TxExtra(this.type);
  factory TxExtra.deserializeJson(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = TxExtraTypes.fromName(decode.variantName);
    switch (type) {
      case TxExtraTypes.publicKey:
        return TxExtraPublicKey.deserializeJson(decode.value);
      case TxExtraTypes.nonce:
        return TxExtraNonce.deserializeJson(decode.value);
      case TxExtraTypes.additionalPubKeys:
        return TxExtraAdditionalPubKeys.deserializeJson(decode.value);
      case TxExtraTypes.padding:
        return TxExtraPadding.deserializeJson(decode.value);

      case TxExtraTypes.mergeMiningTag:
        return TxExtraMergeMiningTag.deserializeJson(decode.value);
      case TxExtraTypes.mysteriousMinergate:
        return TxExtraMysteriousMinergate.deserializeJson(decode.value);
    }
  }
  factory TxExtra.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return TxExtra.deserializeJson(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: TxExtraPublicKey.layout,
        property: TxExtraTypes.publicKey.name,
        index: TxExtraTypes.publicKey.value,
      ),
      LazyVariantModel(
        layout: TxExtraNonce.layout,
        property: TxExtraTypes.nonce.name,
        index: TxExtraTypes.nonce.value,
      ),
      LazyVariantModel(
        layout: TxExtraAdditionalPubKeys.layout,
        property: TxExtraTypes.additionalPubKeys.name,
        index: TxExtraTypes.additionalPubKeys.value,
      ),
      LazyVariantModel(
        layout: TxExtraPadding.layout,
        property: TxExtraTypes.padding.name,
        index: TxExtraTypes.padding.value,
      ),
      LazyVariantModel(
        layout: TxExtraMergeMiningTag.layout,
        property: TxExtraTypes.mergeMiningTag.name,
        index: TxExtraTypes.mergeMiningTag.value,
      ),
      LazyVariantModel(
        layout: TxExtraMysteriousMinergate.layout,
        property: TxExtraTypes.mysteriousMinergate.name,
        index: TxExtraTypes.mysteriousMinergate.value,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    throw DartMoneroPluginException("Unsupported feature.");
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    throw DartMoneroPluginException("Unsupported feature.");
  }

  @override
  String get variantName => type.name;
  T cast<T extends TxExtra>() {
    if (this is! T) {
      throw DartMoneroPluginException(
        "Casting tx extra failed.",
        details: {"expected": "$T", "type": type.name},
      );
    }
    return this as T;
  }
}

class TxExtraPadding extends TxExtra {
  final List<int> data;
  TxExtraPadding(List<int> data)
    : data = data.asImmutableBytes.max(
        length: TxExtraConst.txPaddingMaxCount,
        operation: "Invalid txExtra padding bytes length.",
      ),
      super(TxExtraTypes.padding);
  factory TxExtraPadding.deserializeJson(Map<String, dynamic> json) {
    return TxExtraPadding(json.valueAsBytes("data"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      TxExtraPaddingLayout(property: "data"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"data": data};
  }
}

class TxExtraPublicKey extends TxExtra {
  final List<int> publicKey;
  TxExtraPublicKey(List<int> publicKey)
    : publicKey =
          publicKey
              .exc(
                length: 32,
                operation: "TxExtraPublicKey",
                reason: "Invalid publicKey bytes length.",
              )
              .asImmutableBytes,
      super(TxExtraTypes.publicKey);
  factory TxExtraPublicKey.deserializeJson(Map<String, dynamic> json) {
    return TxExtraPublicKey(json.valueAsBytes("publicKey"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "publicKey"),
    ], property: property);
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
    : nonce =
          nonce
              .max(
                length: TxExtraConst.nonceMaxCount,
                operation: "TxExtraNonce",
                reason: "Invalid nonce bytes length.",
              )
              .asImmutableBytes,
      super(TxExtraTypes.nonce);
  factory TxExtraNonce.deserializeJson(Map<String, dynamic> json) {
    return TxExtraNonce(json.valueAsBytes("nonce"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantBytes(property: "nonce"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  factory TxExtraNonce.encryptedPaymentId(List<int> encryptedPaymentId) {
    final pId = encryptedPaymentId.asBytes.exc(
      length: 8,
      operation: "TxExtraNonce",
      reason: "Invalid encryptedPaymentId bytes length.",
    );
    return TxExtraNonce([TxExtraConst.txExtraNonceEncryptedPaymentId, ...pId]);
  }
  factory TxExtraNonce.memo(List<int> data, {int? tag = 0x7F}) {
    return TxExtraNonce([if (tag != null) tag, ...data]);
  }
  factory TxExtraNonce.paymentId(List<int> paymentId) {
    final pId = paymentId.asBytes.exc(
      length: 8,
      operation: "TxExtraNonce",
      reason: "Invalid paymentId bytes length.",
    );
    return TxExtraNonce([TxExtraConst.txExtraNoncePaymentId, ...pId]);
  }
  List<int>? tryExtractEncryptedPaymetId() {
    if (nonce.length != TxExtraConst.paymentIdWithPrefixLength) return null;
    if (nonce[0] != TxExtraConst.txExtraNonceEncryptedPaymentId) return null;
    return nonce.sublist(1);
  }

  List<int>? tryExtractPaymentId() {
    if (nonce.length != TxExtraConst.paymentIdWithPrefixLength) return null;
    if (nonce[0] != TxExtraConst.txExtraNoncePaymentId) return null;
    return nonce.sublist(1);
  }

  bool isUnknownTxExtra() {
    if (nonce.length != TxExtraConst.paymentIdWithPrefixLength) {
      return true;
    }
    final tag = nonce[0];
    return tag != TxExtraConst.txExtraNoncePaymentId &&
        tag != TxExtraConst.txExtraNonceEncryptedPaymentId;
  }

  String? tryExtractString() {
    if (nonce.isEmpty) return null;
    final decode = StringUtils.tryDecode(nonce);
    if (decode == null && nonce.length > 1) {
      return StringUtils.tryDecode(nonce.sublist(1));
    }
    return decode;
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
    : depth = depth.asU64,
      merkleRoot = merkleRoot.asImmutableBytes.exc(
        length: 32,
        operation: "TxExtraMergeMiningTag",
        reason: "Invalid merkleRoot bytes length.",
      ),
      super(TxExtraTypes.mergeMiningTag);
  factory TxExtraMergeMiningTag.deserializeJson(Map<String, dynamic> json) {
    return TxExtraMergeMiningTag(
      depth: json.valueAsBigInt("depth"),
      merkleRoot: json.valueAsBytes("merkle_root"),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "depth"),
      LayoutConst.fixedBlob32(property: "merkle_root"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"depth": depth, "merkle_root": merkleRoot};
  }
}

class TxExtraAdditionalPubKeys extends TxExtra {
  final List<List<int>> pubKeys;
  TxExtraAdditionalPubKeys(List<List<int>> data)
    : pubKeys =
          data
              .map(
                (e) =>
                    e
                        .exc(
                          length: 32,
                          operation: "TxExtraAdditionalPubKeys",
                          reason: "Invalid pubKeys bytes length.",
                        )
                        .asImmutableBytes,
              )
              .toImutableList,
      super(TxExtraTypes.additionalPubKeys);
  factory TxExtraAdditionalPubKeys.deserializeJson(Map<String, dynamic> json) {
    return TxExtraAdditionalPubKeys(
      json.valueEnsureAsList<List<int>>("pubKeys"),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(
        LayoutConst.fixedBlob32(),
        property: "pubKeys",
      ),
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
  final List<int> data;
  TxExtraMysteriousMinergate(List<int> data)
    : data = data.asImmutableBytes,
      super(TxExtraTypes.mysteriousMinergate);

  factory TxExtraMysteriousMinergate.deserializeJson(
    Map<String, dynamic> json,
  ) {
    return TxExtraMysteriousMinergate(json.valueAsBytes("data"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantBytes(property: "data"),
    ]);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"data": data};
  }
}
