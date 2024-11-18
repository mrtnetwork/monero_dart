import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/models/transaction/transaction/input.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

import 'rct_prunable.dart';

abstract class MoneroTxSignatures extends MoneroSerialization {
  const MoneroTxSignatures();
  factory MoneroTxSignatures.fromStruct(Map<String, dynamic> json) {
    if (json.containsKey("v1")) {
      return MoneroV1Signature.fromStruct(json);
    } else if (json.containsKey("v2")) {
      return RCTSignature.fromStruct(json);
    }
    throw DartMoneroPluginException("Invalid MoneroTxSignatures json struct.",
        details: {"data": json});
  }

  static Layout<Map<String, dynamic>> layout({
    String? property,
    required int version,
    required int inputLength,
    required int outputLength,
    required int mixinLength,
    required List<int>? v1SignaturesLen,
    required bool forcePrunable,
  }) {
    if (version == 1) {
      return MoneroV1Signature.layout(
          inputLength: inputLength,
          signatureLength: v1SignaturesLen,
          property: property);
    } else if (version == 2) {
      return RCTSignature.layout(
          property: property,
          inputLength: inputLength,
          outputLength: outputLength,
          mixinLength: mixinLength,
          forcePrunable: forcePrunable);
    }
    throw const DartMoneroPluginException("Invalid monero tx version.");
  }

