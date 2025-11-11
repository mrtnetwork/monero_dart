import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class TxOutTargetType {
  final String name;
  final int variantId;
  const TxOutTargetType._({required this.name, required this.variantId});
  static const TxOutTargetType txoutToScript =
      TxOutTargetType._(name: "TxoutToScript", variantId: 0x0);
  static const TxOutTargetType txoutToScriptHash =
      TxOutTargetType._(name: "TxoutToScriptHash", variantId: 0x1);
  static const TxOutTargetType txoutToKey =
      TxOutTargetType._(name: "TxoutToKey", variantId: 0x2);
  static const TxOutTargetType txoutToTaggedKey =
      TxOutTargetType._(name: "TxoutToTaggedKey", variantId: 0x3);
  static const List<TxOutTargetType> values = [
    txoutToScript,
    txoutToScriptHash,
    txoutToKey,
    txoutToTaggedKey
  ];
  static TxOutTargetType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException(
            "Invalid Txout target type.",
            details: {"type": name}));
  }
}

abstract class TxoutTarget extends MoneroVariantSerialization {
  final TxOutTargetType type;
  const TxoutTarget(this.type);
  factory TxoutTarget.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = TxOutTargetType.fromName(decode.variantName);
    switch (type) {
      case TxOutTargetType.txoutToKey:
        return TxoutToKey.fromStruct(decode.value);
      case TxOutTargetType.txoutToScript:
        return TxoutToScript.fromStruct(decode.value);
      case TxOutTargetType.txoutToScriptHash:
        return TxoutToScriptHash.fromStruct(decode.value);
      case TxOutTargetType.txoutToTaggedKey:
        return TxoutToTaggedKey.fromStruct(decode.value);
      default:
        throw DartMoneroPluginException("Invalid txout target.",
            details: {"type": type, "data": decode.value});
    }
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: TxoutToScript.layout,
        property: TxOutTargetType.txoutToScript.name,
        index: TxOutTargetType.txoutToScript.variantId,
      ),
      LazyVariantModel(
        layout: TxoutToScriptHash.layout,
        property: TxOutTargetType.txoutToScriptHash.name,
        index: TxOutTargetType.txoutToScriptHash.variantId,
      ),
      LazyVariantModel(
        layout: TxoutToKey.layout,
        property: TxOutTargetType.txoutToKey.name,
        index: TxOutTargetType.txoutToKey.variantId,
      ),
      LazyVariantModel(
        layout: TxoutToTaggedKey.layout,
        property: TxOutTargetType.txoutToTaggedKey.name,
        index: TxOutTargetType.txoutToTaggedKey.variantId,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String get variantName => type.name;

  T cast<T extends TxoutTarget>() {
    if (this is! T) {
      throw DartMoneroPluginException("TxoutTarget casting failed.",
          details: {"expected": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }

  MoneroPublicKey? getPublicKey() {
    switch (type) {
      case TxOutTargetType.txoutToKey:
        return MoneroPublicKey.fromBytes(cast<TxoutToKey>().key);
      case TxOutTargetType.txoutToTaggedKey:
        return MoneroPublicKey.fromBytes(cast<TxoutToTaggedKey>().key);
      default:
        return null;
    }
  }

  List<int>? getPublicKeyBytes() {
    switch (type) {
      case TxOutTargetType.txoutToKey:
        return cast<TxoutToKey>().key;
      case TxOutTargetType.txoutToTaggedKey:
        return cast<TxoutToTaggedKey>().key;
      default:
        return null;
    }
  }

  int? getViewTag() {
    switch (type) {
      case TxOutTargetType.txoutToTaggedKey:
        return cast<TxoutToTaggedKey>().viewTag;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson();
}

class TxoutToScript extends TxoutTarget {
  final List<List<int>> keys;
  final List<int> script;
  TxoutToScript({required List<List<int>> keys, required List<int> script})
      : keys = keys.map((e) => e.asImmutableBytes).toList().immutable,
        script = script.asImmutableBytes,
        super(TxOutTargetType.txoutToScript);
  factory TxoutToScript.fromStruct(Map<String, dynamic> json) {
    return TxoutToScript(
        keys: json.asListBytes("keys")!, script: json.asBytes("script"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "keys"),
      MoneroLayoutConst.variantBytes(property: "script"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"keys": keys, "script": script};
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "keys": keys.map((e) => BytesUtils.toHexString(e)).toList(),
      "script": BytesUtils.toHexString(script)
    };
  }
}

class TxoutToScriptHash extends TxoutTarget {
  final List<int> hash;
  TxoutToScriptHash(List<int> hash)
      : hash = hash.asImmutableBytes,
        super(TxOutTargetType.txoutToScriptHash);
  factory TxoutToScriptHash.fromStruct(Map<String, dynamic> json) {
    return TxoutToScriptHash(json.asBytes("hash"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "hash"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"hash": hash};
  }

  @override
  Map<String, dynamic> toJson() {
    return {"hash": BytesUtils.toHexString(hash)};
  }
}

class TxoutToKey extends TxoutTarget {
  final List<int> key;
  TxoutToKey(List<int> key)
      : key = key.exc(Ed25519KeysConst.pubKeyByteLen),
        super(TxOutTargetType.txoutToKey);
  factory TxoutToKey.fromStruct(Map<String, dynamic> json) {
    return TxoutToKey(json.asBytes("key"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "key"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"key": key};
  }

  @override
  Map<String, dynamic> toJson() {
    return {"key": BytesUtils.toHexString(key)};
  }
}

class TxoutToTaggedKey extends TxoutTarget {
  final List<int> key;
  final int viewTag;
  TxoutToTaggedKey({required List<int> key, required int viewTag})
      : viewTag = viewTag.asUint8,
        key = key.exc(Ed25519KeysConst.privKeyByteLen),
        super(TxOutTargetType.txoutToTaggedKey);
  factory TxoutToTaggedKey.fromStruct(Map<String, dynamic> json) {
    return TxoutToTaggedKey(
        key: json.asBytes("key"), viewTag: json.as("view_tag"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "key"),
      LayoutConst.u8(property: "view_tag"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"key": key, "view_tag": viewTag};
  }

  @override
  Map<String, dynamic> toJson() {
    return {"key": BytesUtils.toHexString(key), "view_tag": viewTag};
  }
}

class MoneroTxout extends MoneroSerialization {
  final BigInt amount;
  final TxoutTarget target;
  MoneroTxout({required BigInt amount, required this.target})
      : amount = amount.asUint64;
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      TxoutTarget.layout(property: "target")
    ], property: property);
  }

  MoneroTxout copyWith({BigInt? amount, TxoutTarget? target}) {
    return MoneroTxout(
        amount: amount ?? this.amount, target: target ?? this.target);
  }

  factory MoneroTxout.fromStruct(Map<String, dynamic> json) {
    return MoneroTxout(
      amount: json.as("amount"),
      target: TxoutTarget.fromStruct(json.asMap("target")),
    );
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"amount": amount, "target": target.toVariantLayoutStruct()};
  }

  Map<String, dynamic> toJson() {
    return {"amount": amount.toString(), "target": target.toJson()};
  }
}
