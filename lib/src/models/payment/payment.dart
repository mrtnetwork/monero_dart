import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/helper/transaction.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

import '../../provider/models/daemon/basic_models.dart';

class MoneroOutputType {
  final int value;
  final String name;
  const MoneroOutputType._({required this.value, required this.name});
  static const MoneroOutputType locked =
      MoneroOutputType._(value: 0, name: "locked");
  static const MoneroOutputType unlocked =
      MoneroOutputType._(value: 1, name: "unlocked");
  static const MoneroOutputType unlockedMultisig =
      MoneroOutputType._(value: 2, name: "unlockedMultisig");
  static const List<MoneroOutputType> values = [locked, unlocked];
  static MoneroOutputType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException("Invalid output type.",
            details: {"type": name}));
  }

  @override
  String toString() {
    return "MoneroOutputType.$name";
  }
}

class MoneroPaymentType {
  final int value;
  final String name;
  const MoneroPaymentType._({required this.value, required this.name});
  static const MoneroPaymentType locked =
      MoneroPaymentType._(value: 0, name: "locked");
  static const MoneroPaymentType unlocked =
      MoneroPaymentType._(value: 1, name: "unlocked");
  static const MoneroPaymentType unlockedMultisig =
      MoneroPaymentType._(value: 2, name: "unlockedMultisig");
  static const List<MoneroPaymentType> values = [
    locked,
    unlocked,
    unlockedMultisig
  ];
  static MoneroPaymentType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException("Invalid payment type.",
            details: {"type": name}));
  }

  @override
  String toString() {
    return "MoneroPaymentType.$name";
  }
}

abstract class MoneroOutput extends MoneroVariantSerialization {
  final BigInt amount;
  final MoneroAccountIndex accountIndex;
  final MoneroOutputType type;
  final RctKey mask;
  final RctKey derivation;
  final List<int> outputPublicKey;
  final BigInt unlockTime;
  final int realIndex;
  MoneroOutput(
      {required BigInt amount,
      required this.accountIndex,
      required this.type,
      required RctKey mask,
      required RctKey derivation,
      required List<int> outputPublicKey,
      required BigInt unlockTime,
      required int realIndex})
      : amount = amount.asUint64,
        mask = mask.asImmutableBytes.exc(32),
        derivation = derivation.asImmutableBytes.exc(32),
        unlockTime = unlockTime.asUint64,
        realIndex = realIndex.asUint32,
        outputPublicKey = outputPublicKey.exc(32);
  factory MoneroOutput.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroOutput.fromStruct(decode);
  }

  factory MoneroOutput.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroOutputType.fromName(decode.variantName);
    switch (type) {
      case MoneroOutputType.locked:
        return MoneroLockedOutput.fromStruct(decode.value);
      case MoneroOutputType.unlocked:
        return MoneroUnlockedOutput.fromStruct(decode.value);
      case MoneroOutputType.unlockedMultisig:
        return MoneroUnlockedMultisigOutput.fromStruct(decode.value);
      default:
        throw UnimplementedError("Invalid monero output type.");
    }
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: MoneroLockedOutput.layout,
        property: MoneroOutputType.locked.name,
        index: MoneroOutputType.locked.value,
      ),
      LazyVariantModel(
        layout: MoneroUnlockedOutput.layout,
        property: MoneroOutputType.unlocked.name,
        index: MoneroOutputType.unlocked.value,
      ),
      LazyVariantModel(
        layout: MoneroUnlockedMultisigOutput.layout,
        property: MoneroOutputType.unlockedMultisig.name,
        index: MoneroOutputType.unlockedMultisig.value,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String get variantName => type.name;
  Map<String, dynamic> toJson() {
    return {
      "amount": amount,
      "mask": BytesUtils.toHexString(mask),
      "derivation": BytesUtils.toHexString(derivation),
      "accountIndex": accountIndex.toJson(),
      "outputPublicKey": BytesUtils.toHexString(outputPublicKey),
      "unlockTime": unlockTime,
      "realIndex": realIndex
    };
  }

  T cast<T extends MoneroOutput>() {
    if (this is! T) {
      throw DartMoneroPluginException("Monero output casting failed.",
          details: {"expected": "$T", "type": type.name});
    }
    return this as T;
  }

  @override
  String toString() {
    return "{amount: ${MoneroTransactionHelper.toXMR(amount)} status: ${type.name} accountIndex: $accountIndex}";
  }
}