  T cast<T extends MoneroTxSignatures>() {
    if (this is! T) {
      throw DartMoneroPluginException("MoneroTxSignatures casting failed.",
          details: {"excepted": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }
}

class RCTSignature<S extends RCTSignatureBase, P extends RctSigPrunable>
    extends MoneroTxSignatures {
  final S signature;
  final P? rctSigPrunable;
  const RCTSignature({required this.signature, this.rctSigPrunable});
  RCTSignature<S, P> copyWith({S? signature, P? rctSigPrunable}) {
    return RCTSignature<S, P>(
        signature: signature ?? this.signature,
        rctSigPrunable: rctSigPrunable ?? this.rctSigPrunable);
  }

  factory RCTSignature.fromStruct(Map<String, dynamic> json) {
    final sig = RCTSignatureBase.fromStruct(json.asMap("v2"));
    final p = json.mybeAs<RctSigPrunable?, Map<String, dynamic>?>(
        key: "rctSigPrunable",
        onValue: (e) {
          if (e?.isEmpty ?? true) return null;
          final rSigType = sig.type;
          return RctSigPrunable.fromStruct(e!, rSigType);
        });
    if (sig is! S) {
      throw const DartMoneroPluginException("RCTSignature casting failed.");
    }
    return RCTSignature(signature: sig, rctSigPrunable: p as P?);
  }
  static Layout<Map<String, dynamic>> layout(
      {int? outputLength,
      int? inputLength,
      MoneroTransaction? transaction,
      int? mixinLength,
      String? property,
      bool forcePrunable = false}) {
    return LayoutConst.lazyStruct([
      LazyLayout(
          layout: ({property}) {
            return RCTSignatureBase.layout(
                property: property,
                inputLength: inputLength,
                outputLength: outputLength);
          },
          property: "v2"),
      ConditionalLazyLayout<Map<String, dynamic>>(
          layout: (
              {required action,
              property,
              required sourceOrResult,
              required remindBytes}) {
            if (transaction != null) {
              if (transaction.signature.cast<RCTSignature>().rctSigPrunable ==
                  null) {
                return LayoutConst.noArgs();
              }
              int mixinLength = 0;
              if (transaction.vin.isNotEmpty &&
                  transaction.vin[0].type == MoneroTxinType.txinToKey) {
                final inp = transaction.vin[0].cast<TxinToKey>();
                mixinLength = inp.keyOffsets.length;
              }
              return RctSigPrunable.layout(
                  outputLength: outputLength ?? 0,
                  type:
                      transaction.signature.cast<RCTSignature>().signature.type,
                  inputLength: inputLength ?? 0,
                  mixinLength: mixinLength);
            }

            final String? ringTypeStr = (sourceOrResult?["v2"] as Map?)?["key"];
            if (ringTypeStr == null) {
              return LayoutConst.noArgs();
            }
            if (remindBytes == 0 && !forcePrunable) {
              return LayoutConst.noArgs();
            }

            final type = RCTType.fromName(ringTypeStr);
            if (type == RCTType.rctTypeNull) {
              return LayoutConst.noArgs();
            }
            return RctSigPrunable.layout(
                outputLength: outputLength ?? 0,
                type: type,
                inputLength: inputLength ?? 0,
                mixinLength: mixinLength ?? 0);
          },
          property: "rctSigPrunable")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout(
      {int? outputLength,
      int? inputLength,
      int? mixinLength,
      String? property}) {
    return layout(
        property: property,
        inputLength: inputLength,
        outputLength: outputLength,
        mixinLength: mixinLength,
        forcePrunable: rctSigPrunable != null);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "v2": signature.toVariantLayoutStruct(),
      "rctSigPrunable": rctSigPrunable?.toLayoutStruct() ?? {}
    };
  }

  RCTType get type => signature.type;
}

class MoneroV1Signature extends MoneroTxSignatures {
  final List<List<int>> signature;
  const MoneroV1Signature(this.signature);
  factory MoneroV1Signature.fromStruct(Map<String, dynamic> json) {
    return MoneroV1Signature(json
        .asListOfMap("v1")!
        .map((e) => List<int>.from(e["signature"]))
        .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {List<int>? signatureLength, int? inputLength, String? property}) {
    int offset = 0;
    return LayoutConst.lazyStruct([
      LazyLayout(
          layout: ({property}) {
            return LayoutConst.seq(
                LayoutConst.lazyStruct([
                  ConditionalLazyLayout(
                      layout: (
                          {required action,
                          property,
                          required remindBytes,
                          required sourceOrResult}) {
                        try {
                          final sigLen = (signatureLength?[offset] ?? 0) * 64;
                          return LayoutConst.fixedBlobN(sigLen);
                        } finally {
                          if (action == LayoutAction.decode &&
                              signatureLength != null &&
                              offset + 1 < signatureLength.length) {
                            offset++;
                          }
                        }
                      },
                      property: "signature")
                ]),
                LayoutConst.constant(inputLength ?? 0, property: "aa"));
          },
          property: "v1")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout(
      {List<int>? signatureLength, int? inputLength, String? property}) {
    return layout(
        property: property,
        inputLength: inputLength,
        signatureLength: signatureLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "v1": signature.map((e) => {"signature": e}).toList()
    };
  }
}

class RCTType {
  final String name;
  final int value;

  const RCTType._(this.name, this.value);

  static const RCTType rctTypeNull = RCTType._('rctTypeNull', 0);
  static const RCTType rctTypeFull = RCTType._('rctTypeFull', 1);
  static const RCTType rctTypeSimple = RCTType._('rctTypeSimple', 2);
  static const RCTType rctTypeBulletproof = RCTType._('rctTypeBulletproof', 3);
  static const RCTType rctTypeBulletproof2 =
      RCTType._('rctTypeBulletproof2', 4);
  static const RCTType rctTypeCLSAG = RCTType._('rctTypeCLSAG', 5);
  static const RCTType rctTypeBulletproofPlus =
      RCTType._('rctTypeBulletproofPlus', 6);
  static const List<RCTType> values = [
    rctTypeNull,
    rctTypeFull,
    rctTypeSimple,
    rctTypeBulletproof,
    rctTypeBulletproof2,
    rctTypeCLSAG,
    rctTypeBulletproofPlus
  ];
  static RCTType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException("Invalid RCTSig type.",
            details: {"type": name}));
  }

  bool get isSimple {
    switch (this) {
      case rctTypeSimple:
      case rctTypeBulletproof:
      case rctTypeBulletproof2:
      case rctTypeCLSAG:
      case rctTypeBulletproofPlus:
        return true;
      default:
        return false;
    }
  }

  bool get isBulletproof {
    switch (this) {
      case rctTypeBulletproof:
      case rctTypeBulletproof2:
      case rctTypeCLSAG:
        return true;
      default:
        return false;
    }
  }

  bool get isBulletproofPlus {
    switch (this) {
      case rctTypeBulletproofPlus:
        return true;
      default:
        return false;
    }
  }

  bool get isClsag {
    switch (this) {
      case rctTypeCLSAG:
      case rctTypeBulletproofPlus:
        return true;
      default:
        return false;
    }
  }

  @override
  String toString() => 'RCTType.$name';
  EcdhInfoVersion get ecdhVersion {
    switch (this) {
      case rctTypeBulletproof2:
      case rctTypeBulletproofPlus:
      case rctTypeCLSAG:
        return EcdhInfoVersion.v2;
      default:
        return EcdhInfoVersion.v1;
    }
  }
}

class EcdhInfoVersion {
  final String name;
  final int version;
  const EcdhInfoVersion._({required this.name, required this.version});
  static const EcdhInfoVersion v1 = EcdhInfoVersion._(name: "V1", version: 1);
  static const EcdhInfoVersion v2 = EcdhInfoVersion._(name: "V2", version: 2);

  @override
  String toString() {
    return "EcdhInfoVersion.$name";
  }
}

class EcdhTuple {
  final RctKey mask;
  final RctKey amount;
  final EcdhInfoVersion version;
  EcdhTuple(
      {required RctKey mask, required RctKey amount, required this.version})
      : mask = mask.asImmutableBytes,
        amount = amount.asImmutableBytes;
}

abstract class EcdhInfo extends MoneroSerialization {
  abstract final List<int> amount;
  abstract final EcdhInfoVersion version;
  T cast<T extends EcdhInfo>() {
    if (this is! T) {
      throw DartMoneroPluginException("EcdhInfo casting failed.",
          details: {"excepted": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }
}

abstract class RCTSignatureBase extends MoneroVariantSerialization {
  final RCTType type;
  RCTSignatureBase({
    required this.type,
    required List<EcdhInfo> ecdhInfo,
    required CtKeyV outPk,
    required RctKey? message,
    required CtKeyM? mixRing,
    required KeyV? pseudoOuts,
    required BigInt txnFee,
  })  : ecdhInfo = ecdhInfo.immutable,
        outPk = outPk.immutable,
        txnFee = txnFee.asUint64,
        pseudoOuts = pseudoOuts
            ?.map((e) => e.asImmutableBytes.exc(32, name: "pseudoOuts"))
            .toList()
            .immutable,
        mixRing = mixRing?.map((e) => e.immutable).toList().immutable,
        message = message?.exc(32, name: "message").asImmutableBytes;
  final List<EcdhInfo> ecdhInfo;
  final CtKeyV outPk;
  final RctKey? message;
  final CtKeyM? mixRing;
  final KeyV? pseudoOuts;
  final BigInt txnFee;
  factory RCTSignatureBase.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = RCTType.fromName(decode.variantName);
    switch (type) {
      case RCTType.rctTypeNull:
        return RCTNull.fromStruct(decode.value);
      case RCTType.rctTypeFull:
        return RCTFull.fromStruct(decode.value);
      case RCTType.rctTypeSimple:
        return RCTSimple.fromStruct(decode.value);
      case RCTType.rctTypeBulletproof:
        return RCTBulletproof.fromStruct(decode.value);
      case RCTType.rctTypeBulletproof2:
        return RCTBulletproof2.fromStruct(decode.value);
      case RCTType.rctTypeCLSAG:
        return RCTCLSAG.fromStruct(decode.value);
      case RCTType.rctTypeBulletproofPlus:
        return RCTBulletproofPlus.fromStruct(decode.value);
      default:
        throw DartMoneroPluginException("Invalid RCTSignature.",
            details: {"type": type, "data": decode.value});
    }
  }
  static Layout<Map<String, dynamic>> layout(
      {int? outputLength, int? inputLength, String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
          layout: RCTNull.layout,
          property: RCTType.rctTypeNull.name,
          index: RCTType.rctTypeNull.value),
      LazyVariantModel(
          layout: ({property}) =>
              RCTFull.layout(property: property, outputLength: outputLength),
          property: RCTType.rctTypeFull.name,
          index: RCTType.rctTypeFull.value),
      LazyVariantModel(
          layout: ({property}) => RCTSimple.layout(
              property: property,
              outputLength: outputLength,
              inputLength: inputLength),
          property: RCTType.rctTypeSimple.name,
          index: RCTType.rctTypeSimple.value),
      LazyVariantModel(
          layout: ({property}) => RCTBulletproof.layout(
              outputLength: outputLength, property: property),
          property: RCTType.rctTypeBulletproof.name,
          index: RCTType.rctTypeBulletproof.value),
      LazyVariantModel(
          layout: ({property}) => RCTBulletproof2.layout(
              property: property, outputLength: outputLength),
          property: RCTType.rctTypeBulletproof2.name,
          index: RCTType.rctTypeBulletproof2.value),
      LazyVariantModel(
          layout: ({property}) =>
              RCTCLSAG.layout(property: property, outputLength: outputLength),
          property: RCTType.rctTypeCLSAG.name,
          index: RCTType.rctTypeCLSAG.value),
      LazyVariantModel(
          layout: ({property}) => RCTBulletproofPlus.layout(
              property: property, outputLength: outputLength),
          property: RCTType.rctTypeBulletproofPlus.name,
          index: RCTType.rctTypeBulletproofPlus.value),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String get variantName => type.name;

  T cast<T extends RCTSignatureBase>() {
    if (this is! T) {
      throw DartMoneroPluginException("RCTSignatureBase casting failed.",
          details: {"excepted": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }
}

class EcdhInfoV2 extends EcdhInfo {
  EcdhInfoV2(List<int> amount)
      : amount = amount.asImmutableBytes.exc(8, name: "EcdhInfoV2");
  @override
  final List<int> amount;
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([LayoutConst.fixedBlobN(8, property: "amount")],
        property: property);
  }

  factory EcdhInfoV2.fromStruct(Map<String, dynamic> json) {
    return EcdhInfoV2(json.asBytes("amount"));
  }
  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"amount": amount};
  }

  @override
  EcdhInfoVersion get version => EcdhInfoVersion.v2;
}

class EcdhInfoV1 extends EcdhInfo {
  final List<int> mask;
  @override
  final List<int> amount;
  EcdhInfoV1({required List<int> amount, required List<int> mask})
      : amount = amount.asImmutableBytes.exc(32, name: "amount"),
        mask = mask.asImmutableBytes.exc(32, name: "mask");
  factory EcdhInfoV1.fromStruct(Map<String, dynamic> json) {
    return EcdhInfoV1(
        amount: json.asBytes("amount"), mask: json.asBytes("mask"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "amount")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"amount": amount, "mask": mask};
  }

  @override
  EcdhInfoVersion get version => EcdhInfoVersion.v1;
}

class RCTNull extends RCTSignatureBase {
  RCTNull()
      : super(
            type: RCTType.rctTypeNull,
            ecdhInfo: [],
            outPk: [],
            message: null,
            mixRing: null,
            pseudoOuts: null,
            txnFee: BigInt.zero);
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.noArgs(property: property);
  }

  factory RCTNull.fromStruct(Map<String, dynamic> json) {
    json.asEmpty();
    return RCTNull();
  }
  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {};
  }

  @override
  List<EcdhInfoV2> get ecdhInfo => throw const DartMoneroPluginException(
      "RCTNULL does not support ECDH information.");
  @override
  List<CtKey> get outPk => throw const DartMoneroPluginException(
      "RCTNULL does not support public key information.");
  @override
  BigInt get txnFee => throw const DartMoneroPluginException(
      "RCTNULL does not support txnFee information.");
}

class RCTCLSAG extends RCTSignatureBase {
  RCTCLSAG._({
    required List<EcdhInfoV2> super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    required super.type,
    super.message,
    super.mixRing,
  }) : super(
            pseudoOuts: null);

  RCTCLSAG({
    required List<EcdhInfoV2> super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super(
            type: RCTType.rctTypeCLSAG,
            pseudoOuts: null);
  factory RCTCLSAG.fromStruct(Map<String, dynamic> json) {
    return RCTCLSAG(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV2.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int? outputLength}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "txnFee"),
      LayoutConst.seq(
          EcdhInfoV2.layout(), ConstantLayout<int>(outputLength ?? 0),
          property: "ecdhInfo"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), ConstantLayout<int>(outputLength ?? 0),
          property: "outPk"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, outputLength: outPk.length);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "txnFee": txnFee,
      "ecdhInfo": ecdhInfo.map((e) => e.toLayoutStruct()).toList(),
      "outPk": outPk.map((e) => e.mask).toList()
    };
  }
}

class RCTSimple extends RCTSignatureBase {
  RCTSimple({
    required List<EcdhInfoV1> super.ecdhInfo,
    required super.txnFee,
    required List<List<int>> super.pseudoOuts,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super(
            type: RCTType.rctTypeSimple);
  factory RCTSimple.fromStruct(Map<String, dynamic> json) {
    return RCTSimple(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV1.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        pseudoOuts: json.asListBytes("pseudoOuts")!,
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, int? outputLength, int? inputLength}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "txnFee"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(inputLength ?? 0),
          property: "pseudoOuts"),
      LayoutConst.seq(
          EcdhInfoV1.layout(), LayoutConst.constant(outputLength ?? 0),
          property: "ecdhInfo"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(outputLength ?? 0),
          property: "outPk")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(
        property: property,
        outputLength: outPk.length,
        inputLength: pseudoOuts!.length);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "txnFee": txnFee,
      "pseudoOuts": pseudoOuts,
      "ecdhInfo": ecdhInfo.map((e) => e.toLayoutStruct()).toList(),
      "outPk": outPk.map((e) => e.mask).toList()
    };
  }
}

class RCTBulletproof2 extends RCTCLSAG {
  RCTBulletproof2({
    required super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super._(
            type: RCTType.rctTypeBulletproof2);
  factory RCTBulletproof2.fromStruct(Map<String, dynamic> json) {
    return RCTBulletproof2(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV2.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int? outputLength}) {
    return RCTCLSAG.layout(property: property, outputLength: outputLength);
  }
}

class RCTBulletproofPlus extends RCTCLSAG {
  RCTBulletproofPlus({
    required super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super._(
            type: RCTType.rctTypeBulletproofPlus);
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int? outputLength}) {
    return RCTCLSAG.layout(property: property, outputLength: outputLength);
  }

  factory RCTBulletproofPlus.fromStruct(Map<String, dynamic> json) {
    return RCTBulletproofPlus(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV2.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
}

class RCTFull extends RCTSignatureBase {
  RCTFull({
    required List<EcdhInfoV1> super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super(
            type: RCTType.rctTypeFull,
            pseudoOuts: null);
  factory RCTFull.fromStruct(Map<String, dynamic> json) {
    return RCTFull(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV1.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, int? outputLength}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "txnFee"),
      LayoutConst.seq(
          EcdhInfoV1.layout(), LayoutConst.constant(outputLength ?? 0),
          property: "ecdhInfo"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(outputLength ?? 0),
          property: "outPk")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, outputLength: outPk.length);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "txnFee": txnFee,
      "ecdhInfo": ecdhInfo.map((e) => e.toLayoutStruct()).toList(),
      "outPk": outPk.map((e) => e.mask).toList()
    };
  }
}

class RCTBulletproof extends RCTSignatureBase {
  RCTBulletproof({
    required List<EcdhInfoV1> super.ecdhInfo,
    required super.txnFee,
    required super.outPk,
    super.message,
    super.mixRing,
  }) : super(
            type: RCTType.rctTypeBulletproof,
            pseudoOuts: null);
  factory RCTBulletproof.fromStruct(Map<String, dynamic> json) {
    return RCTBulletproof(
        ecdhInfo: json
            .asListOfMap("ecdhInfo")!
            .map((e) => EcdhInfoV1.fromStruct(e))
            .toList(),
        txnFee: json.as("txnFee"),
        outPk: json
            .asListBytes("outPk")!
            .map((e) => CtKey(dest: RCT.zero(), mask: e))
            .toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, int? outputLength}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "txnFee"),
      LayoutConst.seq(
          EcdhInfoV1.layout(), LayoutConst.constant(outputLength ?? 0),
          property: "ecdhInfo"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(outputLength ?? 0),
          property: "outPk")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, outputLength: outPk.length);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "txnFee": txnFee,
      "ecdhInfo": ecdhInfo.map((e) => e.toLayoutStruct()).toList(),
      "outPk": outPk.map((e) => e.mask).toList()
    };
  }
}
