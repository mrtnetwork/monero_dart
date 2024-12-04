// Copyright (c) 2021-2024, The Monero Project
// Copyright (c) 2024, MRTNETWORK (https://github.com/mrtnetwork)

// All rights reserved.

// This software includes portions of the Monero Project's original C/C++ implementation,
// which have been adapted and reimplemented in Dart.

// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// Redistributions of source code must retain the above copyright notice,
// this list of conditions, and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions, and the following disclaimers in the documentation and/or other materials provided with the distribution.
// Neither the name of the copyright holders nor the names of their contributors
// may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/ringct/clsag/clsag.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/network/config.dart';

class RCTGeneratorUtils {
  static RctKey getPreMlsagHash(RCTSignature rv) {
    final KeyV hashes = [];
    if (rv.signature.message == null ||
        (rv.signature.mixRing?.isEmpty ?? true)) {
      throw const MoneroCryptoException(
          "message and mixRing required for generate mlsag hash.");
    }
    final message = rv.signature.message!;
    final mixRing = rv.signature.mixRing!;
    hashes.add(message);
    final int inputs =
        rv.signature.type.isSimple ? mixRing.length : mixRing[0].length;
    final int outputs = rv.signature.ecdhInfo.length;
    final ss = RCTSignature.layout(
            inputLength: inputs, outputLength: outputs, forcePrunable: true)
        .serialize(rv.toLayoutStruct());
    final h = QuickCrypto.keccack256Hash(ss);
    hashes.add(h);
    final KeyV kv = [];
    if (rv.signature.type == RCTType.rctTypeBulletproof ||
        rv.signature.type == RCTType.rctTypeBulletproof2 ||
        rv.signature.type == RCTType.rctTypeCLSAG) {
      final bulletproofs = rv.rctSigPrunable!.cast<BulletproofPrunable>();
      for (final p in bulletproofs.bulletproof) {
        // V are not hashed as they're expanded from outPk.mask
        // (and thus hashed as part of rctSigBase above)
        kv.add(p.a);
        kv.add(p.s);
        kv.add(p.t1);
        kv.add(p.t2);
        kv.add(p.taux);
        kv.add(p.mu);
        for (int n = 0; n < p.l.length; ++n) {
          kv.add(p.l[n]);
        }
        for (int n = 0; n < p.r.length; ++n) {
          kv.add(p.r[n]);
        }
        kv.add(p.a_);
        kv.add(p.b);
        kv.add(p.t);
      }
    } else if (rv.signature.type == RCTType.rctTypeBulletproofPlus) {
      final bulletproofs =
          rv.rctSigPrunable!.cast<RctSigPrunableBulletproofPlus>();
      for (final p in bulletproofs.bulletproofPlus) {
        kv.add(p.a);
        kv.add(p.a1);
        kv.add(p.b);
        kv.add(p.r1);
        kv.add(p.s1);
        kv.add(p.d1);
        for (int n = 0; n < p.l.length; ++n) {
          kv.add(p.l[n]);
        }
        for (int n = 0; n < p.r.length; ++n) {
          kv.add(p.r[n]);
        }
      }
    } else {
      final range = rv.rctSigPrunable!.cast<RctSigPrunableRangeSigs>();
      for (final r in range.rangeSig) {
        for (int n = 0; n < 64; ++n) {
          kv.add(r.asig.s0[n]);
        }
        for (int n = 0; n < 64; ++n) {
          kv.add(r.asig.s1[n]);
        }
        kv.add(r.asig.ee);
        for (int n = 0; n < 64; ++n) {
          kv.add(r.ci[n]);
        }
      }
    }
    hashes.add(QuickCrypto.keccack256Hash(kv.expand((e) => e).toList()));
    return QuickCrypto.keccack256Hash(hashes.expand((e) => e).toList());
  }

  static const int maxOuts = 16;
  static CtKey _generateRandomKey() {
    final mask = RCT.pkGen();
    final dest = RCT.pkGen();
    return CtKey(mask: mask, dest: dest);
  }

