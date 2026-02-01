import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
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
    return MoneroTransactionPrefix.fromStruct(decode);
  }
  factory MoneroTransactionPrefix.fromStruct(Map<String, dynamic> json) {
    // final Map<String, dynamic> signatureJson = json.asMap("signature");
    final int version = json.as("version");

    // final MoneroTxSignatures sig;
    // if (version == 1 && signatureJson.isEmpty) {
    //   sig = const MoneroV1Signature(null);
    // } else {
    //   sig = MoneroTxSignatures.fromStruct(json.asMap("signature"));
    // }

    return MoneroTransactionPrefix(
      version: version,
      unlockTime: json.as("unlock_time"),
      vin:
          json
              .asListOfMap("vin")!
              .map((e) => MoneroTxin.fromStruct(e))
              .toList(),
      vout:
          json
              .asListOfMap("vout")!
              .map((e) => MoneroTxout.fromStruct(e))
              .toList(),
      extra: json.asBytes("extera"),
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

  late final List<TxExtra> txExtras = _toTxExtra();
  MoneroPublicKey _getTxExtraPubKey() {
    final pubKeyExtra =
        txExtras
            .firstWhere(
              (e) => e.type == TxExtraTypes.publicKey,
              orElse:
                  () =>
                      throw const DartMoneroPluginException(
                        "Cannot find tx public key extra.",
                      ),
            )
            .cast<TxExtraPublicKey>();
    return MoneroPublicKey.fromBytes(pubKeyExtra.publicKey);
  }

  late final MoneroPublicKey txPublicKey = _getTxExtraPubKey();

  List<int> txPubkeyBytes() {
    final pubKeyExtra =
        txExtras
            .firstWhere(
              (e) => e.type == TxExtraTypes.publicKey,
              orElse:
                  () =>
                      throw const DartMoneroPluginException(
                        "Cannot find tx public key extra.",
                      ),
            )
            .cast<TxExtraPublicKey>();
    return pubKeyExtra.publicKey;
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

  late TxExtraAdditionalPubKeys? additionalPubKeys = _getTxAdditionalPubKeys();

  List<TxExtraNonce> getTxExtraNonces() {
    return txExtras.whereType<TxExtraNonce>().toList();
  }

  RctKey? _getTxEncryptedPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      if (i.hasEncryptedPaymentId != null) {
        return i.hasEncryptedPaymentId;
      }
    }
    return null;
  }

  late final RctKey? txEncryptedPaymentId =
      _getTxEncryptedPaymentId()?.asImmutableBytes;

  RctKey? _getTxPaymentId() {
    final nonces = getTxExtraNonces();
    for (final i in nonces) {
      if (i.hasPaymentId != null) {
        return i.hasPaymentId;
      }
    }
    return null;
  }

  late final RctKey? txPaymentId = _getTxPaymentId()?.asImmutableBytes;

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
