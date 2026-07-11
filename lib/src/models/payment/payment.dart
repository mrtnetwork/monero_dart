import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/transaction.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/network/config.dart';
import 'package:monero_dart/src/provider/models/models.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

enum MoneroOutputType {
  locked(value: 0, name: "locked"),
  unlocked(value: 1, name: "unlocked"),
  unlockedMultisig(value: 2, name: "unlockedMultisig");

  static MoneroOutputType fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw ItemNotFoundException(
                name: "MoneroOutputType",
                value: name,
              ),
    );
  }

  final int value;
  final String name;
  const MoneroOutputType({required this.value, required this.name});

  @override
  String toString() {
    return "MoneroOutputType.$name";
  }
}

enum MoneroPaymentType {
  locked(value: 0, name: "locked"),
  unlocked(value: 1, name: "unlocked"),
  unlockedMultisig(value: 2, name: "unlockedMultisig");

  static MoneroPaymentType fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw ItemNotFoundException(
                name: "MoneroPaymentType",
                value: name,
              ),
    );
  }

  final int value;
  final String name;
  const MoneroPaymentType({required this.value, required this.name});
  @override
  String toString() {
    return "MoneroPaymentType.$name";
  }
}

abstract class MoneroOutput extends MoneroVariantSerialization with Equality {
  final BigInt amount;
  final MoneroSubIndex accountIndex;
  final MoneroOutputType type;
  final RctKey mask;
  final RctKey derivation;
  final List<int> outputPublicKey;
  final BigInt unlockTime;
  final int realIndex;
  final bool coinbase;
  MoneroOutput({
    required BigInt amount,
    required this.accountIndex,
    required this.type,
    required RctKey mask,
    required RctKey derivation,
    required List<int> outputPublicKey,
    required BigInt unlockTime,
    required int realIndex,
    required this.coinbase,
  }) : amount = amount.asU64,
       mask = mask.asImmutableBytes.exc(
         length: 32,
         operation: "MoneroOutput",
         reason: "Invalid mask bytes length.",
       ),
       derivation = derivation.asImmutableBytes.exc(
         length: 32,
         operation: "MoneroOutput",
         reason: "Invalid derivation bytes length.",
       ),
       unlockTime = unlockTime.asU64,
       realIndex = realIndex.asU32,
       outputPublicKey = outputPublicKey.exc(
         length: 32,
         operation: "MoneroOutput",
         reason: "Invalid outputPublicKey bytes length.",
       );
  factory MoneroOutput.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroOutput.deserializeJson(decode);
  }

  factory MoneroOutput.deserializeJson(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroOutputType.fromName(decode.variantName);
    switch (type) {
      case MoneroOutputType.locked:
        return MoneroLockedOutput.deserializeJson(decode.value);
      case MoneroOutputType.unlocked:
        return MoneroUnlockedOutput.deserializeJson(decode.value);
      case MoneroOutputType.unlockedMultisig:
        return MoneroUnlockedMultisigOutput.deserializeJson(decode.value);
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
      "realIndex": realIndex,
      "coinbase": coinbase,
    };
  }

  T cast<T extends MoneroOutput>() {
    if (this is! T) {
      throw DartMoneroPluginException(
        "Monero output casting failed.",
        details: {"expected": "$T", "type": type.name},
      );
    }
    return this as T;
  }

  MoneroOutputUnlockTime getUnlockTime() {
    final unlocktime = unlockTime.toIntOrNull;
    if (unlocktime == null) {
      throw DartMoneroPluginException(
        "Invalid output unlock time. value is too large.",
        details: {"value": unlockTime.toString()},
      );
    }
    if (unlocktime == 0) {
      return MoneroOutputUnlockTimeNone();
    }
    if (unlocktime > MoneroNetworkConst.cryptonoteMaxBlockNumber) {
      return MoneroOutputUnlockTimeTimestamp(
        DateTime.fromMillisecondsSinceEpoch(unlocktime * 1000),
      );
    }
    return MoneroOutputUnlockTimeHeight(unlocktime);
  }

  @override
  String toString() {
    return "{amount: ${MoneroTransactionHelper.toXMR(amount)} status: ${type.name} accountIndex: $accountIndex}";
  }
}