  static BulletproofPlus _proveRangeBulletproofPlus(
      KeyV C, KeyV masks, List<BigInt> amounts, List<RctKey> sk) {
    if (amounts.length != sk.length) {
      throw const MoneroCryptoException("Invalid amounts/sk sizes");
    }
    final proof =
        BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(amounts, masks);
    if (proof.v.length != amounts.length) {
      throw const MoneroCryptoException("V does not have the expected size");
    }
    for (int i = 0; i < proof.v.length; i++) {
      C[i] = proof.v[i].clone();
    }
    return proof;
  }

  static BulletproofPlus _fakeProveRangeBulletproofPlus(
      KeyV C, KeyV masks, List<BigInt> amounts) {
    int lR = 0;
    while ((1 << lR) < amounts.length) {
      ++lR;
    }
    lR += 6;
    for (int i = 0; i < amounts.length; ++i) {
      masks[i] = RCT.identity(clone: false);
      final RctKey sv8 = RCT.zero();
      final RctKey sv = RCT.d2h(amounts[i]);
      CryptoOps.scMul(sv8, sv, RCTConst.invEight);
      RCT.addKeys2(C[i], RCTConst.invEight, sv8, RCTConst.h);
    }
    return BulletproofPlus(
        a: RCT.identity(clone: false),
        a1: RCT.identity(clone: false),
        b: RCT.identity(clone: false),
        r1: RCT.identity(clone: false),
        s1: RCT.identity(clone: false),
        d1: RCT.identity(clone: false),
        l: List.filled(lR, RCT.identity(clone: false)),
        r: List.filled(lR, RCT.identity(clone: false)),
        v: List.filled(amounts.length, RCT.identity(clone: false)));
  }

