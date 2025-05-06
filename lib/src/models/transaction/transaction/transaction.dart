import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:monero_dart/src/models/transaction/transaction/input.dart';
import 'package:monero_dart/src/models/transaction/transaction/output.dart';
import 'package:monero_dart/src/models/transaction/transaction/prefix.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroTransaction extends MoneroTransactionPrefix {
  final MoneroTxSignatures signature;
  MoneroTransaction({
    super.version,
    BigInt? unlockTime,
    required super.vin,
    required super.vout,
    required super.extra,
    required this.signature,
  }) : super(unlockTime: unlockTime ?? BigInt.zero);
  factory MoneroTransaction.deserialize(List<int> bytes,
      {bool forcePrunable = false, String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes,
        layout: layout(property: property, forcePrunable: forcePrunable));
    return MoneroTransaction.fromStruct(decode);
  }
  factory MoneroTransaction.fromStruct(Map<String, dynamic> json) {
    final Map<String, dynamic> signatureJson = json.asMap("signature");
    final int version = json.as("version");

    final MoneroTxSignatures sig;
    if (version == 1 && signatureJson.isEmpty) {
      sig = const MoneroV1Signature(null);
    } else {
      sig = MoneroTxSignatures.fromStruct(json.asMap("signature"));
    }

    return MoneroTransaction(
        version: version,
        unlockTime: json.as("unlock_time"),
        vin: json
            .asListOfMap("vin")!
            .map((e) => MoneroTxin.fromStruct(e))
            .toList(),
        vout: json
            .asListOfMap("vout")!
            .map((e) => MoneroTxout.fromStruct(e))
            .toList(),
        extra: json.asBytes("extera"),
        signature: sig);
  }
  static Layout<Map<String, dynamic>> layout({
    String? property,
    required bool forcePrunable,
    MoneroTransaction? transaction,
  }) {
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
      ConditionalLazyLayout<Map<String, dynamic>>(
          layout: (
              {required action,
              property,
              required sourceOrResult,
              required remindBytes}) {
            if (transaction != null) {
              if (transaction.version == 1) {
                if (transaction.signature.cast<MoneroV1Signature>().signature ==
                    null) {
                  return LayoutConst.noArgs();
                }
                final List<int> signatureLength =
                    List.filled(transaction.vin.length, 0);
                for (int i = 0; i < transaction.vin.length; i++) {
                  final input = transaction.vin[i];

                  if (input.type == MoneroTxinType.txinToKey) {
                    signatureLength[i] =
                        input.cast<TxinToKey>().keyOffsets.length;
                  }
                }
                return MoneroV1Signature.layout(
                    inputLength: transaction.vin.length,
                    signatureLength: signatureLength);
              }
              return RCTSignature.layout(
                  outputLength: transaction.vout.length,
                  inputLength: transaction.vin.length,
                  transaction: transaction,
                  mixinLength: null,
                  forcePrunable: forcePrunable);
            }
            final outputLength =
                (sourceOrResult?["vout"] as List?)?.length ?? 0;
            final inputLength = (sourceOrResult?["vin"] as List?)?.length ?? 0;
            final version = sourceOrResult?["version"];
            final List<int> signatureLength = List.filled(inputLength, 0);
            if (version == 1) {
              if (remindBytes == 0) {
                return LayoutConst.noArgs();
              }
              for (int i = 0; i < inputLength; i++) {
                final Map<String, dynamic> vin0 =
                    (sourceOrResult!["vin"] as List)[0];
                if (vin0["key"] == MoneroTxinType.txinToKey.name) {
                  signatureLength[i] =
                      (vin0["value"]["key_offsets"] as List).length;
                }
              }
              return MoneroV1Signature.layout(
                  property: property,
                  inputLength: inputLength,
                  signatureLength: signatureLength);
            }
            int mixinLength = 0;
            if (inputLength > 0) {
              final Map<String, dynamic> vin0 =
                  (sourceOrResult!["vin"] as List)[0];
              if (vin0["key"] == MoneroTxinType.txinToKey.name) {
                mixinLength = (vin0["value"]["key_offsets"] as List).length;
              }
            }
            return RCTSignature.layout(
                outputLength: outputLength,
                inputLength: inputLength,
                transaction: transaction,
                mixinLength: mixinLength,
                forcePrunable: forcePrunable);
          },
          property: "signature"),
    ], property: property);
  }

  MoneroTransaction copyWith({
    int? version,
    BigInt? unlockTime,
    List<MoneroTxin>? vin,
    List<MoneroTxout>? vout,
    List<int>? extra,
    MoneroTxSignatures? signature,
  }) {
    return MoneroTransaction(
        vin: vin ?? this.vin,
        vout: vout ?? this.vout,
        extra: extra ?? this.extra,
        signature: signature ?? this.signature,
        version: version ?? this.version,
        unlockTime: unlockTime ?? this.unlockTime);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, transaction: this, forcePrunable: false);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "version": version,
      "unlock_time": unlockTime,
      "vin": vin.map((e) => e.toVariantLayoutStruct()).toList(),
      "vout": vout.map((e) => e.toLayoutStruct()).toList(),
      "extera": extra,
      "signature": signature.toLayoutStruct(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      "version": version,
      "unlock_time": unlockTime.toString(),
      "vin": vin.map((e) => e.toJson()).toList(),
      "vout": vout.map((e) => e.toJson()).toList(),
      "extera": BytesUtils.toHexString(extra),
    };
  }

  String getTxHash() {
    List<int> hash;
    if (version == 1) {
      hash = QuickCrypto.keccack256Hash(serialize());
    } else {
      final prefix = getTranactionPrefixHash();
      final sig = signature.cast<RCTSignature>();
      if (sig.rctSigPrunable == null) {
        throw const DartMoneroPluginException(
            "signature prunable required for determinate tx hash.");
      }
      final bsaeBytes = RCTSignatureBase.layout(
        inputLength: vin.length,
        outputLength: vout.length,
      ).serialize(sig.signature.toVariantLayoutStruct());
      final baseSigHash = QuickCrypto.keccack256Hash(bsaeBytes);
      List<int> lastPart;
      if (sig.signature.type == RCTType.rctTypeNull) {
        lastPart = RCT.zero(clone: false);
      } else {
        int mixinLength = 0;
        if (vin.isNotEmpty && vin[0].type == MoneroTxinType.txinToKey) {
          final inp = vin[0].cast<TxinToKey>();
          mixinLength = inp.keyOffsets.length;
        }
        lastPart = RctSigPrunable.layout(
                inputLength: vin.length,
                outputLength: vout.length,
                type: sig.type,
                mixinLength: mixinLength)
            .serialize(sig.rctSigPrunable!.toLayoutStruct());
        lastPart = QuickCrypto.keccack256Hash(lastPart);
      }
      hash =
          QuickCrypto.keccack256Hash([...prefix, ...baseSigHash, ...lastPart]);
    }

    return BytesUtils.toHexString(hash);
  }

  List<String> getInputsKeyImages() {
    return vin
        .map((e) => e.getKeyImage())
        .where((e) => e != null)
        .cast<String>()
        .toList();
  }

  List<List<int>> getPublicKeys() {
    return [
      txPubkeyBytes(),
      if (additionalPubKeys != null) ...additionalPubKeys!.pubKeys
    ];
  }
}
