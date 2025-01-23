import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:monero_dart/src/crypto/multisig/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/models/models.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';

class MoneroMultisigUtils {
  static int combinationsCount(int k, int n) {
    if (k > n) {
      throw const DartMoneroPluginException("k must not be greater than n");
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
    required RctKey keyImage,
  }) {
    final l = RCT.zero();
    final r = generateMultisigLr(
        pubKey: outPybKey, secretKey: secretKey, resultKeyL: l);
    return MultisigKLRKI(k: secretKey, L: l, R: r, ki: keyImage);
  }

  static RctKey generateMultisigLr(
      {required List<int> pubKey,
      required List<int> secretKey,
      RctKey? resultKeyL,
      RctKey? resultKeyR}) {
    resultKeyL ??= RCT.zero();
    resultKeyR ??= RCT.zero();
    RCT.scalarmultBase(resultKeyL, secretKey);
    MoneroCrypto.generateKeyImageBytes(
        pubkey: pubKey, secretKey: secretKey, resultKey: resultKeyR);
    return resultKeyR;
  }

  static RctKey generateMultisigKeyImageBytes(
      {required List<int> outputPubKey,
      required List<int> multisigKey,
      RctKey? resultKey}) {
    return MoneroCrypto.generateKeyImageBytes(
        pubkey: outputPubKey, secretKey: multisigKey, resultKey: resultKey);
  }

  static RctKey generateMultisigKeyImage(
      {required MoneroPublicKey outputPubKey,
      required MoneroPrivateKey multisigKey,
      RctKey? resultKey}) {
    return MoneroCrypto.generateKeyImage(
        pubkey: outputPubKey, secretKey: multisigKey, resultKey: resultKey);
  }

  static RctKey generateMultisigCompositeKeyImage(
      {required List<MoneroMultisigOutputInfo> infos,
      required RctKey keyImage,
      required List<RctKey> exclude}) {
    final RctKey kImage = keyImage.clone();
    for (final i in infos) {
      for (final p in i.partialKeyImages) {
        if (!BytesUtils.isContains(exclude, p)) {
          RCT.addKeys(kImage, kImage, p);
          exclude.add(p);
        }
      }
    }
    return kImage;
  }

  static MultisigKLRKI getMultisigCompositeKLRki(
      {required List<int> outPubKey,
      required RctKey keyImage,
      required List<MoneroMultisigOutputInfo> infos,
      required List<RctKey> usedL,
      required List<RctKey> newUsedL,
      required int threshHold}) {
    final sk = RCT.skGen_().asImmutableBytes;
    final klrki = getMultisigKLRki(
        outPybKey: outPubKey, secretKey: sk, keyImage: keyImage);
    final RctKey L = klrki.L.clone();
    final RctKey R = klrki.R.clone();
    int signers = 1;

    for (final i in infos) {
      for (final lr in i.lr) {
        if (BytesUtils.isContains(usedL, lr.l)) {
          continue;
        }
        usedL.add(lr.l);
        newUsedL.add(lr.l);
        RCT.addKeys(L, L, lr.l);
        RCT.addKeys(R, R, lr.r);
        signers++;
        break;
      }
    }
    if (signers < threshHold) {
      throw const MoneroMultisigAccountException(
          "LR not found for enough participants");
    }

    return MultisigKLRKI(k: klrki.k, L: L, R: R, ki: klrki.ki);
  }
}