  static RCTSignature<S, P>
      genRctSimple<S extends RCTSignatureBase, P extends RctSigPrunable>(
          {required RctKey message,
          required CtKeyV inSk,
          required KeyV destinations,
          required List<BigInt> inamounts,
          required List<BigInt> outamounts,
          required BigInt txnFee,
          required CtKeyM mixRing,
          required KeyV amountKeys,
          required List<int> index,
          required CtKeyV outSk,
          KeyV? aResult,
          bool createLinkable = true}) {
    if (inamounts.isEmpty) {
      throw const MoneroCryptoException("Empty inamounts");
    }

    if (inamounts.length != inSk.length) {
      throw const MoneroCryptoException("Different number of inamounts/inSk");
    }

    if (outamounts.length != destinations.length) {
      throw const MoneroCryptoException(
          "Different number of amounts/destinations");
    }

    if (amountKeys.length != destinations.length) {
      throw const MoneroCryptoException(
          "Different number of amountKeys/destinations");
    }

    if (index.length != inSk.length) {
      throw const MoneroCryptoException("Different number of index/inSk");
    }

    if (mixRing.length != inSk.length) {
      throw const MoneroCryptoException("Different number of mixRing/inSk");
    }

    for (int n = 0; n < mixRing.length; n++) {
      if (index[n] >= mixRing[n].length) {
        throw const MoneroCryptoException("Bad index into mixRing");
      }
    }
    final CtKeyV outPk = [];
    int i;
    final List<RangeSig> rangeSig = [];
    final List<BulletproofPlus> bulletProofPlus = [];
    final List<Bulletproof> bulletProof = [];
    final List<EcdhInfo> ecdh = [];
    for (i = 0; i < destinations.length; i++) {
      final mask = RCT.zero();
      final outSkMask = outSk[i].mask.clone();
      // if (!bpOrBpp) {
      //   final s = BoroSigUtils.proveRange(mask, outSkMask, outamounts[i]);
      //   rangeSig.add(s);
      // }
      outSk[i] = outSk[i].copyWith(mask: outSkMask);
      final CtKey pk = CtKey(dest: destinations[i].clone(), mask: mask);
      outPk.add(pk);
    }

    final keys = amountKeys.map((e) => e.clone()).toList();
    final KeyV masks =
        List.generate(outamounts.length, (i) => RCT.genCommitmentMask(keys[i]));
    final KeyV C = List.generate(outamounts.length, (_) => RCT.zero());
    final prove = _proveRangeBulletproofPlus(C, masks, outamounts, keys);
    bulletProofPlus.add(prove);
    for (i = 0; i < outamounts.length; ++i) {
      final mask = RCT.scalarmult8_(C[i]);
      outPk[i] = outPk[i].copyWith(mask: mask);
      outSk[i] = outSk[i].copyWith(mask: masks[i]);
    }
    final RctKey sumout = RCT.zero();
    for (i = 0; i < outSk.length; ++i) {
      CryptoOps.scAdd(sumout, outSk[i].mask, sumout);
      final ecdhT = EcdhTuple(
          mask: outSk[i].mask,
          amount: RCT.d2h(outamounts[i]),
          version: EcdhInfoVersion.v2);
      final EcdhInfo info = RCT.ecdhEncode(ecdhT, amountKeys[i]);
      ecdh.add(info);
    }
    // BigInt txFee = txnFee;
    final KeyV pseudoOuts = List.generate(inamounts.length, (_) => RCT.zero());
    final List<MgSig> mgs = [];
    final List<Clsag> clsag = [];
    final RctKey sumpouts = RCT.zero();
    final KeyV a =
        aResult ?? List.generate(inamounts.length, (_) => RCT.zero());
    if (a.length != inamounts.length) {
      throw const MoneroCryptoException("Invalid a provided.");
    }
    for (i = 0; i < inamounts.length - 1; i++) {
      RCT.skGen(a[i]);
      CryptoOps.scAdd(sumpouts, a[i], sumpouts);
      RCT.genC(pseudoOuts[i], a[i], inamounts[i]);
    }
    CryptoOps.scSub(a[i], sumout, sumpouts);
    RCT.genC(pseudoOuts[i], a[i], inamounts[i]);
    final RCTSignature<S, P> signature = buildSignature(
        type: RCTType.rctTypeBulletproofPlus,
        ecdh: ecdh,
        txnFee: txnFee,
        outPk: outPk,
        message: message,
        mixRing: mixRing,
        rangeSig: rangeSig,
        mgs: mgs,
        bulletProofPlus: bulletProofPlus,
        bulletProof: bulletProof,
        clsag: clsag,
        pseudoOuts: pseudoOuts);
    if (!createLinkable) return signature;
    final RctKey fullMessage = getPreMlsagHash(signature);
    for (i = 0; i < inamounts.length; i++) {
      final prove = CLSAGUtins.prove(
          fullMessage,
          signature.signature.mixRing![i],
          inSk[i],
          a[i],
          pseudoOuts[i],
          index[i]);
      clsag.add(prove);
    }
    return buildSignature<S, P>(
        type: RCTType.rctTypeBulletproofPlus,
        ecdh: ecdh,
        txnFee: txnFee,
        outPk: outPk,
        message: message,
        mixRing: mixRing,
        rangeSig: rangeSig,
        mgs: mgs,
        bulletProofPlus: bulletProofPlus,
        bulletProof: bulletProof,
        clsag: clsag,
        pseudoOuts: pseudoOuts);
  }

