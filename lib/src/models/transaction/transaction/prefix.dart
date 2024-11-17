import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/transaction.dart';
import 'package:monero_dart/src/models/transaction/transaction/input.dart';
import 'package:monero_dart/src/models/transaction/transaction/output.dart';
import 'package:monero_dart/src/models/transaction/transaction/extra.dart';
import 'package:monero_dart/src/network/config.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroTransactionPrefix extends MoneroSerialization {
  final int version;
  final BigInt unlockTime;
  final List<MoneroTxin> vin;
  final List<MoneroTxout> vout;
  final List<int> extra;
  MoneroTransactionPrefix(
      {int version = MoneroConst.currentVersion,
      BigInt? unlockTime,
      required List<MoneroTxin> vin,
      required List<MoneroTxout> vout,
      required List<int> extra})
      : version = version.asUint32,
        unlockTime = unlockTime?.asUint64 ?? MoneroConst.unlockTime,
        vin = vin.immutable,
        vout = vout.immutable,
        extra = extra.asImmutableBytes;

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyStruct([
      LazyLayout(layout: MoneroLayoutConst.varintInt, property: "version"),
      LazyLayout(
          layout: MoneroLayoutConst.varintBigInt, property: "unlock_time"),
      LazyLayout(
          layout: ({property}) => MoneroLayoutConst.variantVec(
              MoneroTxin.layout(),
              property: property),
          property: "vin"),
      LazyLayout(
          layout: ({property}) => MoneroLayoutConst.variantVec(
              MoneroTxout.layout(),
              property: property),
          property: "vout"),
      LazyLayout(layout: MoneroLayoutConst.variantBytes, property: "extera"),
    ], property: property);
  }

  List<TxExtra> toTxExtra() {
    return MoneroTransactionHelper.extraParsing(extra);
  }

  MoneroPublicKey getTxExtraPubKey() {
    final extras = toTxExtra();
    final pubKeyExtra = extras
        .firstWhere((e) => e.type == TxExtraTypes.publicKey,
            orElse: () => throw const DartMoneroPluginException(
                "Cannot find tx public key extra."))
        .cast<TxExtraPublicKey>();
    return pubKeyExtra.publicKey;
  }

  TxExtraAdditionalPubKeys? getTxAdditionalPubKeys() {
    final extras = toTxExtra();
    try {
      return extras
          .firstWhere((e) => e.type == TxExtraTypes.additionalPubKeys)
          .cast();
    } on StateError {
      return null;
    }
  }

  List<TxExtraNonce> getTxExtraNonces() {
    final extras = toTxExtra();
    return extras.whereType<TxExtraNonce>().toList();
  }

  RctKey? getTxEncryptedPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      if (i.hasEncryptedPaymentId != null) {
        return i.hasEncryptedPaymentId;
      }
    }
    return null;
  }

  RctKey? getTxPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      if (i.hasPaymentId != null) {
        return i.hasPaymentId;
      }
    }
    return null;
  }

  List<int> getTranactionPrefixHash() {
    final serialize = layout().serialize(toLayoutStruct());
    return QuickCrypto.keccack256Hash(serialize);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "version": version,
      "unlock_time": unlockTime,
      "vin": vin.map((e) => e.toVariantLayoutStruct()).toList(),
      "vout": vout.map((e) => e.toLayoutStruct()).toList(),
      "extera": extra
    };
  }
}
