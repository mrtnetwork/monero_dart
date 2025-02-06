import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/models/transaction/transaction/output.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroTxinType {
  final String name;
  final int variantId;
  const MoneroTxinType._({required this.name, required this.variantId});
  static const MoneroTxinType txinGen =
      MoneroTxinType._(name: "TxinGen", variantId: 0xff);
  static const MoneroTxinType txinToScript =
      MoneroTxinType._(name: "TxinToScript", variantId: 0x0);
  static const MoneroTxinType txinToScriptHash =
      MoneroTxinType._(name: "TxinToScriptHash", variantId: 0x1);
  static const MoneroTxinType txinToKey =
      MoneroTxinType._(name: "TxinToKey", variantId: 0x2);
  static const List<MoneroTxinType> values = [
    txinGen,
    txinToScript,
    txinToScriptHash,
    txinToKey
  ];
  static MoneroTxinType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException("Invalid Txin type.",
            details: {"type": name}));
  }
}

/// txin_v
abstract class MoneroTxin extends MoneroVariantSerialization {
  final MoneroTxinType type;
  const MoneroTxin(this.type);
  factory MoneroTxin.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroTxinType.fromName(decode.variantName);
    switch (type) {
      case MoneroTxinType.txinGen:
        return TxinGen.fromStruct(decode.value);
      case MoneroTxinType.txinToScript:
        return TxinToScript.fromStruct(decode.value);
      case MoneroTxinType.txinToScriptHash:
        return TxinToScriptHash.fromStruct(decode.value);
      case MoneroTxinType.txinToKey:
        return TxinToKey.fromStruct(decode.value);
      default:
        throw DartMoneroPluginException("Invalid Txin.",
            details: {"type": type, "data": decode.value});
    }
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
          layout: TxinGen.layout,
          property: MoneroTxinType.txinGen.name,
          index: MoneroTxinType.txinGen.variantId),
      LazyVariantModel(
          layout: TxinToScript.layout,
          property: MoneroTxinType.txinToScript.name,
          index: MoneroTxinType.txinToScript.variantId),
      LazyVariantModel(
          layout: TxinToScriptHash.layout,
          property: MoneroTxinType.txinToScriptHash.name,
          index: MoneroTxinType.txinToScriptHash.variantId),
      LazyVariantModel(
          layout: TxinToKey.layout,
          property: MoneroTxinType.txinToKey.name,
          index: MoneroTxinType.txinToKey.variantId),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String get variantName => type.name;
  T cast<T extends MoneroTxin>() {
    if (this is! T) {
      throw DartMoneroPluginException("MoneroTxin casting failed.",
          details: {"expected": "$T", "type": type.name});
    }
    return this as T;
  }

  Map<String, dynamic> toJson();

  String? getKeyImage() {
    if (type != MoneroTxinType.txinToKey) return null;
    return BytesUtils.toHexString(cast<TxinToKey>().keyImage);
  }
}

class TxinToKey extends MoneroTxin {
  final BigInt amount;
  final List<BigInt> keyOffsets;
  final List<int> keyImage;

  TxinToKey(
      {required BigInt amount,
      required List<BigInt> keyOffsets,
      required List<int> keyImage})
      : amount = amount.asUint64,
        keyOffsets = keyOffsets.map((e) => e.asUint64).toList().immutable,
        keyImage = keyImage.asImmutableBytes,
        super(MoneroTxinType.txinToKey);
  factory TxinToKey.fromStruct(Map<String, dynamic> json) {
    return TxinToKey(
        amount: json.as("amount"),
        keyImage: json.asBytes("k_image"),
        keyOffsets: json.asListBig("key_offsets")!);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      MoneroLayoutConst.variantVec(MoneroLayoutConst.varintBigInt(),
          property: "key_offsets"),
      LayoutConst.fixedBlob32(property: "k_image")
    ], property: property);
  }

  TxinToKey copyWith({
    BigInt? amount,
    List<BigInt>? keyOffsets,
    List<int>? keyImage,
  }) {
    return TxinToKey(
        amount: amount ?? this.amount,
        keyOffsets: keyOffsets ?? this.keyOffsets,
        keyImage: keyImage ?? this.keyImage);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"amount": amount, "key_offsets": keyOffsets, "k_image": keyImage};
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "amount": amount.toString(),
      "keyOffsets": keyOffsets.map((e) => e.toString()).toList(),
      "keyImage": BytesUtils.toHexString(keyImage)
    };
  }
}

class TxinToScriptHash extends MoneroTxin {
  final List<int> prev;
  final BigInt prevout;
  final TxoutToScript script;
  final List<int> sigset;

  TxinToScriptHash(
      {required List<int> prev,
      required BigInt prevout,
      required this.script,
      required List<int> sigset})
      : prev = prev.asImmutableBytes,
        prevout = prevout.asUint64,
        sigset = sigset.asImmutableBytes,
        super(MoneroTxinType.txinToScriptHash);
  factory TxinToScriptHash.fromStruct(Map<String, dynamic> json) {
    return TxinToScriptHash(
      prev: json.asBytes("prev"),
      prevout: json.as("prevout"),
      script: TxoutToScript.fromStruct(json.asMap("script")),
      sigset: json.asBytes("sigset"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "prev"),
      MoneroLayoutConst.varintBigInt(property: "prevout"),
      TxoutToScript.layout(property: "script"),
      MoneroLayoutConst.variantVec(LayoutConst.u8(), property: "sigset"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "prev": prev,
      "prevout": prevout,
      "script": script.toLayoutStruct(),
      "sigset": sigset,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "prevout": prevout.toString(),
      "script": script.toJson(),
      "prev": BytesUtils.toHexString(prev),
      "sigset": BytesUtils.toHexString(sigset),
    };
  }
}

class TxinToScript extends MoneroTxin {
  final List<int> prev;
  final BigInt prevout;
  final List<int> sigset;

  TxinToScript(
      {required List<int> prev,
      required BigInt prevout,
      required List<int> sigset})
      : prev = prev.asImmutableBytes,
        prevout = prevout.asUint64,
        sigset = sigset.asImmutableBytes,
        super(MoneroTxinType.txinToScript);
  factory TxinToScript.fromStruct(Map<String, dynamic> json) {
    return TxinToScript(
      prev: json.asBytes("prev"),
      prevout: json.as("prevout"),
      sigset: json.asBytes("sigset"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "prev"),
      MoneroLayoutConst.varintBigInt(property: "prevout"),
      MoneroLayoutConst.variantBytes(property: "sigset"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"prev": prev, "prevout": prevout, "sigset": sigset};
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "prevout": prevout.toString(),
      "prev": BytesUtils.toHexString(prev),
      "sigset": BytesUtils.toHexString(sigset),
    };
  }
}

class TxinGen extends MoneroTxin {
  final BigInt height;
  TxinGen(BigInt height)
      : height = height.asUint64,
        super(MoneroTxinType.txinGen);
  factory TxinGen.fromStruct(Map<String, dynamic> json) {
    return TxinGen(json.as("height"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "height"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"height": height};
  }

  @override
  Map<String, dynamic> toJson() {
    return {"height": height.toString()};
  }
}