  static RCTSignature<S, P>
      genFakeRctSimple<S extends RCTSignatureBase, P extends RctSigPrunable>(
          {required RctKey message,
          required CtKeyV inSk,
          required KeyV destinations,
          required List<BigInt> inamounts,
          required List<BigInt> outamounts,
          required BigInt txnFee,
          required CtKeyM mixRing,
          required KeyV amountKeys,
          required List<int> index,
          required CtKeyV outSk,
          // required RCTType? rctType,
          KeyV? aResult,
          bool createLinkable = true}) {
    if (inamounts.isEmpty) {
      throw const MoneroCryptoException("Empty inamounts");
    }

    if (inamounts.length != inSk.length) {
      throw const MoneroCryptoException("Different number of inamounts/inSk");
    }

    if (outamounts.length != destinations.length) {
      throw const MoneroCryptoException(
          "Different number of amounts/destinations");
    }

    if (amountKeys.length != destinations.length) {
      throw const MoneroCryptoException(
          "Different number of amountKeys/destinations");
    }

    if (index.length != inSk.length) {
      throw const MoneroCryptoException("Different number of index/inSk");
    }

    if (mixRing.length != inSk.length) {
      throw const MoneroCryptoException("Different number of mixRing/inSk");
    }

    for (int n = 0; n < mixRing.length; n++) {
      if (index[n] >= mixRing[n].length) {
        throw const MoneroCryptoException("Bad index into mixRing");
      }
    }
    final CtKeyV outPk = [];
    int i;
    final List<RangeSig> rangeSig = [];
    final List<BulletproofPlus> bulletProofPlus = [];
    final List<Bulletproof> bulletProof = [];
    final List<EcdhInfo> ecdh = [];
    for (i = 0; i < destinations.length; i++) {
      final mask = RCT.zero();
      final outSkMask = outSk[i].mask.clone();
      outSk[i] = outSk[i].copyWith(mask: outSkMask);
      final CtKey pk = CtKey(dest: destinations[i].clone(), mask: mask);
      outPk.add(pk);
    }
    final KeyV masks = List.filled(outamounts.length, RCT.identity());
    final KeyV C = List.generate(outamounts.length, (_) => RCT.identity());
    final prove = _fakeProveRangeBulletproofPlus(C, masks, outamounts);
    bulletProofPlus.add(prove);
    final RctKey sumout = RCT.zero();
    for (i = 0; i < outSk.length; ++i) {
      CryptoOps.scAdd(sumout, outSk[i].mask, sumout);
      final ecdhT = EcdhTuple(
          mask: outSk[i].mask,
          amount: RCT.d2h(outamounts[i]),
          version: EcdhInfoVersion.v2);
      final EcdhInfo info = RCT.ecdhEncode(ecdhT, amountKeys[i]);
      ecdh.add(info);
    }
    // BigInt txFee = txnFee;
    final KeyV pseudoOuts = List.generate(inamounts.length, (_) => RCT.zero());
    final List<MgSig> mgs = [];
    final List<Clsag> clsag = [];
    final RctKey sumpouts = RCT.zero();
    final KeyV a =
        aResult ?? List.generate(inamounts.length, (_) => RCT.zero());
    if (a.length != inamounts.length) {
      throw const MoneroCryptoException("Invalid a provided.");
    }
    for (i = 0; i < inamounts.length - 1; i++) {
      RCT.skGen(a[i]);
      CryptoOps.scAdd(sumpouts, a[i], sumpouts);
      RCT.genC(pseudoOuts[i], a[i], inamounts[i]);
    }
    CryptoOps.scSub(a[i], sumout, sumpouts);
    RCT.genC(pseudoOuts[i], a[i], inamounts[i]);
    final RCTSignature<S, P> signature = buildSignature(
        type: RCTType.rctTypeBulletproofPlus,
        ecdh: ecdh,
        txnFee: txnFee,
        outPk: outPk,
        message: message,
        mixRing: mixRing,
        rangeSig: rangeSig,
        mgs: mgs,
        bulletProofPlus: bulletProofPlus,
        bulletProof: bulletProof,
        clsag: clsag,
        pseudoOuts: pseudoOuts);
    for (i = 0; i < inamounts.length; i++) {
      final prove =
          CLSAGUtins.fakeProve(signature.signature.mixRing![i].length);
      clsag.add(prove);
    }
    return buildSignature<S, P>(
        type: RCTType.rctTypeBulletproofPlus,
        ecdh: ecdh,
        txnFee: txnFee,
        outPk: outPk,
        message: message,
        mixRing: mixRing,
        rangeSig: rangeSig,
        mgs: mgs,
        bulletProofPlus: bulletProofPlus,
        bulletProof: bulletProof,
        clsag: clsag,
        pseudoOuts: pseudoOuts);
  }

