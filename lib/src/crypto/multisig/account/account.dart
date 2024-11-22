import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/const/const.dart';
import 'package:monero_dart/src/crypto/multisig/utils/utils.dart';
import 'package:monero_dart/src/crypto/multisig/core/account.dart';
import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/multisig/utils/multi_sig_kex_utils.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/network/network.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroMultisigAccount extends MoneroMultisigAccountCore {
  MoneroMultisigAccount._(
      {required super.threshold,
      required super.signers,
      required super.basePrivateKey,
      required super.basePublicKey,
      required super.baseCommonPrivateKey,
      required super.multisigPrivateKeys,
      required super.commonPrivateKey,
      required super.multisigPubKey,
      required super.commonPubKey,
      required super.kexRoundsComplete,
      required super.nextRoundKexMessage,
      super.kexKeysToOriginsMap = const {}});

  factory MoneroMultisigAccount(
      {required int threshold,
      required List<MoneroPublicKey> signers,
      required MoneroPrivateKey basePrivateKey,
      required MoneroPrivateKey baseCommonPrivateKey,
      required List<MoneroPrivateKey> multisigPrivateKeys,
      required MoneroPrivateKey commonPrivateKey,
      required MoneroPublicKey multisigPubKey,
      required MoneroPublicKey commonPubKey,
      required int kexRoundsComplete,
      required MultisigKexMessageSerializable nextRoundKexMessage,
      Map<MoneroPublicKey, Set<MoneroPublicKey>> kexKeysToOriginsMap =
          const {}}) {
    if (kexRoundsComplete <= 0) {
      throw const MoneroCryptoException(
          "multisig account: can't reconstruct account if its kex wasn't initialized.");
    }
    final basePubKey = basePrivateKey.publicKey;
    final cloneSigners = MoneroMultisigKexUtils.validateConfig(
        threshold: threshold, signers: signers, basePublicKey: basePubKey);
    final roundRequired = MoneroMultisigKexUtils.multisigKexRoundsRequired(
        cloneSigners.length, threshold);
    final mainKexDone = kexRoundsComplete >=
        MoneroMultisigKexUtils.multisigKexRoundsRequired(
            cloneSigners.length, threshold);
    if (kexRoundsComplete > roundRequired + 1) {
      throw const MoneroCryptoException(
          "multisig account: tried to reconstruct account, but kex rounds complete counter is invalid.");
    }
    if (mainKexDone) {
      // nextRoundKexMessage = MultisigKexMessage.generate(
      //     round: roundRequired + 1,
      //     signingPrivateKey: basePrivateKey,
      //     msgPubKeys: [multisigPubKey, commonPubKey]).message;
    }

    return MoneroMultisigAccount._(
        threshold: threshold,
        signers: cloneSigners,
        basePrivateKey: basePrivateKey,
        basePublicKey: basePubKey,
        baseCommonPrivateKey: baseCommonPrivateKey,
        multisigPrivateKeys: multisigPrivateKeys,
        commonPrivateKey: commonPrivateKey,
        multisigPubKey: multisigPubKey,
        commonPubKey: commonPubKey,
        kexRoundsComplete: kexRoundsComplete,
        nextRoundKexMessage: nextRoundKexMessage,
        kexKeysToOriginsMap: kexKeysToOriginsMap);
  }

  factory MoneroMultisigAccount.initialize({
    required MoneroPrivateKey privateSpendKey,
    required MoneroPrivateKey privateViewKey,
  }) {
    final basePrivateKey =
        MoneroMultisigKexUtils.getMultisigBlindedSecretKey(privateSpendKey.key);
    final baseCommonPrivateKey =
        MoneroMultisigKexUtils.getMultisigBlindedSecretKey(privateViewKey.key);
    return MoneroMultisigAccount._(
        threshold: 0,
        signers: [],
        basePrivateKey: basePrivateKey,

        ///
        basePublicKey: basePrivateKey.publicKey,
        baseCommonPrivateKey: baseCommonPrivateKey,
        multisigPrivateKeys: [],

        ///
        commonPrivateKey: MoneroPrivateKey.fromBytes(RCT.zero(clone: false)),
        multisigPubKey: MoneroPublicKey.fromBytes(RCT.identity(clone: false)),
        commonPubKey: MoneroPublicKey.fromBytes(RCT.identity(clone: false)),
        kexRoundsComplete: 0,
        nextRoundKexMessage: MultisigKexMessage.generate(
                round: 1,
                signingPrivateKey: basePrivateKey,
                msgPubKeys: [],
                msgPrivateKey: baseCommonPrivateKey)
            .message);
  }

  factory MoneroMultisigAccount.deserialize(List<int> bytes,
      {String? propery}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes,
        layout: MoneroMultisigAccountCore.layout(property: propery));
    return MoneroMultisigAccount.fromStruct(decode);
  }
  factory MoneroMultisigAccount.fromStruct(Map<String, dynamic> json) {
    return MoneroMultisigAccount(
        threshold: json.as("threshold"),
        signers: json
            .asListBytes("signers")!
            .map((e) => MoneroPublicKey.fromBytes(e))
            .toList(),
        basePrivateKey:
            MoneroPrivateKey.fromBytes(json.asBytes("base_private_key")),
        baseCommonPrivateKey:
            MoneroPrivateKey.fromBytes(json.asBytes("base_common_private_key")),
        multisigPrivateKeys: json
            .asListBytes("multisig_private_keys")!
            .map((e) => MoneroPrivateKey.fromBytes(e))
            .toList(),
        commonPrivateKey:
            MoneroPrivateKey.fromBytes(json.asBytes("common_private_key")),
        multisigPubKey:
            MoneroPublicKey.fromBytes(json.asBytes("multisig_pub_key")),
        commonPubKey: MoneroPublicKey.fromBytes(json.asBytes("common_pub_key")),
        kexRoundsComplete: json.as("kex_rounds_complete"),
        nextRoundKexMessage: MultisigKexMessageSerializable.fromBase58(
            json.as("kex_round_message")),
        kexKeysToOriginsMap: json.as<Map>("kex_keys").map((k, v) {
          return MapEntry(
              MoneroPublicKey.fromBytes(List<int>.from(k)),
              (v as List)
                  .map((e) => MoneroPublicKey.fromBytes((e as List).cast()))
                  .toSet());
        }));
  }

  /// get address
  MoneroAddress toAddress({MoneroNetwork network = MoneroNetwork.mainnet}) {
    if (!multisigIsReady) {
      throw const MoneroCryptoException(
          "Unable to determine the address until the final round is completed.");
    }
    return MoneroAccountAddress.fromPubKeys(
        pubSpendKey: multisigPubKey.key,
        pubViewKey: commonPrivateKey.publicKey.key,
        network: network);
  }

  /// create monero account from multisig account
  MoneroAccount toAccount({MoneroNetwork network = MoneroNetwork.mainnet}) {
    if (!multisigIsReady) {
      throw const MoneroCryptoException(
          "Unable to determine account until the final round is completed.");
    }
    return MoneroAccount.multisig(
        privSkey: basePrivateKey,
        privVkey: commonPrivateKey,
        pubSkey: multisigPubKey,
        coinType: network.coin);
  }

  /// generate multisig info for  each output
  MoneroMultisigInfo generateMultisigInfo(MoneroUnlockedOutput out) {
    final List<RctKey> keyImages = [];
    for (final i in multisigPrivateKeys) {
      final partialKeyImage = MoneroMultisigUtils.generateMultisigKeyImage(
          outputPubKey: out.outputPublicKey, multisigKey: i);
      keyImages.add(partialKeyImage);
    }

    int nlr = MoneroMultisigUtils.combinationsCount(
        signers.length - threshold, signers.length - 1);
    nlr = nlr * MoneroMultisigConst.kAlphaComponents;
    final List<MultisigLR> lr = [];
    final List<MoneroPrivateKey> nonces = [];
    for (int i = 0; i < nlr; i++) {
      final sK = MoneroPrivateKey.fromBytes(RCT.skGen_());
      nonces.add(sK);
      final r = MoneroMultisigUtils.getMultisigKLRki(
          outPybKey: out.outputPublicKey,
          secretKey: sK,
          keyImage: out.keyImage);
      lr.add(MultisigLR(l: r.L, r: r.R));
    }
    final info = MoneroMultisigOutputInfo(
        signer: basePublicKey, lr: lr, partialKeyImages: keyImages);
    return MoneroMultisigInfo(info: info, nonces: nonces);
  }
}