class MoneroLockedOutput extends MoneroOutput {
  MoneroLockedOutput({
    required super.amount,
    required super.mask,
    required super.derivation,
    required super.outputPublicKey,
    required super.accountIndex,
    required super.unlockTime,
    required super.realIndex,
    required super.coinbase,
  }) : super(type: MoneroOutputType.locked);
  factory MoneroLockedOutput.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroLockedOutput.deserializeJson(decode);
  }
  factory MoneroLockedOutput.deserializeJson(Map<String, dynamic> json) {
    return MoneroLockedOutput(
      amount: json.valueAs("amount"),
      accountIndex: MoneroSubIndex.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("accountIndex"),
      ),
      mask: json.valueAsBytes("mask"),
      derivation: json.valueAsBytes("derivation"),
      outputPublicKey: json.valueAsBytes("outputPublicKey"),
      unlockTime: json.valueAs("unlockTime"),
      realIndex: json.valueAs("realIndex"),
      coinbase: json.valueAs("coinbase"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      MoneroSubIndex.layout(property: "accountIndex"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
      LayoutConst.boolean(property: "coinbase"),
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
      "realIndex": realIndex,
      "coinbase": coinbase,
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  List<dynamic> get variables => [
    amount,
    accountIndex,
    mask,
    derivation,
    outputPublicKey,
    unlockTime,
    realIndex,
    coinbase,
  ];
}

class MoneroUnlockedOutput extends MoneroOutput {
  final RctKey ephemeralSecretKey;
  final RctKey ephemeralPublicKey;
  final TxKeyImage keyImage;
  String get keyImageAsHex => keyImage.toHex();

  CtKey get toSecretKey => CtKey(dest: ephemeralSecretKey, mask: mask);
  MoneroUnlockedOutput._({
    required super.amount,
    required super.derivation,
    required RctKey ephemeralSecretKey,
    required RctKey ephemeralPublicKey,
    required this.keyImage,
    required super.mask,
    required super.outputPublicKey,
    required super.accountIndex,
    required super.unlockTime,
    required super.realIndex,
    required super.coinbase,
    MoneroOutputType type = MoneroOutputType.unlocked,
  }) : ephemeralPublicKey = ephemeralPublicKey.asImmutableBytes.exc(
         length: 32,
         operation: "MoneroUnlockedOutput",
         reason: "Invalid ephemeralPublicKey bytes length.",
       ),
       ephemeralSecretKey = ephemeralSecretKey.asImmutableBytes.exc(
         length: 32,
         operation: "MoneroUnlockedOutput",
         reason: "Invalid ephemeralSecretKey bytes length.",
       ),

       super(type: MoneroOutputType.unlocked);
  factory MoneroUnlockedOutput({
    required BigInt amount,
    required RctKey derivation,
    required RctKey ephemeralSecretKey,
    required RctKey ephemeralPublicKey,
    required TxKeyImage keyImage,
    required RctKey mask,
    required RctKey outputPublicKey,
    required MoneroSubIndex accountIndex,
    required BigInt unlockTime,
    required int realIndex,
    required bool coinbase,
  }) {
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
      realIndex: realIndex,
      coinbase: coinbase,
    );
  }
  factory MoneroUnlockedOutput.deserialize(
    List<int> bytes, {
    String? property,
  }) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroUnlockedOutput.deserializeJson(decode);
  }
  factory MoneroUnlockedOutput.deserializeJson(Map<String, dynamic> json) {
    return MoneroUnlockedOutput(
      amount: json.valueAs("amount"),
      accountIndex: MoneroSubIndex.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("accountIndex"),
      ),
      derivation: json.valueAsBytes("derivation"),
      mask: json.valueAsBytes("mask"),
      ephemeralPublicKey: json.valueAsBytes("ephemeralPublicKey"),
      ephemeralSecretKey: json.valueAsBytes("ephemeralSecretKey"),
      keyImage: TxKeyImage.deserializeJson(json.valueEnsureAsMap("keyImage")),
      outputPublicKey: json.valueAsBytes("outputPublicKey"),
      unlockTime: json.valueAs("unlockTime"),
      realIndex: json.valueAs("realIndex"),
      coinbase: json.valueAs("coinbase"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      LayoutConst.fixedBlob32(property: "ephemeralSecretKey"),
      LayoutConst.fixedBlob32(property: "ephemeralPublicKey"),
      TxKeyImage.layout(property: "keyImage"),
      MoneroSubIndex.layout(property: "accountIndex"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
      LayoutConst.boolean(property: "coinbase"),
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
      "keyImage": keyImage.toLayoutStruct(),
      "accountIndex": accountIndex.toLayoutStruct(),
      "outputPublicKey": outputPublicKey,
      "unlockTime": unlockTime,
      "realIndex": realIndex,
      "coinbase": coinbase,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      "ephemeralSecretKey": BytesUtils.toHexString(ephemeralSecretKey),
      "ephemeralPublicKey": BytesUtils.toHexString(ephemeralPublicKey),
      "keyImage": keyImageAsHex,
      "realIndex": realIndex,
      "coinbase": coinbase,
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  List<dynamic> get variables => [
    amount,
    accountIndex,
    mask,
    derivation,
    outputPublicKey,
    unlockTime,
    realIndex,
    ephemeralSecretKey,
    ephemeralPublicKey,
    keyImage,
    coinbase,
  ];
}

class MoneroUnlockedMultisigOutput extends MoneroUnlockedOutput {
  final TxKeyImage multisigKeyImage;
  MoneroUnlockedMultisigOutput({
    required super.amount,
    required super.derivation,
    required super.ephemeralSecretKey,
    required super.ephemeralPublicKey,
    required this.multisigKeyImage,
    required super.keyImage,
    required super.mask,
    required super.outputPublicKey,
    required super.accountIndex,
    required super.unlockTime,
    required super.realIndex,
    required super.coinbase,
  }) : super._(type: MoneroOutputType.unlockedMultisig);
  factory MoneroUnlockedMultisigOutput.deserializeJson(
    Map<String, dynamic> json,
  ) {
    return MoneroUnlockedMultisigOutput(
      amount: json.valueAs("amount"),
      accountIndex: MoneroSubIndex.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("accountIndex"),
      ),
      derivation: json.valueAsBytes("derivation"),
      mask: json.valueAsBytes("mask"),
      ephemeralPublicKey: json.valueAsBytes("ephemeralPublicKey"),
      ephemeralSecretKey: json.valueAsBytes("ephemeralSecretKey"),
      keyImage: TxKeyImage.deserializeJson(json.valueEnsureAsMap("keyImage")),
      unlockTime: json.valueAs("unlockTime"),
      outputPublicKey: json.valueAsBytes("outputPublicKey"),
      multisigKeyImage: TxKeyImage.deserializeJson(
        json.valueEnsureAsMap("multisigKeyImage"),
      ),
      realIndex: json.valueAs("realIndex"),
      coinbase: json.valueAs("coinbase"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "amount"),
      LayoutConst.fixedBlob32(property: "mask"),
      LayoutConst.fixedBlob32(property: "derivation"),
      LayoutConst.fixedBlob32(property: "outputPublicKey"),
      LayoutConst.fixedBlob32(property: "ephemeralSecretKey"),
      LayoutConst.fixedBlob32(property: "ephemeralPublicKey"),
      TxKeyImage.layout(property: "keyImage"),
      TxKeyImage.layout(property: "multisigKeyImage"),
      MoneroSubIndex.layout(property: "accountIndex"),
      MoneroLayoutConst.varintBigInt(property: "unlockTime"),
      MoneroLayoutConst.varintInt(property: "realIndex"),
      LayoutConst.boolean(property: "coinbase"),
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
      "keyImage": keyImage.toLayoutStruct(),
      "accountIndex": accountIndex.toLayoutStruct(),
      "outputPublicKey": outputPublicKey,
      "multisigKeyImage": multisigKeyImage.toLayoutStruct(),
      "unlockTime": unlockTime,
      "realIndex": realIndex,
      "coinbase": coinbase,
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  List<dynamic> get variables => [...super.variables, multisigKeyImage];
}

abstract class MoneroPayment<T extends MoneroOutput>
    extends MoneroVariantSerialization
    with Equality {
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
      "globalIndex": globalIndex.toString(),
    };
  }

  MoneroPayment({
    required this.type,
    required this.output,
    required List<int> txPubkey,
    required RctKey? paymentId,
    required RctKey? encryptedPaymentid,
    required this.globalIndex,
  }) : paymentId = paymentId?.asImmutableBytes,
       encryptedPaymentid = encryptedPaymentid?.asImmutableBytes,
       txPubkey = txPubkey.exc(
         length: 32,
         operation: "MoneroPayment",
         reason: "Invalid txPubkey bytes length.",
         name: "txPubkey",
       );
  factory MoneroPayment.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroVariantSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroPayment.deserializeJson(decode);
  }

  factory MoneroPayment.deserializeJson(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroPaymentType.fromName(decode.variantName);
    final MoneroPayment payment;
    switch (type) {
      case MoneroPaymentType.locked:
        payment = MoneroLockedPayment.deserializeJson(decode.value);
        break;
      case MoneroPaymentType.unlocked:
        payment = MoneroUnLockedPayment.deserializeJson(decode.value);
        break;
      case MoneroPaymentType.unlockedMultisig:
        payment = MoneroUnlockedMultisigPayment.deserializeJson(decode.value);
        break;
    }
    if (payment is! MoneroPayment<T>) {
      throw DartMoneroPluginException(
        "Monero payment casting failed.",
        details: {"expected": "$T", "type": type.name},
      );
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
      throw DartMoneroPluginException(
        "Payment casting failed.",
        details: {"expected": "$E", "type": type.name},
      );
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
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroLockedPayment.deserializeJson(decode);
  }
  factory MoneroLockedPayment.deserializeJson(Map<String, dynamic> json) {
    return MoneroLockedPayment(
      output: MoneroLockedOutput.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("output"),
      ),
      txPubkey: json.valueAsBytes("txPubkey"),
      encryptedPaymentid: json.valueAsBytes("encryptedPaymentid"),
      paymentId: json.valueAsBytes("paymentId"),
      globalIndex: json.valueAs("globalIndex"),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLockedOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(
        LayoutConst.fixedBlobN(8),
        property: "encryptedPaymentid",
      ),
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
  List<dynamic> get variables => [
    output,
    txPubkey,
    paymentId,
    encryptedPaymentid,
    globalIndex,
  ];
}

class MoneroUnLockedPayment<T extends MoneroUnlockedOutput>
    extends MoneroPayment<T> {
  TxKeyImage get keyImage => output.keyImage;
  String get keyImageAsHex => keyImage.toHex();
  MoneroUnLockedPayment._({
    required super.output,
    required super.txPubkey,
    super.paymentId,
    super.encryptedPaymentid,
    required super.type,
    required super.globalIndex,
  });
  MoneroUnLockedPayment({
    required super.output,
    required super.txPubkey,
    super.paymentId,
    super.encryptedPaymentid,
    required super.globalIndex,
  }) : super(type: MoneroPaymentType.unlocked);
  factory MoneroUnLockedPayment.deserializeJson(Map<String, dynamic> json) {
    return MoneroUnLockedPayment(
      output:
          MoneroUnlockedOutput.deserializeJson(
            json.valueEnsureAsMap<String, dynamic>("output"),
          ).cast<T>(),
      txPubkey: json.valueAsBytes("txPubkey"),
      encryptedPaymentid: json.valueAsBytes("encryptedPaymentid"),
      paymentId: json.valueAsBytes("paymentId"),
      globalIndex: json.valueAs("globalIndex"),
    );
  }
  factory MoneroUnLockedPayment.deserialize(
    List<int> bytes, {
    String? property,
  }) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroUnLockedPayment.deserializeJson(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroUnlockedOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(
        LayoutConst.fixedBlobN(8),
        property: "encryptedPaymentid",
      ),
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
  List<dynamic> get variables => [
    output,
    txPubkey,
    paymentId,
    encryptedPaymentid,
    globalIndex,
  ];
}

class MoneroUnlockedMultisigPayment
    extends MoneroUnLockedPayment<MoneroUnlockedMultisigOutput> {
  @override
  TxKeyImage get keyImage => output.multisigKeyImage;
  final List<MoneroMultisigOutputInfo> multisigInfos;
  MoneroUnlockedMultisigPayment({
    required super.output,
    required super.txPubkey,
    required super.paymentId,
    required super.encryptedPaymentid,
    required super.globalIndex,
    required List<MoneroMultisigOutputInfo> multisigInfos,
  }) : multisigInfos = multisigInfos.immutable,
       super._(type: MoneroPaymentType.unlockedMultisig);
  factory MoneroUnlockedMultisigPayment.deserializeJson(
    Map<String, dynamic> json,
  ) {
    return MoneroUnlockedMultisigPayment(
      output: MoneroUnlockedMultisigOutput.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("output"),
      ),
      txPubkey: json.valueAsBytes("txPubkey"),
      encryptedPaymentid: json.valueAsBytes("encryptedPaymentid"),
      paymentId: json.valueAsBytes("paymentId"),
      multisigInfos:
          json
              .valueEnsureAsList<Map<String, dynamic>>("multisigInfos")
              .map((e) => MoneroMultisigOutputInfo.deserializeJson(e))
              .toList(),
      globalIndex: json.valueAs("globalIndex"),
    );
  }
  factory MoneroUnlockedMultisigPayment.deserialize(
    List<int> bytes, {
    String? property,
  }) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroUnlockedMultisigPayment.deserializeJson(decode);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroUnlockedMultisigOutput.layout(property: "output"),
      LayoutConst.fixedBlob32(property: "txPubkey"),
      LayoutConst.optional(LayoutConst.fixedBlobN(8), property: "paymentId"),
      LayoutConst.optional(
        LayoutConst.fixedBlobN(8),
        property: "encryptedPaymentid",
      ),
      MoneroLayoutConst.varintBigInt(property: "globalIndex"),
      MoneroLayoutConst.variantVec(
        MoneroMultisigOutputInfo.layout(),
        property: "multisigInfos",
      ),
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
      "globalIndex": globalIndex,
    };
  }

  @override
  List<dynamic> get variables => [
    output,
    txPubkey,
    paymentId,
    encryptedPaymentid,
    globalIndex,
    multisigInfos,
  ];
}

class SpendablePayment<T extends MoneroPayment> extends MoneroSerialization {
  final T payment;
  final List<OutsEntery> outs;
  final int realOutIndex;

  SpendablePayment<E> updatePayment<E extends MoneroPayment>(E updatePayment) {
    return SpendablePayment<E>(
      payment: updatePayment,
      outs: outs,
      realOutIndex: realOutIndex,
    );
  }

  SpendablePayment({
    required this.payment,
    required List<OutsEntery> outs,
    required int realOutIndex,
  }) : outs = outs.immutable,
       realOutIndex = realOutIndex.asU32;
  factory SpendablePayment.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return SpendablePayment.deserializeJson(decode);
  }
  factory SpendablePayment.deserializeJson(Map<String, dynamic> json) {
    return SpendablePayment(
      payment:
          MoneroPayment.deserializeJson(
            json.valueEnsureAsMap<String, dynamic>("payment"),
          ).cast<T>(),
      outs:
          json
              .valueEnsureAsList<Map<String, dynamic>>("outs")
              .map((e) => OutsEntery.deserializeJson(e))
              .toList(),
      realOutIndex: json.valueAs("realOutIndex"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroPayment.layout(property: "payment"),
      MoneroLayoutConst.variantVec(OutsEntery.layout(), property: "outs"),
      MoneroLayoutConst.varintInt(property: "realOutIndex"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "payment": payment.toVariantLayoutStruct(),
      "outs": outs.map((e) => e.toLayoutStruct()).toList(),
      "realOutIndex": realOutIndex,
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
      "payment": payment.toJson(),
    };
  }
}

class UnlockMultisigOutputRequest {
  final List<MoneroMultisigOutputInfo> multisigInfos;
  final MoneroUnLockedPayment payment;
  UnlockMultisigOutputRequest({
    required this.payment,
    required List<MoneroMultisigOutputInfo> multisigInfos,
  }) : multisigInfos = multisigInfos.immutable;
}

class MoneroTransactionWithOutputIndeces {
  final MoneroTransaction transaction;
  final List<BigInt>? outputIndices;
  MoneroTransactionWithOutputIndeces._({
    required this.transaction,
    required List<BigInt>? outputIndices,
  }) : outputIndices = outputIndices?.immutable;
  factory MoneroTransactionWithOutputIndeces.unSafe({
    required MoneroTransaction transaction,
    required List<BigInt>? outputIndices,
  }) {
    if (outputIndices != null &&
        transaction.vout.length != outputIndices.length) {
      throw DartMoneroPluginException(
        "Invalid output indices length: the number of transaction outputs must match the number of output indices.",
        details: {
          "out_indices": outputIndices.join(","),
          "output": transaction.vout.length.toString(),
        },
      );
    }
    return MoneroTransactionWithOutputIndeces._(
      transaction: transaction,
      outputIndices: outputIndices,
    );
  }
  factory MoneroTransactionWithOutputIndeces({
    required MoneroTransaction transaction,
    required List<BigInt>? outputIndices,
  }) {
    if (outputIndices == null ||
        transaction.vout.length != outputIndices.length) {
      throw DartMoneroPluginException(
        "Invalid output indices length: the number of transaction outputs must match the number of output indices.",
        details: {
          "out_indices": outputIndices?.join(","),
          "output": transaction.vout.length.toString(),
        },
      );
    }
    return MoneroTransactionWithOutputIndeces._(
      transaction: transaction,
      outputIndices: outputIndices,
    );
  }

  bool get hasIndices => outputIndices != null;
}

class MoneroTxDestination extends MoneroSerialization {
  final BigInt amount;
  final MoneroAddress address;
  String get amountAsXMR => MoneroTransactionHelper.toXMR(amount);
  MoneroTxDestination({required BigInt amount, required this.address})
    : amount = amount.asU64;
  factory MoneroTxDestination.fromXMR({
    required MoneroAddress address,
    required String amount,
  }) {
    final piconero = MoneroTransactionHelper.toPiconero(amount);
    return MoneroTxDestination(amount: piconero, address: address);
  }
  factory MoneroTxDestination.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroTxDestination.deserializeJson(decode);
  }
  factory MoneroTxDestination.deserializeJson(Map<String, dynamic> json) {
    return MoneroTxDestination(
      amount: json.valueAs("amount"),
      address: MoneroAddress.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("address"),
      ),
    );
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
      "address": address.toString(),
    }.toString();
  }
}