  static bool verRctSemanticsSimple(List<RCTSignature> rvv) {
    final List<BulletproofPlus> bppProofs = [];
    for (final rv in rvv) {
      if (!rv.signature.type.isSimple) {
        throw const MoneroCryptoException("called on non simple rctSig");
      }
      final bool bulletproof = rv.signature.type.isBulletproof;
      final bool bulletproofPlus = rv.signature.type.isBulletproofPlus;
      if (bulletproof || bulletproofPlus) {
        if (bulletproofPlus) {
          if (rv.signature.outPk.length !=
              nBulletproofPlusAmounts(rv.rctSigPrunable!
                  .cast<RctSigPrunableBulletproofPlus>()
                  .bulletproofPlus)) {
            throw const MoneroCryptoException(
                "Mismatched sizes of outPk and bulletproofs_plus");
          }
        } else {
          if (rv.signature.outPk.length !=
              nBulletproofAmounts(
                  rv.rctSigPrunable!.cast<BulletproofPrunable>().bulletproof)) {
            throw const MoneroCryptoException(
                "Mismatched sizes of outPk and bulletproofs");
          }
        }

        if (rv.signature.type.isClsag) {
          final clsag = rv.rctSigPrunable!.cast<ClsagPrunable>();
          if (clsag.pseudoOuts.length != clsag.clsag.length) {
            throw const MoneroCryptoException(
                "Mismatched sizes of pseudoOuts and CLSAGs");
          }
        }

        if (rv.signature.pseudoOuts?.isNotEmpty ?? false) {
          throw const MoneroCryptoException("pseudoOuts is not empty");
        }
      }

      if (rv.signature.outPk.length != rv.signature.ecdhInfo.length) {
        throw const MoneroCryptoException(
            "Mismatched sizes of outPk and rv.ecdhInfo");
      }
    }

    for (final rv in rvv) {
      final bool bulletproof = rv.signature.type.isBulletproof;
      final bool bulletproofPlus = rv.signature.type.isBulletproofPlus;
      KeyV pseudoOuts = rv.signature.pseudoOuts ?? [];
      if (bulletproof || bulletproofPlus) {
        pseudoOuts =
            rv.rctSigPrunable!.pseudoOuts.map((e) => e.clone()).toList();
      }
      final KeyV masks =
          List.generate(rv.signature.outPk.length, (_) => RCT.zero());
      for (int i = 0; i < rv.signature.outPk.length; i++) {
        masks[i] = rv.signature.outPk[i].mask.clone();
      }
      final RctKey sumOutpks = RCT.addKeysBatch(masks);
      final RctKey txnFeeKey = RCT.scalarmultH(RCT.d2h(rv.signature.txnFee));
      RCT.addKeys(sumOutpks, txnFeeKey, sumOutpks);
      final RctKey sumPseudoOuts = RCT.addKeysBatch(pseudoOuts);
      if (!BytesUtils.bytesEqual(sumPseudoOuts, sumOutpks)) {
        return false;
      }
      final bpp = rv.rctSigPrunable!.cast<RctSigPrunableBulletproofPlus>();
      bppProofs.addAll(bpp.bulletproofPlus);
    }
    final ver = BulletproofsPlusGenerator.bulletproofPlusVerify(bppProofs);
    if (!ver) return false;
    return true;
  }

  static bool verRctNonSemanticsSimple(RCTSignature rv) {
    if (!rv.signature.type.isSimple) {
      throw const MoneroCryptoException("called on non simple rctSig");
    }
    if (rv.signature.mixRing == null || rv.signature.message == null) {
      throw const MoneroCryptoException(
          "mixRing and message required for verification.");
    }
    if (rv.rctSigPrunable == null) {
      throw const MoneroCryptoException(
          "Prunable signature is required for verification.");
    }
    final bool bulletproof = rv.signature.type.isBulletproof;
    final bool bulletproofPlus = rv.signature.type.isBulletproofPlus;
    if (bulletproof || bulletproofPlus) {
      if (rv.signature.mixRing!.length !=
          rv.rctSigPrunable!.pseudoOuts.length) {
        throw const MoneroCryptoException(
            "Mismatched sizes of pseudoOuts and mixRing");
      }
    } else {
      if (rv.signature.pseudoOuts == null) {
        throw const MoneroCryptoException(
            "Signature pseudoOuts is required for verification.");
      }
      if (rv.signature.mixRing!.length != rv.signature.pseudoOuts?.length) {
        throw const MoneroCryptoException(
            "Mismatched sizes of pseudoOuts and mixRing");
      }
    }
    final KeyV pseudoOuts = bulletproof || bulletproofPlus
        ? rv.rctSigPrunable!.pseudoOuts
        : rv.signature.pseudoOuts!;
    final message = getPreMlsagHash(rv);
    for (int i = 0; i < rv.signature.mixRing!.length; i++) {
      final cslag = rv.rctSigPrunable!.cast<ClsagPrunable>();
      final verify = CLSAGUtins.verify(
          message, cslag.clsag[i], rv.signature.mixRing![i], pseudoOuts[i]);
      if (!verify) return false;
    }
    return true;
  }