class MoneroLockedOutput extends MoneroOutput {
  MoneroLockedOutput(
      {required super.amount,
      required super.mask,
      required super.derivation,
      required super.outputPublicKey,
      required super.accountIndex,
      required super.unlockTime,
      required super.realIndex})
      : super(type: MoneroOutputType.locked);
  factory MoneroLockedOutput.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroLockedOutput.fromStruct(decode);
  }
  factory MoneroLockedOutput.fromStruct(Map<String, dynamic> json) {
    return MoneroLockedOutput(
        amount: json.as("amount"),
        accountIndex: MoneroAccountIndex.fromStruct(json.asMap("accountIndex")),
        mask: json.asBytes("mask"),
        derivation: json.asBytes("derivation"),
        outputPublicKey: json.asBytes("outputPublicKey"),
        unlockTime: json.as("unlockTime"),
        realIndex: json.as("realIndex"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      MoneroAccountIndex.layout(property: "accountIndex"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "amount": amount,
      "accountIndex": accountIndex.toLayoutStruct(),
      "mask": mask,
      "derivation": derivation,
      "outputPublicKey": outputPublicKey,
      "unlockTime": unlockTime,
      "realIndex": realIndex
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class MoneroUnlockedOutput extends MoneroOutput {
  final RctKey ephemeralSecretKey;
  final RctKey ephemeralPublicKey;
  final RctKey keyImage;
  String get keyImageAsHex => BytesUtils.toHexString(keyImage);

  CtKey get toSecretKey => CtKey(dest: ephemeralSecretKey, mask: mask);
  MoneroUnlockedOutput._({
    required super.amount,
    required super.derivation,
    required RctKey ephemeralSecretKey,
    required RctKey ephemeralPublicKey,
    required RctKey keyImage,
    required super.mask,
    required super.outputPublicKey,
    required super.accountIndex,
    required super.unlockTime,
    required super.realIndex,
    MoneroOutputType type = MoneroOutputType.unlocked,
  })  : ephemeralPublicKey = ephemeralPublicKey.asImmutableBytes.exc(32),
        ephemeralSecretKey = ephemeralSecretKey.asImmutableBytes.exc(32),
        keyImage = keyImage.asImmutableBytes.exc(32),
        super(type: MoneroOutputType.unlocked);
  factory MoneroUnlockedOutput(
      {required BigInt amount,
      required RctKey derivation,
      required RctKey ephemeralSecretKey,
      required RctKey ephemeralPublicKey,
      required RctKey keyImage,
      required RctKey mask,
      required RctKey outputPublicKey,
      required MoneroAccountIndex accountIndex,
      required BigInt unlockTime,
      required int realIndex}) {
    return MoneroUnlockedOutput._(
        amount: amount,
        derivation: derivation,
        ephemeralSecretKey: ephemeralSecretKey,
        ephemeralPublicKey: ephemeralPublicKey,
        keyImage: keyImage,
        mask: mask,
        outputPublicKey: outputPublicKey,
        accountIndex: accountIndex,
        unlockTime: unlockTime,
        realIndex: realIndex);
  }
  factory MoneroUnlockedOutput.fromStruct(Map<String, dynamic> json) {
    return MoneroUnlockedOutput(
        amount: json.as("amount"),
        accountIndex: MoneroAccountIndex.fromStruct(json.asMap("accountIndex")),
        derivation: json.asBytes("derivation"),
        mask: json.asBytes("mask"),
        ephemeralPublicKey: json.asBytes("ephemeralPublicKey"),
        ephemeralSecretKey: json.asBytes("ephemeralSecretKey"),
        keyImage: json.asBytes("keyImage"),
        outputPublicKey: json.asBytes("outputPublicKey"),
        unlockTime: json.as("unlockTime"),
        realIndex: json.as("realIndex"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      LayoutConst.fixedBlob32(property: "ephemeralSecretKey"),
      LayoutConst.fixedBlob32(property: "ephemeralPublicKey"),
      LayoutConst.fixedBlob32(property: "keyImage"),
      MoneroAccountIndex.layout(property: "accountIndex"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "amount": amount,
      "mask": mask,
      "derivation": derivation,
      "ephemeralSecretKey": ephemeralSecretKey,
      "ephemeralPublicKey": ephemeralPublicKey,
      "keyImage": keyImage,
      "accountIndex": accountIndex.toLayoutStruct(),
      "outputPublicKey": outputPublicKey,
      "unlockTime": unlockTime,
      "realIndex": realIndex
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "ephemeralSecretKey": BytesUtils.toHexString(ephemeralSecretKey),
      "ephemeralPublicKey": BytesUtils.toHexString(ephemeralPublicKey),
      "keyImage": BytesUtils.toHexString(keyImage),
      "realIndex": realIndex
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class MoneroUnlockedMultisigOutput extends MoneroUnlockedOutput {
  final RctKey multisigKeyImage;
  MoneroUnlockedMultisigOutput(
      {required super.amount,
      required super.derivation,
      required super.ephemeralSecretKey,
      required super.ephemeralPublicKey,
      required RctKey multisigKeyImage,
      required super.keyImage,
      required super.mask,
      required super.outputPublicKey,
      required super.accountIndex,
      required super.unlockTime,
      required super.realIndex})
      : multisigKeyImage = multisigKeyImage.asImmutableBytes.exc(32),
        super._(type: MoneroOutputType.unlockedMultisig);
  factory MoneroUnlockedMultisigOutput.fromStruct(Map<String, dynamic> json) {
    return MoneroUnlockedMultisigOutput(
        amount: json.as("amount"),
        accountIndex: MoneroAccountIndex.fromStruct(json.asMap("accountIndex")),
        derivation: json.asBytes("derivation"),
        mask: json.asBytes("mask"),
        ephemeralPublicKey: json.asBytes("ephemeralPublicKey"),
        ephemeralSecretKey: json.asBytes("ephemeralSecretKey"),
        keyImage: json.asBytes("keyImage"),
        unlockTime: json.as("unlockTime"),
        outputPublicKey: json.asBytes("outputPublicKey"),
        multisigKeyImage: json.asBytes("multisigKeyImage"),
        realIndex: json.as("realIndex"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      LayoutConst.fixedBlob32(property: "ephemeralSecretKey"),
      LayoutConst.fixedBlob32(property: "ephemeralPublicKey"),
      LayoutConst.fixedBlob32(property: "keyImage"),
      LayoutConst.fixedBlob32(property: "multisigKeyImage"),
      MoneroAccountIndex.layout(property: "accountIndex"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "amount": amount,
      "mask": mask,
      "derivation": derivation,
      "ephemeralSecretKey": ephemeralSecretKey,
      "ephemeralPublicKey": ephemeralPublicKey,
      "keyImage": keyImage,
      "accountIndex": accountIndex.toLayoutStruct(),
      "outputPublicKey": outputPublicKey,
      "multisigKeyImage": multisigKeyImage,
      "unlockTime": unlockTime,
      "realIndex": realIndex
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

abstract class MoneroPayment<T extends MoneroOutput>
    extends MoneroVariantSerialization {
  final MoneroPaymentType type;
  final T output;
  final List<int> txPubkey;
  final RctKey? paymentId;
  final RctKey? encryptedPaymentid;
  final BigInt globalIndex;
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "output": output.toJson(),
      "txPubkey": txPubkey,
      "paymentId": BytesUtils.tryToHexString(paymentId),
      "encryptedPaymentid": BytesUtils.tryToHexString(encryptedPaymentid),
      "globalIndex": globalIndex.toString()
    };
  }

  MoneroPayment({
    required this.type,
    required this.output,
    required List<int> txPubkey,
    required RctKey? paymentId,
    required RctKey? encryptedPaymentid,
    required this.globalIndex,
  })  : paymentId = paymentId?.asImmutableBytes,
        encryptedPaymentid = encryptedPaymentid?.asImmutableBytes,
        txPubkey = txPubkey.exc(32, name: "public key.");
  factory MoneroPayment.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroPayment.fromStruct(decode);
  }

  factory MoneroPayment.fromStruct(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroPaymentType.fromName(decode.variantName);
    final MoneroPayment payment;
    switch (type) {
      case MoneroPaymentType.locked:
        payment = MoneroLockedPayment.fromStruct(decode.value);
        break;
      case MoneroPaymentType.unlocked:
        payment = MoneroUnLockedPayment.fromStruct(decode.value);
        break;
      case MoneroPaymentType.unlockedMultisig:
        payment = MoneroUnlockedMultisigPayment.fromStruct(decode.value);
        break;
      default:
        throw UnimplementedError("Invalid monero payment type.");
    }
    if (payment is! MoneroPayment<T>) {
      throw DartMoneroPluginException("Monero payment casting failed.",
          details: {"expected": "$T", "type": type.name});
    }
    return payment;
  }

  @override
  String get variantName => type.name;
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: MoneroLockedPayment.layout,
        property: MoneroPaymentType.locked.name,
        index: MoneroPaymentType.locked.value,
      ),
      LazyVariantModel(
        layout: MoneroUnLockedPayment.layout,
        property: MoneroPaymentType.unlocked.name,
        index: MoneroPaymentType.unlocked.value,
      ),
      LazyVariantModel(
        layout: MoneroUnlockedMultisigPayment.layout,
        property: MoneroPaymentType.unlockedMultisig.name,
        index: MoneroPaymentType.unlockedMultisig.value,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  E cast<E extends MoneroPayment>() {
    if (this is! E) {
      throw DartMoneroPluginException("Payment casting failed.",
          details: {"expected": "$E", "type": type.name});
    }
    return this as E;
  }

  @override
  String toString() {
    return output.toString();
  }
}

class MoneroLockedPayment extends MoneroPayment<MoneroLockedOutput> {
  MoneroLockedPayment({
    required super.output,
    required super.txPubkey,
    required super.paymentId,
    required super.encryptedPaymentid,
    required super.globalIndex,
  }) : super(type: MoneroPaymentType.locked);

  factory MoneroLockedPayment.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroLockedPayment.fromStruct(decode);
  }
  factory MoneroLockedPayment.fromStruct(Map<String, dynamic> json) {
    return MoneroLockedPayment(
        output: MoneroLockedOutput.fromStruct(json.asMap("output")),
        txPubkey: json.asBytes("txPubkey"),
        encryptedPaymentid: json.asBytes("encryptedPaymentid"),
        paymentId: json.asBytes("paymentId"),
        globalIndex: json.as("globalIndex"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLockedOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8),
          property: "encryptedPaymentid"),
      MoneroLayoutConst.varintBigInt(property: "globalIndex"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "output": output.toLayoutStruct(),
      "txPubkey": txPubkey,
      "paymentId": paymentId,
      "encryptedPaymentid": encryptedPaymentid,
      "globalIndex": globalIndex
    };
  }
}

class MoneroUnLockedPayment<T extends MoneroUnlockedOutput>
    extends MoneroPayment<T> {
  RctKey get keyImage => output.keyImage;
  String get keyImageAsHex => BytesUtils.toHexString(keyImage);
  MoneroUnLockedPayment._(
      {required super.output,
      required super.txPubkey,
      super.paymentId,
      super.encryptedPaymentid,
      required super.type,
      required super.globalIndex});
  MoneroUnLockedPayment(
      {required super.output,
      required super.txPubkey,
      super.paymentId,
      super.encryptedPaymentid,
      required super.globalIndex})
      : super(type: MoneroPaymentType.unlocked);
  factory MoneroUnLockedPayment.fromStruct(Map<String, dynamic> json) {
    return MoneroUnLockedPayment(
      output: MoneroUnlockedOutput.fromStruct(json.asMap("output")).cast<T>(),
      txPubkey: json.asBytes("txPubkey"),
      encryptedPaymentid: json.asBytes("encryptedPaymentid"),
      paymentId: json.asBytes("paymentId"),
      globalIndex: json.as("globalIndex"),
    );
  }
  factory MoneroUnLockedPayment.deserialize(List<int> bytes,
      {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroUnLockedPayment.fromStruct(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroUnlockedOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8),
          property: "encryptedPaymentid"),
      MoneroLayoutConst.varintBigInt(property: "globalIndex"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "output": output.toLayoutStruct(),
      "txPubkey": txPubkey,
      "paymentId": paymentId,
      "encryptedPaymentid": encryptedPaymentid,
      "globalIndex": globalIndex,
    };
  }

  @override
  operator ==(other) {
    if (other is! MoneroUnLockedPayment) return false;
    if (identical(this, other)) return true;
    return BytesUtils.bytesEqual(keyImage, other.keyImage);
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(keyImage);
}

class MoneroUnlockedMultisigPayment
    extends MoneroUnLockedPayment<MoneroUnlockedMultisigOutput> {
  @override
  RctKey get keyImage => output.multisigKeyImage;
  final List<MoneroMultisigOutputInfo> multisigInfos;
  MoneroUnlockedMultisigPayment({
    required super.output,
    required super.txPubkey,
    required super.paymentId,
    required super.encryptedPaymentid,
    required super.globalIndex,
    required List<MoneroMultisigOutputInfo> multisigInfos,
  })  : multisigInfos = multisigInfos.immutable,
        super._(type: MoneroPaymentType.unlockedMultisig);
  factory MoneroUnlockedMultisigPayment.fromStruct(Map<String, dynamic> json) {
    return MoneroUnlockedMultisigPayment(
        output: MoneroUnlockedMultisigOutput.fromStruct(json.asMap("output")),
        txPubkey: json.asBytes("txPubkey"),
        encryptedPaymentid: json.asBytes("encryptedPaymentid"),
        paymentId: json.asBytes("paymentId"),
        multisigInfos: json
            .asListOfMap("multisigInfos")!
            .map((e) => MoneroMultisigOutputInfo.fromStruct(e))
            .toList(),
        globalIndex: json.as("globalIndex"));
  }
  factory MoneroUnlockedMultisigPayment.deserialize(List<int> bytes,
      {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroUnlockedMultisigPayment.fromStruct(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroUnlockedMultisigOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8),
          property: "encryptedPaymentid"),
      MoneroLayoutConst.varintBigInt(property: "globalIndex"),
      MoneroLayoutConst.variantVec(MoneroMultisigOutputInfo.layout(),
          property: "multisigInfos"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "output": output.toLayoutStruct(),
      "txPubkey": txPubkey,
      "paymentId": paymentId,
      "encryptedPaymentid": encryptedPaymentid,
      "multisigInfos": multisigInfos.map((e) => e.toLayoutStruct()).toList(),
      "globalIndex": globalIndex
    };
  }

  @override
  operator ==(other) {
    if (other is! MoneroUnlockedMultisigPayment) return false;
    if (identical(this, other)) return true;
    return BytesUtils.bytesEqual(keyImage, other.keyImage);
  }

  @override
  int get hashCode => HashCodeGenerator.generateBytesHashCode(keyImage);
}

class SpendablePayment<T extends MoneroPayment> extends MoneroSerialization {
  final T payment;
  final List<OutsEntery> outs;
  final int realOutIndex;

  SpendablePayment<E> updatePayment<E extends MoneroPayment>(E updatePayment) {
    return SpendablePayment<E>(
        payment: updatePayment, outs: outs, realOutIndex: realOutIndex);
  }

  SpendablePayment(
      {required this.payment,
      required List<OutsEntery> outs,
      required int realOutIndex})
      : outs = outs.immutable,
        realOutIndex = realOutIndex.asUint32;
  factory SpendablePayment.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return SpendablePayment.fromStruct(decode);
  }
  factory SpendablePayment.fromStruct(Map<String, dynamic> json) {
    return SpendablePayment(
        payment: MoneroPayment.fromStruct(json.asMap("payment")).cast<T>(),
        outs: json
            .asListOfMap("outs")!
            .map((e) => OutsEntery.fromStruct(e))
            .toList(),
        realOutIndex: json.as("realOutIndex"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroPayment.layout(property: "payment"),
      MoneroLayoutConst.variantVec(OutsEntery.layout(), property: "outs"),
      MoneroLayoutConst.varintInt(property: "realOutIndex")
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "payment": payment.toVariantLayoutStruct(),
      "outs": outs.map((e) => e.toLayoutStruct()).toList(),
      "realOutIndex": realOutIndex
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  Map<String, dynamic> toJson() {
    return {
      "outs": outs.map((e) => e.toJson()).toList(),
      "realOutIndex": realOutIndex,
      "payment": payment.toJson()
    };
  }
}

class UnlockMultisigOutputRequest {
  final List<MoneroMultisigOutputInfo> multisigInfos;
  final MoneroUnLockedPayment payment;
  UnlockMultisigOutputRequest(
      {required this.payment,
      required List<MoneroMultisigOutputInfo> multisigInfos})
      : multisigInfos = multisigInfos.immutable;
}

class MoneroTransactionWithOutputIndeces {
  final MoneroTransaction transaction;
  final List<BigInt> outputIndices;
  MoneroTransactionWithOutputIndeces._(
      {required this.transaction, required List<BigInt> outputIndices})
      : outputIndices = outputIndices.immutable;
  factory MoneroTransactionWithOutputIndeces.unSafe({
    required MoneroTransaction transaction,
    required List<BigInt> outputIndices,
  }) {
    if (outputIndices.isNotEmpty &&
        transaction.vout.length != outputIndices.length) {
      throw DartMoneroPluginException(
          "Invalid output indices length: the number of transaction outputs must match the number of output indices.",
          details: {
            "out_indices": outputIndices,
            "output": transaction.vout.length
          });
    }
    return MoneroTransactionWithOutputIndeces._(
        transaction: transaction, outputIndices: outputIndices);
  }
  factory MoneroTransactionWithOutputIndeces({
    required MoneroTransaction transaction,
    required List<BigInt> outputIndices,
  }) {
    if (transaction.vout.length != outputIndices.length) {
      throw DartMoneroPluginException(
          "Invalid output indices length: the number of transaction outputs must match the number of output indices.",
          details: {
            "out_indices": outputIndices,
            "output": transaction.vout.length
          });
    }
    return MoneroTransactionWithOutputIndeces._(
        transaction: transaction, outputIndices: outputIndices);
  }

  bool get hasIndices => outputIndices.isNotEmpty;
}

class MoneroTxDestination extends MoneroSerialization {
  final BigInt amount;
  final MoneroAddress address;
  String get amountAsXMR => MoneroTransactionHelper.toXMR(amount);
  MoneroTxDestination({required BigInt amount, required this.address})
      : amount = amount.asUint64;
  factory MoneroTxDestination.fromXMR(
      {required MoneroAddress address, required String amount}) {
    final piconero = MoneroTransactionHelper.toPiconero(amount);
    return MoneroTxDestination(amount: piconero, address: address);
  }
  factory MoneroTxDestination.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroTxDestination.fromStruct(decode);
  }
  factory MoneroTxDestination.fromStruct(Map<String, dynamic> json) {
    return MoneroTxDestination(
        amount: json.as("amount"),
        address: MoneroAddress.fromStruct(json.asMap("address")));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      MoneroAddress.layout(property: "address"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"amount": amount, "address": address.toLayoutStruct()};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String toString() {
    return {
      "amount": MoneroTransactionHelper.toXMR(amount),
      "address": address.toString()
    }.toString();
  }
}

class MoneroAccountIndex extends MoneroSerialization {
  final int major;
  final int minor;
  const MoneroAccountIndex({this.major = 0, this.minor = 0});
  factory MoneroAccountIndex.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroAccountIndex.fromStruct(decode);
  }
  static const MoneroAccountIndex primary = MoneroAccountIndex();
  static const MoneroAccountIndex minor1 = MoneroAccountIndex(minor: 1);
  bool get isSubaddress {
    return major != 0 || minor != 0;
  }

  factory MoneroAccountIndex.fromStruct(Map<String, dynamic> json) {
    return MoneroAccountIndex(major: json.as("major"), minor: json.as("minor"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.u32(property: "major"),
      LayoutConst.u32(property: "minor")
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"major": major, "minor": minor};
  }

  Map<String, dynamic> toJson() {
    return {"major": major, "minor": minor};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  String toString() {
    return {"major": major, "minor": minor}.toString();
  }

  @override
  operator ==(other) {
    if (other is! MoneroAccountIndex) return false;
    if (identical(this, other)) return true;
    return major == other.major && minor == other.minor;
  }

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([major, minor]);
}

class OutsEntery extends MoneroSerialization {
  final BigInt index;
  final CtKey key;
  const OutsEntery({required this.index, required this.key});
  factory OutsEntery.fromStruct(Map<String, dynamic> json) {
    return OutsEntery(
        index: json.as("index"), key: CtKey.fromStruct(json.asMap("key")));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "index"),
      CtKey.layout(property: "key")
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"index": index, "key": key.toLayoutStruct()};
  }

  Map<String, dynamic> toJson() {
    return {"index": index, "key": key.toJson()};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutsEntery &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          key == other.key);

  @override
  int get hashCode => HashCodeGenerator.generateHashCode([index, key]);
}

class TxEpemeralKeyResult {
  final TxoutTarget txOut;
  final List<int> amountKey;
  final MoneroPublicKey? additionalTxPubKey;
  TxEpemeralKeyResult(
      {required this.txOut,
      required List<int> amountKey,
      this.additionalTxPubKey})
      : amountKey = amountKey.immutable;
}

class MoneroFeePrority {
  final String name;
  final int index;
  const MoneroFeePrority._({required this.name, required this.index});
  static const MoneroFeePrority defaultPriority =
      MoneroFeePrority._(name: "default", index: 0);
  static const MoneroFeePrority low = MoneroFeePrority._(name: "Low", index: 1);
  static const MoneroFeePrority medium =
      MoneroFeePrority._(name: "Medium", index: 2);
  static const MoneroFeePrority high =
      MoneroFeePrority._(name: "High", index: 3);

  static const List<MoneroFeePrority> values = [
    defaultPriority,
    low,
    medium,
    high
  ];
  BigInt getBaseFee(DaemonGetEstimateFeeResponse baseFee) {
    if (index == 0) return baseFee.fee;
    if (index >= baseFee.fees.length) {
      throw const DartMoneroPluginException(
          "Failed to determine base fee based on your priority.");
    }
    return baseFee.fees[index];
  }

  BigInt calcuateFee(
      {required BigInt weight, required DaemonGetEstimateFeeResponse baseFee}) {
    BigInt fee = getBaseFee(baseFee);
    fee = weight * fee;
    fee = (fee + baseFee.quantizationMask - BigInt.one) ~/
        baseFee.quantizationMask *
        baseFee.quantizationMask;
    return fee;
  }

  @override
  String toString() {
    return "MoneroFeePrority.$name";
  }
}