class MoneroSubIndex extends MoneroSerialization
    with Equality, CborTagSerializable {
  final int major;
  final int minor;
  const MoneroSubIndex.unsafe({this.major = 0, this.minor = 0});
  factory MoneroSubIndex.deserializeCbor({List<int>? bytes, CborObject? obj}) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: MoneroSerializationIdentifiers.subIndex,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroSubIndex(
      major: values.rawValueAt(0),
      minor: values.rawValueAt(1),
    );
  }
  factory MoneroSubIndex({int major = 0, int minor = 0}) {
    if (minor < 0 || minor > MoneroSubaddressConst.subaddrMaxIdx) {
      throw ArgumentException.invalidOperationArguments(
        "MoneroSubIndex",
        name: "minor",
        reason: "Invalid minor index.",
      );
    }
    if (major < 0 || major > MoneroSubaddressConst.subaddrMaxIdx) {
      throw ArgumentException.invalidOperationArguments(
        "MoneroSubIndex",
        name: "major",
        reason: "Invalid major index.",
      );
    }
    return MoneroSubIndex.unsafe(major: major, minor: minor);
  }
  factory MoneroSubIndex.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroSubIndex.deserializeJson(decode);
  }
  static const MoneroSubIndex primary = MoneroSubIndex.unsafe();
  static const MoneroSubIndex minor1 = MoneroSubIndex.unsafe(minor: 1);
  bool get isSubaddress {
    return major != 0 || minor != 0;
  }

  factory MoneroSubIndex.deserializeJson(Map<String, dynamic> json) {
    return MoneroSubIndex(
      major: json.valueAs("major"),
      minor: json.valueAs("minor"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.u32(property: "major"),
      LayoutConst.u32(property: "minor"),
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

  MoneroSubIndex? tryIncrement() {
    const max = MoneroSubaddressConst.subaddrMaxIdx;

    return minor < max
        ? MoneroSubIndex(major: major, minor: minor + 1)
        : major < max
        ? MoneroSubIndex(major: major + 1, minor: 0)
        : null;
  }

  @override
  List<dynamic> get variables => [major, minor];

  @override
  SerializationIdentifier get serializationIdentifier =>
      MoneroSerializationIdentifiers.subIndex;

  @override
  List<CborObject?> get serializationItems => [major.toCbor(), minor.toCbor()];
}

class OutsEntery extends MoneroSerialization with Equality {
  final BigInt index;
  final CtKey key;
  const OutsEntery({required this.index, required this.key});
  factory OutsEntery.deserializeJson(Map<String, dynamic> json) {
    return OutsEntery(
      index: json.valueAs("index"),
      key: CtKey.deserializeJson(json.valueEnsureAsMap<String, dynamic>("key")),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintBigInt(property: "index"),
      CtKey.layout(property: "key"),
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
  List<dynamic> get variables => [index, key];
}

class TxEpemeralKeyResult {
  final TxoutTarget txOut;
  final List<int> amountKey;
  final MoneroPublicKey? additionalTxPubKey;
  TxEpemeralKeyResult({
    required this.txOut,
    required List<int> amountKey,
    this.additionalTxPubKey,
  }) : amountKey = amountKey.immutable;
}

/// Dont change order.
enum MoneroFeePrority {
  defaultPriority(name: "default"),
  low(name: "Low"),
  medium(name: "Medium"),
  high(name: "High");

  final String name;

  const MoneroFeePrority({required this.name});
  BigInt getBaseFee(DaemonGetEstimateFeeResponse baseFee) {
    if (index == 0) return baseFee.fee;
    final fees = baseFee.fees;
    if (fees == null || index >= fees.length) {
      throw const DartMoneroPluginException(
        "Failed to determine base fee based on your priority.",
      );
    }
    return fees[index];
  }

  static List<MoneroFeePrority> getFeeProrities(
    DaemonGetEstimateFeeResponse baseFee,
  ) {
    final int length = baseFee.fees?.length ?? 0;
    if (length == 0) {
      return [MoneroFeePrority.defaultPriority];
    }
    return MoneroFeePrority.values.sublist(
      0,
      IntUtils.min(MoneroFeePrority.values.length, length + 1),
    );
  }

  BigInt calcuateFee({
    required BigInt weight,
    required DaemonGetEstimateFeeResponse baseFee,
  }) {
    BigInt fee = getBaseFee(baseFee);
    fee = weight * fee;
    fee =
        (fee + baseFee.quantizationMask - BigInt.one) ~/
        baseFee.quantizationMask *
        baseFee.quantizationMask;
    return fee;
  }

  @override
  String toString() {
    return "MoneroFeePrority.$name";
  }
}

sealed class MoneroOutputUnlockTime {
  const MoneroOutputUnlockTime();
}

class MoneroOutputUnlockTimeNone extends MoneroOutputUnlockTime {
  const MoneroOutputUnlockTimeNone();
  @override
  String toString() {
    return "MoneroOutputUnlockTimeNone";
  }
}

class MoneroOutputUnlockTimeHeight extends MoneroOutputUnlockTime {
  final int height;
  const MoneroOutputUnlockTimeHeight(this.height);
  @override
  String toString() {
    return "MoneroOutputUnlockTimeHeight($height)";
  }
}

class MoneroOutputUnlockTimeTimestamp extends MoneroOutputUnlockTime {
  final DateTime unlockTimeUtc;
  const MoneroOutputUnlockTimeTimestamp(this.unlockTimeUtc);
  @override
  String toString() {
    return "MoneroOutputUnlockTimeTimestamp($unlockTimeUtc)";
  }
}