  static bool verRctSimple(RCTSignature rv) {
    final bool verRctNonSemantics = verRctNonSemanticsSimple(rv);
    bool verRctSemantics = false;
    if (verRctNonSemantics) {
      verRctSemantics = verRctSemanticsSimple([rv]);
    }
    return verRctSemantics && verRctNonSemantics;
  }

  static int nBulletproofAmountsBase(
      int lSize, int rSize, int vSize, int maxOutputs) {
    if (lSize < 6) {
      throw const MoneroCryptoException("Invalid bulletproof L size");
    }
    if (lSize != rSize) {
      throw const MoneroCryptoException("Mismatched bulletproof L/R size");
    }

    const int extraBits = 4;
    if ((1 << extraBits) != maxOutputs) {
      throw const MoneroCryptoException("log2(max_outputs) is out of date");
    }
    if (lSize > 6 + extraBits) {
      throw const MoneroCryptoException("Invalid bulletproof L size");
    }
    if (vSize > (1 << (lSize - 6))) {
      throw const MoneroCryptoException("Invalid bulletproof V/L");
    }
    if (vSize * 2 <= (1 << (lSize - 6))) {
      throw const MoneroCryptoException("Invalid bulletproof V/L");
    }
    if (vSize <= 0) {
      throw const MoneroCryptoException("Empty bulletproof");
    }

    return vSize;
  }

  static int nBulletproofAmount(Bulletproof proof) {
    return nBulletproofAmountsBase(
        proof.l.length, proof.r.length, proof.v.length, maxOuts);
  }

  static int nBulletproofPlusAmount(BulletproofPlus proof) {
    return nBulletproofAmountsBase(
        proof.l.length, proof.r.length, proof.v.length, maxOuts);
  }

  static int nBulletproofAmounts(List<Bulletproof> proofs) {
    int n = 0;

    for (final Bulletproof proof in proofs) {
      final int n2 = nBulletproofAmount(proof);
      if (n2 >= mask32 - n) {
        throw const MoneroCryptoException("Invalid number of bulletproofs");
      }

      if (n2 == 0) {
        return 0;
      }

      n += n2;
    }

    return n;
  }

  static int nBulletproofMaxAmountBase(
      {required int lSize, required int rSize, required int maxOuts}) {
    const int extraBits = 4;

    if (lSize < 6) {
      throw const MoneroCryptoException(
          "Invalid bulletproof L size: L size must be at least 6.");
    }
    if (lSize != rSize) {
      throw const MoneroCryptoException(
          "Mismatched bulletproof L/R size: L size and R_size must be equal.");
    }
    if ((1 << extraBits) != maxOuts) {
      throw const MoneroCryptoException(
          "log2(max_outputs) is out of date: max_outputs must be 2^extraBits.");
    }
    if (lSize > 6 + extraBits) {
      throw const MoneroCryptoException(
          "Invalid bulletproof L size: L_size must not exceed 6 + extraBits.");
    }
    return 1 << (lSize - 6);
  }

  static int _nBulletproofMaxAmounts(Bulletproof proof) {
    return nBulletproofMaxAmountBase(
        lSize: proof.l.length,
        rSize: proof.r.length,
        maxOuts: MoneroNetworkConst.bulletproofMaxOutputs);
  }

  static int _nBulletproofPlusMaxAmounts(BulletproofPlus proof) {
    return nBulletproofMaxAmountBase(
        lSize: proof.l.length,
        rSize: proof.r.length,
        maxOuts: MoneroNetworkConst.bulletproofPlussMaxOutputs);
  }

  static int nBulletproofMaxAmounts(List<Bulletproof> proofs) {
    int n = 0;
    for (final proof in proofs) {
      final int n2 = _nBulletproofMaxAmounts(proof);
      if (n2 >= (1 << 32) - 1 - n) {
        throw const MoneroCryptoException(
            "Invalid number of bulletproofs: sum of amounts exceeds uint32 max value.");
      }
      if (n2 == 0) {
        return 0;
      }
      n += n2;
    }
    return n;
  }

