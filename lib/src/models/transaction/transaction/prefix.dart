import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
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

  MoneroTransactionPrefix({
    int version = MoneroNetworkConst.currentVersion,
    BigInt? unlockTime,
    required List<MoneroTxin> vin,
    required List<MoneroTxout> vout,
    required List<int> extra,
  }) : version = version.asU32,
       unlockTime = unlockTime?.asU64 ?? MoneroNetworkConst.unlockTime,
       vin = vin.immutable,
       vout = vout.immutable,
       extra = extra.asImmutableBytes;
  factory MoneroTransactionPrefix.deserialize(
    List<int> bytes, {
    bool forcePrunable = false,
    String? property,
  }) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroTransactionPrefix.deserializeJson(decode);
  }
  factory MoneroTransactionPrefix.deserializeJson(Map<String, dynamic> json) {
    final int version = json.valueAs("version");
    return MoneroTransactionPrefix(
      version: version,
      unlockTime: json.valueAs("unlock_time"),
      vin:
          json
              .valueEnsureAsList<Map<String, dynamic>>("vin")
              .map((e) => MoneroTxin.deserializeJson(e))
              .toList(),
      vout:
          json
              .valueEnsureAsList<Map<String, dynamic>>("vout")
              .map((e) => MoneroTxout.deserializeJson(e))
              .toList(),
      extra: json.valueAsBytes("extera"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyStruct([
      LazyStructLayoutBuilder(
        layout:
            (property, params) =>
                MoneroLayoutConst.varintInt(property: property),
        property: "version",
      ),
      LazyStructLayoutBuilder(
        layout:
            (property, params) =>
                MoneroLayoutConst.varintBigInt(property: property),
        property: "unlock_time",
      ),
      LazyStructLayoutBuilder(
        layout:
            (property, params) => MoneroLayoutConst.variantVec(
              MoneroTxin.layout(),
              property: property,
            ),
        property: "vin",
      ),
      LazyStructLayoutBuilder(
        layout:
            (property, params) => MoneroLayoutConst.variantVec(
              MoneroTxout.layout(),
              property: property,
            ),
        property: "vout",
      ),
      LazyStructLayoutBuilder(
        layout:
            (property, params) =>
                MoneroLayoutConst.variantBytes(property: property),
        property: "extera",
      ),
    ], property: property);
  }

  List<TxExtra> _toTxExtra() {
    return MoneroTransactionHelper.extraParsing(extra);
  }

  MoneroPublicKey? _getTxExtraPubKey() {
    final pubKeyExtra =
        txExtras
            .firstWhereNullable((e) => e.type == TxExtraTypes.publicKey)
            ?.cast<TxExtraPublicKey>();
    if (pubKeyExtra == null) {
      return null;
    }
    return MoneroPublicKey.fromBytes(pubKeyExtra.publicKey);
  }

  TxExtraAdditionalPubKeys? _getTxAdditionalPubKeys() {
    try {
      return txExtras
          .firstWhere((e) => e.type == TxExtraTypes.additionalPubKeys)
          .cast();
    } on StateError {
      return null;
    }
  }

  RctKey? _getTxEncryptedPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      final encPaymentId = i.tryExtractEncryptedPaymetId();
      if (encPaymentId != null) {
        return encPaymentId;
      }
    }
    return null;
  }

  RctKey? _getTxPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      final paymentId = i.tryExtractPaymentId();
      if (paymentId != null) {
        return paymentId;
      }
    }
    return null;
  }

  late final RctKey? txPaymentId = _getTxPaymentId()?.asImmutableBytes;
  late final List<TxExtra> txExtras = _toTxExtra();
  late final MoneroPublicKey? txPublicKey = _getTxExtraPubKey();
  late final TxExtraAdditionalPubKeys? additionalPubKeys =
      _getTxAdditionalPubKeys();
  late final RctKey? txEncryptedPaymentId =
      _getTxEncryptedPaymentId()?.asImmutableBytes;
  bool isCoinbase() {
    return vin.length == 1 && vin[0].type.isCoinBase;
  }

  List<int>? txPubkeyBytes() {
    final pubKeyExtra =
        txExtras
            .firstWhereNullable((e) => e.type == TxExtraTypes.publicKey)
            ?.cast<TxExtraPublicKey>();
    assert(pubKeyExtra != null || isCoinbase());
    if (pubKeyExtra == null) return null;

    return pubKeyExtra.publicKey;
  }

  List<TxExtraNonce> getTxExtraNonces() {
    return txExtras.whereType<TxExtraNonce>().toList();
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
      "extera": extra,
    };
  }
}
