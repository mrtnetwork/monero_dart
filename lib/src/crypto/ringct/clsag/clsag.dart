import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class CLSAGUtins {
  static Clsag generate(RctKey message, KeyV P, RctKey p, KeyV C, RctKey z,
      KeyV cNonZero, RctKey cOffset, int l) {
    final int n = P.length;
    if (n != C.length) {
      throw Exception("Signing and commitment key vector sizes must match!");
    }
    if (n != cNonZero.length) {
      throw Exception("Signing and commitment key vector sizes must match!");
    }
    if (l >= n) {
      throw Exception("Signing index out of range!");
    }
    // Key images
    final GroupElementP3 hP3 = GroupElementP3();
    RCT.hashToP3(hP3, P[l]);
    final RctKey H = RCT.zero();
    CryptoOps.geP3Tobytes(H, hP3);
    final RctKey D = RCT.zero();
    // Initial values
    final RctKey a = RCT.zero();
    final RctKey aG = RCT.zero();
    final RctKey aH = RCT.zero();
    final RctKey sigI = RCT.zero();
    final RctKey sigD = RCT.zero();
    RctKey sigC1 = RCT.zero();

    clsagPrepare(p, z, sigI, D, H, a, aG, aH);
    final GroupElementDsmp iPrecomp = GroupElementCached.dsmp;
    final GroupElementDsmp dPrecomp = GroupElementCached.dsmp;
    RCT.precomp(iPrecomp, sigI);
    RCT.precomp(dPrecomp, D);

    // Offset key image
    RCT.scalarmultKey(sigD, D, RCTConst.invEight);

    // // Aggregation hashes
    final KeyV muPtoHash = List.generate(2 * n + 4, (_) => RCT.zero());
    final KeyV muCtoHash = List.generate(2 * n + 4, (_) => RCT.zero());
    muPtoHash[0] = RCT.strToKey(RCTConst.cslagHashKeyAgg0);
    muCtoHash[0] = RCT.strToKey(RCTConst.cslagHashKeyAgg1);
    for (int i = 1; i < n + 1; ++i) {
      muPtoHash[i] = P[i - 1];
      muCtoHash[i] = P[i - 1];
    }
    for (int i = n + 1; i < 2 * n + 1; ++i) {
      muPtoHash[i] = cNonZero[i - n - 1];
      muCtoHash[i] = cNonZero[i - n - 1];
    }
    muPtoHash[2 * n + 1] = sigI;
    muPtoHash[2 * n + 2] = sigD;
    muPtoHash[2 * n + 3] = cOffset;
    muCtoHash[2 * n + 1] = sigI;
    muCtoHash[2 * n + 2] = sigD;
    muCtoHash[2 * n + 3] = cOffset;
    RctKey muP = RCT.zero(), muC = RCT.zero();
    muP = RCT.hashToScalarKeys(muPtoHash);
    muC = RCT.hashToScalarKeys(muCtoHash);
    final KeyV cToHash = List.generate(2 * n + 5, (_) => RCT.zero());
    RctKey c = RCT.zero();
    cToHash[0] = RCT.strToKey(RCTConst.cslagHashKeyRound);
    for (int i = 1; i < n + 1; ++i) {
      cToHash[i] = P[i - 1];
      cToHash[i + n] = cNonZero[i - 1];
    }
    cToHash[2 * n + 1] = cOffset;
    cToHash[2 * n + 2] = message;

    cToHash[2 * n + 3] = aG;
    cToHash[2 * n + 4] = aH;
    c = RCT.hashToScalarKeys(cToHash);
    int i;
    i = (l + 1) % n;
    if (i == 0) {
      sigC1 = c.clone();
    }
    final KeyV sigS = List.generate(n, (_) => RCT.zero());
    RctKey cNew = RCT.zero();
    final RctKey L = RCT.zero();
    final RctKey R = RCT.zero();
    final RctKey cP = RCT.zero();
    final RctKey cC = RCT.zero();
    final GroupElementDsmp pPrecomp = GroupElementCached.dsmp;
    final GroupElementDsmp cPrecomp = GroupElementCached.dsmp;
    final GroupElementDsmp hPrecomp = GroupElementCached.dsmp;
    final GroupElementP3 hiP3 = GroupElementP3();
    while (i != l) {
      sigS[i] = RCT.skGen_();
      cNew = RCT.zero();
      CryptoOps.scMul(cP, muP, c);
      CryptoOps.scMul(cC, muC, c);

      // Precompute points
      RCT.precomp(pPrecomp, P[i]);
      RCT.precomp(cPrecomp, C[i]);

      // Compute L
      RCT.addKeysAGbBcC(L, sigS[i], cP, pPrecomp, cC, cPrecomp);

      // // Compute R
      RCT.hashToP3(hiP3, P[i]);
      CryptoOps.geDsmPrecomp(hPrecomp, hiP3);
      RCT.addKeysAAbBcC(R, sigS[i], hPrecomp, cP, iPrecomp, cC, dPrecomp);

      cToHash[2 * n + 3] = L;
      cToHash[2 * n + 4] = R;
      cNew = RCT.hashToScalarKeys(cToHash);
      c = cNew.clone();
      i = (i + 1) % n;
      if (i == 0) sigC1 = c.clone();
    }
    clsagSign(c, a, p, z, muP, muC, sigS[l]);
    return Clsag(s: sigS, c1: sigC1, d: sigD, i: sigI);
    // return sig;
  }

  static void clsagPrepare(RctKey p, RctKey z, RctKey I, RctKey D, RctKey H,
      RctKey a, RctKey aG, RctKey aH) {
    RCT.skpkGen(a, aG);
    RCT.scalarmultKey(aH, H, a);
    RCT.scalarmultKey(I, H, p);
    RCT.scalarmultKey(D, H, z);
  }

  static void clsagSign(RctKey c, RctKey a, RctKey p, RctKey z, RctKey muP,
      RctKey muC, RctKey s) {
    final RctKey s0PmuP = RCT.zero();
    CryptoOps.scMul(s0PmuP, muP, p);
    final RctKey s0AddZMuC = RCT.zero();
    CryptoOps.scMulAdd(s0AddZMuC, muC, z, s0PmuP);
    CryptoOps.scMulSub(s, c, s0AddZMuC, a);
  }

  static bool verify(RctKey message, Clsag sig, CtKeyV pubs, RctKey cOffset) {
    try {
      final int n = pubs.length;
      if (n < 1) {
        throw const MoneroCryptoException("Empty pubs");
      }
      if (n != sig.s.length) {
        throw const MoneroCryptoException(
            "Signature scalar vector is the wrong size!");
      }

      for (int i = 0; i < n; i++) {
        if (CryptoOps.scCheck(sig.s[i]) != 0) {
          throw const MoneroCryptoException("Bad signature scalar!");
        }
      }

      if (CryptoOps.scCheck(sig.c1) != 0) {
        throw const MoneroCryptoException("Bad signature commitment!");
      }

      if (sig.i == null ||
          BytesUtils.bytesEqual(sig.i, RCT.identity(clone: false))) {
        throw const MoneroCryptoException("Bad key image!");
      }
      final GroupElementP3 cOffsetP3 = GroupElementP3();
      if (CryptoOps.geFromBytesVartime_(cOffsetP3, cOffset) != 0) {
        throw const MoneroCryptoException("point conv failed");
      }
      final GroupElementCached cOffsetCached = GroupElementCached();
      CryptoOps.geP3ToCached(cOffsetCached, cOffsetP3);
      RctKey c = sig.c1.clone();
      final RctKey d8 = RCT.scalarmult8_(sig.d);
      if (BytesUtils.bytesEqual(d8, RCT.identity(clone: false))) {
        throw const MoneroCryptoException("Bad auxiliary key image!");
      }
      final GroupElementDsmp iPrecomp = GroupElementCached.dsmp;
      final GroupElementDsmp dPrecomp = GroupElementCached.dsmp;
      if (sig.i == null) {
        throw const MoneroCryptoException("I is required for verification.");
      }
      RCT.precomp(iPrecomp, sig.i!);
      RCT.precomp(dPrecomp, d8);
      final KeyV muPtoHash = List.generate(2 * n + 4, (_) => RCT.zero());
      final KeyV muCtoHash = List.generate(2 * n + 4, (_) => RCT.zero());
      muPtoHash[0] = RCT.strToKey(RCTConst.cslagHashKeyAgg0);
      muCtoHash[0] = RCT.strToKey(RCTConst.cslagHashKeyAgg1);
      for (int i = 1; i < n + 1; ++i) {
        muPtoHash[i] = pubs[i - 1].dest;
        muCtoHash[i] = pubs[i - 1].dest;
      }
      for (int i = n + 1; i < 2 * n + 1; ++i) {
        muPtoHash[i] = pubs[i - n - 1].mask;
        muCtoHash[i] = pubs[i - n - 1].mask;
      }
      muPtoHash[2 * n + 1] = sig.i!;
      muPtoHash[2 * n + 2] = sig.d;
      muPtoHash[2 * n + 3] = cOffset;
      muCtoHash[2 * n + 1] = sig.i!;
      muCtoHash[2 * n + 2] = sig.d;
      muCtoHash[2 * n + 3] = cOffset;
      RctKey muP = RCT.zero(), muC = RCT.zero();
      muP = RCT.hashToScalarKeys(muPtoHash);
      muC = RCT.hashToScalarKeys(muCtoHash);
      final KeyV cToHash = List.generate(2 * n + 5, (_) => RCT.zero());
      cToHash[0] = RCT.strToKey(RCTConst.cslagHashKeyRound);
      for (int i = 1; i < n + 1; ++i) {
        cToHash[i] = pubs[i - 1].dest;
        cToHash[i + n] = pubs[i - 1].mask;
      }
      cToHash[2 * n + 1] = cOffset;
      cToHash[2 * n + 2] = message;
      final RctKey cP = RCT.zero();
      final RctKey cC = RCT.zero();
      RctKey cNew = RCT.zero();
      final RctKey L = RCT.zero();
      final RctKey R = RCT.zero();
      final GroupElementDsmp pPrecomp = GroupElementCached.dsmp;
      final GroupElementDsmp cPrecomp = GroupElementCached.dsmp;
      int i = 0;
      final GroupElementP3 hash8P3 = GroupElementP3();
      final GroupElementDsmp hashPrecomp = GroupElementCached.dsmp;

      final GroupElementP3 tempP3 = GroupElementP3();
      final GroupElementP1P1 tempP1 = GroupElementP1P1();
      while (i < n) {
        CryptoOps.scZero(cNew);
        CryptoOps.scMul(cP, muP, c);
        CryptoOps.scMul(cC, muC, c);

        RCT.precomp(pPrecomp, pubs[i].dest);

        if (CryptoOps.geFromBytesVartime_(tempP3, pubs[i].mask) != 0) {
          throw const MoneroCryptoException("point conv failed");
        }
        CryptoOps.geSub(tempP1, tempP3, cOffsetCached);
        CryptoOps.geP1P1ToP3(tempP3, tempP1);
        CryptoOps.geDsmPrecomp(cPrecomp, tempP3);

        RCT.addKeysAGbBcC(L, sig.s[i], cP, pPrecomp, cC, cPrecomp);

        RCT.hashToP3(hash8P3, pubs[i].dest);
        CryptoOps.geDsmPrecomp(hashPrecomp, hash8P3);
        RCT.addKeysAAbBcC(R, sig.s[i], hashPrecomp, cP, iPrecomp, cC, dPrecomp);

        cToHash[2 * n + 3] = L;
        cToHash[2 * n + 4] = R;
        cNew = RCT.hashToScalarKeys(cToHash);
        if (BytesUtils.bytesEqual(cNew, RCT.zero(clone: false))) {
          throw const MoneroCryptoException("Bad signature hash");
        }
        // CHECK_AND_ASSERT_MES(!(cNew == rct::zero()), false, "Bad signature hash");
        c = cNew.clone();

        i = i + 1;
      }
      CryptoOps.scSub(cNew, c, sig.c1);
      return CryptoOps.scIsNonZero(cNew) == 0;
    } catch (e) {
      return false;
    }
  }

  static Clsag fakeProve(int ringSize) {
    return Clsag(
        s: List.filled(ringSize, RCT.identity(clone: false)),
        c1: RCT.identity(clone: false),
        d: RCT.identity(clone: false),
        i: RCT.identity(clone: false));
  }

  static Clsag prove(RctKey message, CtKeyV pubs, CtKey inSk, RctKey a,
      RctKey cout, int index) {
    if (pubs.isEmpty) {
      throw const MoneroCryptoException("Empty pubs");
    }
    final KeyV sk = List.generate(2, (_) => RCT.zero());
    final KeyV P = [];
    final KeyV C = [];
    final KeyV cNonZero = [];

    for (int i = 0; i < pubs.length; i++) {
      final k = pubs[i];
      P.add(k.dest.clone());
      cNonZero.add(k.mask.clone());
      final RctKey tmp = RCT.zero();
      RCT.subKeys(tmp, k.mask, cout);
      C.add(tmp);
    }
    sk[0] = inSk.dest.clone();
    CryptoOps.scSub(sk[1], inSk.mask, a);
    final Clsag result =
        generate(message, P, sk[0], C, sk[1], cNonZero, cout, index);
    return result;
  }
}