  static int nBulletproofPlusMaxAmounts(List<BulletproofPlus> proofs) {
    int n = 0;
    for (final proof in proofs) {
      final int n2 = _nBulletproofPlusMaxAmounts(proof);
      if (n2 >= (1 << 32) - 1 - n) {
        throw const MoneroCryptoException(
            "Invalid number of bulletproofs: sum of amounts exceeds uint32 max value.");
      }
      if (n2 == 0) {
        return 0;
      }
      n += n2;
    }
    return n;
  }

  static RCTSignature<S, P>
      buildSignature<S extends RCTSignatureBase, P extends RctSigPrunable>({
    required RCTType type,
    required List<EcdhInfo> ecdh,
    required BigInt txnFee,
    required List<CtKey> outPk,
    required RctKey message,
    required List<List<CtKey>> mixRing,
    required List<RangeSig> rangeSig,
    required List<MgSig> mgs,
    required List<BulletproofPlus> bulletProofPlus,
    required List<Bulletproof> bulletProof,
    required List<Clsag> clsag,
    required KeyV pseudoOuts,
  }) {
    RCTSignatureBase base;
    RctSigPrunable prunable;
    switch (type) {
      case RCTType.rctTypeFull:
        base = RCTFull(
            ecdhInfo: ecdh.cast<EcdhInfoV1>(),
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableRangeSigs(rangeSig: rangeSig, mgs: mgs);
        break;
      case RCTType.rctTypeBulletproofPlus:
        base = RCTBulletproofPlus(
            ecdhInfo: ecdh.cast<EcdhInfoV2>(),
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableBulletproofPlus(
            bulletproofPlus: bulletProofPlus,
            clsag: clsag,
            pseudoOuts: pseudoOuts);
        break;
      case RCTType.rctTypeBulletproof2:
        base = RCTBulletproof2(
            ecdhInfo: ecdh.cast<EcdhInfoV2>(),
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableBulletproof2(
            bulletproof: bulletProof, mgs: mgs, pseudoOuts: pseudoOuts);
        break;
      case RCTType.rctTypeBulletproof:
        base = RCTBulletproof(
            ecdhInfo: ecdh.cast<EcdhInfoV1>(),
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableBulletproof(
            bulletproof: bulletProof, mgs: mgs, pseudoOuts: pseudoOuts);
        break;
      case RCTType.rctTypeCLSAG:
        base = RCTCLSAG(
            ecdhInfo: ecdh.cast<EcdhInfoV2>(),
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableCLSAG(
            bulletproof: bulletProof, clsag: clsag, pseudoOuts: pseudoOuts);
        break;
      case RCTType.rctTypeSimple:
        base = RCTSimple(
            ecdhInfo: ecdh.cast<EcdhInfoV1>(),
            pseudoOuts: pseudoOuts,
            txnFee: txnFee,
            outPk: outPk,
            message: message,
            mixRing: mixRing);
        prunable = RctSigPrunableRangeSigs(mgs: mgs, rangeSig: rangeSig);
        break;
      default:
        throw const MoneroCryptoException("Invalid rct type.");
    }
    if (base is! S || prunable is! P) {
      throw const MoneroCryptoException("RCTSignature casting failed.");
    }
    return RCTSignature<S, P>(signature: base, rctSigPrunable: prunable);
  }

  static int nBulletproofPlusAmounts(List<BulletproofPlus> proofs) {
    int n = 0;

    for (final BulletproofPlus proof in proofs) {
      final int n2 = nBulletproofPlusAmount(proof);

      if (n2 >= mask32 - n) {
        throw const MoneroCryptoException("Invalid number of bulletproofs");
      }

      if (n2 == 0) {
        return 0;
      }

      n += n2;
    }

    return n;
  }

  static RCTSignature<S, P>
      genRctSimple_<S extends RCTSignatureBase, P extends RctSigPrunable>(
          {required RctKey message,
          required CtKeyV inSk,
          required CtKeyV inPk,
          required KeyV destinations,
          required List<BigInt> inamounts,
          required List<BigInt> outamounts,
          required KeyV amountKeys,
          required BigInt txnFee,
          required int mixin,
          bool createLinkable = true}) {
    final List<int> index = List.filled(inPk.length, 0);
    final CtKeyM mixRing = List.generate(
        inPk.length,
        (_) => List.generate(
            mixin + 1, (_) => CtKey(dest: RCT.zero(), mask: RCT.zero())));
    final CtKeyV outSk = List.generate(
        destinations.length, (_) => CtKey(dest: RCT.zero(), mask: RCT.zero()));
    for (int i = 0; i < inPk.length; ++i) {
      index[i] = _generateKeySimple(mixRing[i], inPk[i], mixin);
    }
    return genRctSimple(
        message: message,
        inSk: inSk,
        destinations: destinations,
        inamounts: inamounts,
        outamounts: outamounts,
        txnFee: txnFee,
        mixRing: mixRing,
        amountKeys: amountKeys,
        index: index,
        outSk: outSk,
        createLinkable: createLinkable);
  }

  static int _generateKeySimple(CtKeyV mixRing, CtKey inPk, int mixin) {
    final int index = RCT.randXmrAmount(BigInt.from(mixin)).toInt();
    int i = 0;
    for (i = 0; i <= mixin; i++) {
      if (i != index) {
        mixRing[i] = _generateRandomKey();
      } else {
        mixRing[i] = inPk;
      }
    }
    return index;
  }

  static (BigInt, RctKey) decodeRct(
      {required RCTSignature sig,
      required RctKey secretKey,
      required int outputIndex}) {
    if (outputIndex >= sig.signature.ecdhInfo.length) {
      throw const MoneroCryptoException("Bad index");
    }
    if (sig.signature.outPk.length != sig.signature.ecdhInfo.length) {
      throw const MoneroCryptoException(
          "Mismatched sizes of publickey and ECDH");
    }
    final ecdh = sig.signature.ecdhInfo[outputIndex];
    final result = RCT.ecdhDecode(ecdh: ecdh, sharedSec: secretKey);
    final mask = RCT.zero();
    CryptoOps.scFill(mask, result.mask);
    final RctKey amount = result.amount;
    final RctKey c = sig.signature.outPk[outputIndex].mask;
    final RctKey t = RCT.zero();
    if (CryptoOps.scCheck(mask) != 0) {
      throw const MoneroCryptoException("bad ECDH mask.");
    }
    if (CryptoOps.scCheck(amount) != 0) {
      throw const MoneroCryptoException("bad ECDH amount.");
    }

    RCT.addKeys2(t, mask, amount, RCTConst.h);
    if (!BytesUtils.bytesEqual(c, t)) {
      throw const MoneroCryptoException(
          "amount decoded incorrectly, will be unable to spend");
    }
    final bAmount = RCT.h2d(amount);
    return (bAmount, mask);
  }

  static (BigInt, RctKey)? decodeRct_(
      {required RCTSignature sig,
      required RctKey secretKey,
      required int outputIndex}) {
    try {
      return decodeRct(
          sig: sig, secretKey: secretKey, outputIndex: outputIndex);
    } on MoneroCryptoException {
      return null;
    }
  }

  static int weightClawBack(RCTSignature signature) {
    final type = signature.signature.type;
    if (signature.rctSigPrunable == null) {
      throw const MoneroCryptoException(
          "signature prunable required for calculate claw back.");
    }
    if (!type.isBulletproof && !type.isBulletproofPlus) {
      return 0;
    }
    int paddedOutputs = 0;
    if (type.isBulletproofPlus) {
      paddedOutputs = nBulletproofPlusMaxAmounts(signature.rctSigPrunable!
          .cast<RctSigPrunableBulletproofPlus>()
          .bulletproofPlus);
    } else {
      paddedOutputs = nBulletproofMaxAmounts(
          signature.rctSigPrunable!.cast<BulletproofPrunable>().bulletproof);
    }
    if (paddedOutputs <= 2) return 0;
    final isBpp = type.isBulletproofPlus;
    final int bpBase = (32 * ((isBpp ? 6 : 9) + 7 * 2)) ~/ 2;

    int nlr = 0;
    while ((1 << nlr) < paddedOutputs) {
      ++nlr;
    }
    nlr += 6;
    final int bpSize = 32 * ((isBpp ? 6 : 9) + 2 * nlr);
    final int bpClawback = (bpBase * paddedOutputs - bpSize) * 4 ~/ 5;
    return bpClawback;
  }
}
