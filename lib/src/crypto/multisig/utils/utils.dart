import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/transaction/input.dart';

class MoneroMultisigUtils {
  static int combinationsCount(int k, int n) {
    if (k > n) {
      throw BuError(DefaultErrorType.invalidArgument, "k must not be greater than n");
    }

    int c = 1;
    for (int i = 1; i <= k; ++i) {
      c *= n--;
      c ~/= i;
    }

    return c;
  }

  static MultisigKLRKI getMultisigKLRki({
    required List<int> outPybKey,
    required List<int> secretKey,
    required List<int> keyImage,
  }) {
    final (l, r) = generateMultisigLr(pubKey: outPybKey, secretKey: secretKey);
    return MultisigKLRKI(k: secretKey, L: l, R: r, ki: keyImage);
  }

  static (RctKey, RctKey) generateMultisigLr({
    required List<int> pubKey,
    required List<int> secretKey,
  }) {
    final RctKey l = RCT.scalarmultBase(secretKey);
    final RctKey r = MoneroCrypto.generateKeyImageBytes(
      pubkey: pubKey,
      secretKey: secretKey,
    );
    return (l, r);
  }

  static RctKey generateMultisigKeyImageBytes({
    required List<int> outputPubKey,
    required List<int> multisigKey,
  }) {
    return MoneroCrypto.generateKeyImageBytes(
      pubkey: outputPubKey,
      secretKey: multisigKey,
    ).asBytes;
  }

  static RctKey generateMultisigKeyImage({
    required ED25519MoneroPublicKey outputPubKey,
    required ED25519MoneroPrivateKey multisigKey,
  }) {
    return multisigKey.takeSecretKey().useValue(
      (k) => MoneroCrypto.generateKeyImageBytes(
        pubkey: outputPubKey.keyBytes,
        secretKey: k,
      ),
    );
  }

  static TxKeyImage generateMultisigCompositeKeyImage({
    required List<MoneroMultisigOutputInfo> infos,
    required TxKeyImage keyImage,
    required List<List<int>> exclude,
  }) {
    RctKey kImage = keyImage.keyImage.clone();
    for (final i in infos) {
      for (final p in i.partialKeyImages) {
        if (!BytesUtils.isContains(exclude, p)) {
          kImage = RCT.addKeys(kImage, p);
          exclude.add(p);
        }
      }
    }
    return TxKeyImage(kImage);
  }

  static MultisigKLRKI getMultisigCompositeKLRki({
    required List<int> outPubKey,
    required List<int> keyImage,
    required List<MoneroMultisigOutputInfo> infos,
    required List<List<int>> usedL,
    required List<List<int>> newUsedL,
    required int threshHold,
  }) {
    final sk = RCT.skGen().asImmutableBytes;
    final klrki = getMultisigKLRki(
      outPybKey: outPubKey,
      secretKey: sk,
      keyImage: keyImage,
    );
    RctKey L = klrki.L.clone();
    RctKey R = klrki.R.clone();
    int signers = 1;

    for (final i in infos) {
      for (final lr in i.lr) {
        if (BytesUtils.isContains(usedL, lr.l)) {
          continue;
        }
        usedL.add(lr.l);
        newUsedL.add(lr.l);
        L = RCT.addKeys(L, lr.l);
        R = RCT.addKeys(R, lr.r);
        signers++;
        break;
      }
    }
    if (signers < threshHold) {
      throw BuError(DefaultErrorType.notFound, 
        "LR not found for enough participants",
      );
    }

    return MultisigKLRKI(k: klrki.k, L: L, R: R, ki: klrki.ki);
  }
}
