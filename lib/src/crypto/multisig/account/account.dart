import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/multisig/const/const.dart';
import 'package:monero_dart/src/crypto/multisig/utils/utils.dart';
import 'package:monero_dart/src/crypto/multisig/core/account.dart';
import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/multisig/utils/multi_sig_kex_utils.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/network/network.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroMultisigAccount extends MoneroMultisigAccountCore {
  MoneroMultisigAccount._({
    required super.threshold,
    required super.signers,
    required super.basePrivateKey,
    required super.basePublicKey,
    required super.baseCommonPrivateKey,
    required super.multisigPrivateKeys,
    required super.commonPrivateKey,
    super.multisigPubKey,
    super.commonPubKey,
    required super.kexRoundsComplete,
    required super.nextRoundKexMessage,
    super.kexKeysToOriginsMap = const {},
  });

  factory MoneroMultisigAccount({
    required int threshold,
    required List<ED25519MoneroPublicKey> signers,
    required ED25519MoneroPrivateKey basePrivateKey,
    required ED25519MoneroPrivateKey baseCommonPrivateKey,
    required List<ED25519MoneroPrivateKey> multisigPrivateKeys,
    required ED25519MoneroPrivateKey commonPrivateKey,
    required ED25519MoneroPublicKey multisigPubKey,
    required ED25519MoneroPublicKey commonPubKey,
    required int kexRoundsComplete,
    required MultisigKexMessageSerializable nextRoundKexMessage,
    Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
        kexKeysToOriginsMap =
        const {},
  }) {
    if (kexRoundsComplete <= 0) {
      throw BuError(
        DefaultErrorType.invalidState,
        "multisig account: can't reconstruct account if its kex wasn't initialized.",
      );
    }
    final basePubKey = basePrivateKey.publicKey;
    final cloneSigners = MoneroMultisigKexUtils.validateConfig(
      threshold: threshold,
      signers: signers,
      basePublicKey: basePubKey,
    );
    final roundRequired = MoneroMultisigKexUtils.multisigKexRoundsRequired(
      cloneSigners.length,
      threshold,
    );
    final mainKexDone =
        kexRoundsComplete >=
        MoneroMultisigKexUtils.multisigKexRoundsRequired(
          cloneSigners.length,
          threshold,
        );
    if (kexRoundsComplete > roundRequired + 1) {
      throw BuError(
        DefaultErrorType.invalidState,
        "multisig account: tried to reconstruct account, but kex rounds complete counter is invalid.",
      );
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
      kexKeysToOriginsMap: kexKeysToOriginsMap,
    );
  }

  factory MoneroMultisigAccount.initialize({
    required ED25519MoneroPrivateKey privateSpendKey,
    required ED25519MoneroPrivateKey privateViewKey,
  }) {
    final basePrivateKey = MoneroMultisigKexUtils.getMultisigBlindedSecretKey(
      privateSpendKey.takeSecretKey(),
    );
    final baseCommonPrivateKey =
        MoneroMultisigKexUtils.getMultisigBlindedSecretKey(
          privateViewKey.takeSecretKey(),
        );
    return MoneroMultisigAccount._(
      threshold: 0,
      signers: [],
      basePrivateKey: basePrivateKey,

      ///
      basePublicKey: basePrivateKey.publicKey,
      baseCommonPrivateKey: baseCommonPrivateKey,
      multisigPrivateKeys: [],

      ///
      commonPrivateKey: null,

      kexRoundsComplete: 0,
      nextRoundKexMessage:
          MultisigKexMessage.generate(
            round: 1,
            signingPrivateKey: basePrivateKey,
            msgPubKeys: [],
            msgPrivateKey: baseCommonPrivateKey,
          ).message,
    );
  }

  factory MoneroMultisigAccount.deserialize(
    List<int> bytes, {
    String? propery,
  }) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: MoneroMultisigAccountCore.layout(property: propery),
    );
    return MoneroMultisigAccount.deserializeJson(decode);
  }
  factory MoneroMultisigAccount.deserializeJson(Map<String, dynamic> json) {
    return MoneroMultisigAccount(
      threshold: json.valueAs("threshold"),
      signers:
          json
              .valueEnsureAsList<List<int>>("signers")
              .map((e) => ED25519MoneroPublicKey.fromBytes(e))
              .toList(),
      basePrivateKey: ED25519MoneroPrivateKey.fromBytes(
        json.valueAsBytes("base_private_key"),
      ),
      baseCommonPrivateKey: ED25519MoneroPrivateKey.fromBytes(
        json.valueAsBytes("base_common_private_key"),
      ),
      multisigPrivateKeys:
          json
              .valueEnsureAsList<List<int>>("multisig_private_keys")
              .map((e) => ED25519MoneroPrivateKey.fromBytes(e))
              .toList(),
      commonPrivateKey: ED25519MoneroPrivateKey.fromBytes(
        json.valueAsBytes("common_private_key"),
      ),
      multisigPubKey: ED25519MoneroPublicKey.fromBytes(
        json.valueAsBytes("multisig_pub_key"),
      ),
      commonPubKey: ED25519MoneroPublicKey.fromBytes(
        json.valueAsBytes("common_pub_key"),
      ),
      kexRoundsComplete: json.valueAs("kex_rounds_complete"),
      nextRoundKexMessage: MultisigKexMessageSerializable.fromBase58(
        json.valueAs("kex_round_message"),
      ),
      kexKeysToOriginsMap: json.valueAs<Map>("kex_keys").map((k, v) {
        return MapEntry(
          ED25519MoneroPublicKey.fromBytes(List<int>.from(k)),
          (v as List)
              .map((e) => ED25519MoneroPublicKey.fromBytes((e as List).cast()))
              .toSet(),
        );
      }),
    );
  }

  /// get address
  MoneroAddress toAddress({MoneroNetwork network = MoneroNetwork.mainnet}) {
    if (!multisigIsReady) {
      throw BuError(
        DefaultErrorType.invalidState,
        "Unable to determine the address until the final round is completed.",
      );
    }
    return MoneroAccountAddress.fromPubKeys(
      pubSpendKey: multisigPubKey.toBytes(),
      pubViewKey: commonPrivateKey.publicKey.toBytes(),
      network: network,
    );
  }

  /// create monero account from multisig account
  MoneroAccount toAccount({MoneroNetwork network = MoneroNetwork.mainnet}) {
    if (!multisigIsReady) {
      throw BuError(
        DefaultErrorType.invalidState,
        "Unable to determine account until the final round is completed.",
      );
    }
    return MoneroAccount.multisig(
      privSkey: basePrivateKey,
      privVkey: commonPrivateKey,
      pubSkey: multisigPubKey,
      coinType: network.coin,
    );
  }

  /// generate multisig info for  each output
  MoneroMultisigInfo generateMultisigInfo(MoneroUnlockedOutput out) {
    final List<RctKey> keyImages = [];
    for (final i in multisigPrivateKeys) {
      final partialKeyImage = MoneroMultisigUtils.generateMultisigKeyImageBytes(
        outputPubKey: out.outputPublicKey,
        multisigKey: i.toBytes(),
      );
      keyImages.add(partialKeyImage);
    }

    int nlr = MoneroMultisigUtils.combinationsCount(
      signers.length - threshold,
      signers.length - 1,
    );
    nlr = nlr * MoneroMultisigConst.kAlphaComponents;
    final List<MultisigLR> lr = [];
    final List<ED25519MoneroPrivateKey> nonces = [];
    for (int i = 0; i < nlr; i++) {
      final sK = ED25519MoneroPrivateKey.fromBytes(RCT.skGen());
      nonces.add(sK);
      final r = MoneroMultisigUtils.getMultisigKLRki(
        outPybKey: out.outputPublicKey,
        secretKey: sK.toBytes(),
        keyImage: out.keyImage.keyImage,
      );
      lr.add(MultisigLR(l: r.L, r: r.R));
    }
    final info = MoneroMultisigOutputInfo(
      signer: basePublicKey,
      lr: lr,
      partialKeyImages: keyImages,
    );
    return MoneroMultisigInfo(info: info, nonces: nonces);
  }
}
