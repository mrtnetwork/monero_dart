import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/transaction/output.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

enum MoneroTxinType {
  txinGen(name: "TxinGen", variantId: 0xff),
  txinToScript(name: "TxinToScript", variantId: 0x0),
  txinToScriptHash(name: "TxinToScriptHash", variantId: 0x1),
  txinToKey(name: "TxinToKey", variantId: 0x2);

  final String name;
  final int variantId;
  bool get isCoinBase => this == txinGen;
  const MoneroTxinType({required this.name, required this.variantId});
  static MoneroTxinType fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw ItemNotFoundException(name: "MoneroTxinType", value: name),
    );
  }
}

/// txin_v
abstract class MoneroTxin extends MoneroVariantSerialization {
  final MoneroTxinType type;
  const MoneroTxin(this.type);
  factory MoneroTxin.deserializeJson(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroTxinType.fromName(decode.variantName);
    switch (type) {
      case MoneroTxinType.txinGen:
        return TxinGen.deserializeJson(decode.value);
      case MoneroTxinType.txinToScript:
        return TxinToScript.deserializeJson(decode.value);
      case MoneroTxinType.txinToScriptHash:
        return TxinToScriptHash.deserializeJson(decode.value);
      case MoneroTxinType.txinToKey:
        return TxinToKey.deserializeJson(decode.value);
    }
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: TxinGen.layout,
        property: MoneroTxinType.txinGen.name,
        index: MoneroTxinType.txinGen.variantId,
      ),
      LazyVariantModel(
        layout: TxinToScript.layout,
        property: MoneroTxinType.txinToScript.name,
        index: MoneroTxinType.txinToScript.variantId,
      ),
      LazyVariantModel(
        layout: TxinToScriptHash.layout,
        property: MoneroTxinType.txinToScriptHash.name,
        index: MoneroTxinType.txinToScriptHash.variantId,
      ),
      LazyVariantModel(
        layout: TxinToKey.layout,
        property: MoneroTxinType.txinToKey.name,
        index: MoneroTxinType.txinToKey.variantId,
      ),
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
      throw DartMoneroPluginException(
        "MoneroTxin casting failed.",
        details: {"expected": "$T", "type": type.name},
      );
    }
    return this as T;
  }

  Map<String, dynamic> toJson();

  TxKeyImage? getKeyImage() {
    if (type != MoneroTxinType.txinToKey) return null;
    return cast<TxinToKey>().keyImage;
  }
}

class TxinToKey extends MoneroTxin {
  final BigInt amount;
  final List<BigInt> keyOffsets;
  final TxKeyImage keyImage;

  TxinToKey({
    required BigInt amount,
    required List<BigInt> keyOffsets,
    required this.keyImage,
  }) : amount = amount.asU64,
       keyOffsets = keyOffsets.map((e) => e.asU64).toList().immutable,

       super(MoneroTxinType.txinToKey);
  factory TxinToKey.deserializeJson(Map<String, dynamic> json) {
    return TxinToKey(
      amount: json.valueAs("amount"),
      keyImage: TxKeyImage.deserializeJson(json.valueEnsureAsMap("k_image")),
      keyOffsets: json.valueEnsureAsList<BigInt>("key_offsets"),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      MoneroLayoutConst.variantVec(
        MoneroLayoutConst.varintBigInt(),
        property: "key_offsets",
      ),
      TxKeyImage.layout(property: "k_image"),
    ], property: property);
  }

  TxinToKey copyWith({
    BigInt? amount,
    List<BigInt>? keyOffsets,
    TxKeyImage? keyImage,
  }) {
    return TxinToKey(
      amount: amount ?? this.amount,
      keyOffsets: keyOffsets ?? this.keyOffsets,
      keyImage: keyImage ?? this.keyImage,
    );
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "amount": amount,
      "key_offsets": keyOffsets,
      "k_image": keyImage.toLayoutStruct(),
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "amount": amount.toString(),
      "keyOffsets": keyOffsets.map((e) => e.toString()).toList(),
      "keyImage": keyImage.toHex(),
    };
  }
}

class TxinToScriptHash extends MoneroTxin {
  final List<int> prev;
  final BigInt prevout;
  final TxoutToScript script;
  final List<int> sigset;

  TxinToScriptHash({
    required List<int> prev,
    required BigInt prevout,
    required this.script,
    required List<int> sigset,
  }) : prev = prev.asImmutableBytes,
       prevout = prevout.asU64,
       sigset = sigset.asImmutableBytes,
       super(MoneroTxinType.txinToScriptHash);
  factory TxinToScriptHash.deserializeJson(Map<String, dynamic> json) {
    return TxinToScriptHash(
      prev: json.valueAsBytes("prev"),
      prevout: json.valueAs("prevout"),
      script: TxoutToScript.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("script"),
      ),
      sigset: json.valueAsBytes("sigset"),
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

  TxinToScript({
    required List<int> prev,
    required BigInt prevout,
    required List<int> sigset,
  }) : prev = prev.asImmutableBytes,
       prevout = prevout.asU64,
       sigset = sigset.asImmutableBytes,
       super(MoneroTxinType.txinToScript);
  factory TxinToScript.deserializeJson(Map<String, dynamic> json) {
    return TxinToScript(
      prev: json.valueAsBytes("prev"),
      prevout: json.valueAs("prevout"),
      sigset: json.valueAsBytes("sigset"),
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
  TxinGen(BigInt height) : height = height.asU64, super(MoneroTxinType.txinGen);
  factory TxinGen.deserializeJson(Map<String, dynamic> json) {
    return TxinGen(json.valueAs("height"));
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

class TxKeyImage extends MoneroSerialization
    with Equality, CborTagSerializable {
  final List<int> keyImage;
  TxKeyImage(List<int> keyImage)
    : keyImage = keyImage.asImmutableBytes.exc(
        length: Ed25519KeysConst.privKeyByteLen,
        operation: "TxKeyImage",
        reason: "Invalid key image bytes length.",
      );
  factory TxKeyImage.deserializeJson(Map<String, dynamic> json) {
    return TxKeyImage(json.valueAsBytes("key_image"));
  }
  factory TxKeyImage.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.keyImage,
      cborBytes: bytes,
      cborObject: obj,
    );
    return TxKeyImage(values.rawValueAt(0));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlobN(
        Ed25519KeysConst.privKeyByteLen,
        property: "key_image",
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"key_image": keyImage};
  }

  String toHex() => BytesUtils.toHexString(keyImage);

  @override
  List<dynamic> get variables => [keyImage];

  @override
  SerializationIdentifier get serializationIdentifier =>
      MoneroSerializationIdentifiers.keyImage;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(keyImage)];
}
