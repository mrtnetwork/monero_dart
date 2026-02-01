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
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class CLSAGUtils {
  static (RctKey, RctKey, RctKey) _clsagPrepare(
    RctKey p,
    RctKey z,
    RctKey H,
    RctKey a,
    RctKey aG,
  ) {
    RCT.skpkGen(a, aG);
    final aH = RCT.scalarmultKey(H, a);
    final I = RCT.scalarmultKey(H, p);
    final D = RCT.scalarmultKey(H, z);
    return (aH, I, D);
  }

  static void _clsagSign(
    RctKey c,
    RctKey a,
    RctKey p,
    RctKey z,
    RctKey muP,
    RctKey muC,
    RctKey s,
  ) {
    final RctKey s0PmuP = RCT.zero();
    CryptoOps.scMul(s0PmuP, muP, p);
    final RctKey s0AddZMuC = RCT.zero();
    CryptoOps.scMulAdd(s0AddZMuC, muC, z, s0PmuP);
    CryptoOps.scMulSub(s, c, s0AddZMuC, a);
  }

  static Clsag generate(
    RctKey message,
    KeyV P,
    RctKey p,
    KeyV C,
    RctKey z,
    KeyV cNonZero,
    RctKey cOffset,
    int l,
  ) {
    final int n = P.length;
    if (n != C.length) {
      throw const MoneroCryptoException(
        "Signing and commitment key vector sizes must match!",
      );
    }
    if (n != cNonZero.length) {
      throw const MoneroCryptoException(
        "Signing and commitment key vector sizes must match!",
      );
    }
    if (l >= n) {
      throw const MoneroCryptoException("Signing index out of range!");
    }
    final RctKey H = RCT.hashToP3Bytes(P[l]);

    // Initial values
    final RctKey a = RCT.zero();
    final RctKey aG = RCT.zero();

    RctKey sigC1 = RCT.zero();

    final r = _clsagPrepare(p, z, H, a, aG);
    final RctKey aH = r.$1;
    final RctKey sigI = r.$2;
    final RctKey D = r.$3;
    final List<EDPoint> iPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(sigI));
    final List<EDPoint> dPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(D));

    final RctKey sigD = RCT.scalarmultKeyVar(D, RCTConst.invEight);

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
    muP = RCT.hashToScalarKeysVar(muPtoHash);
    muC = RCT.hashToScalarKeysVar(muCtoHash);
    final KeyV cToHash = List.generate(2 * n + 5, (_) => RCT.zero());
    cToHash[0] = RCT.strToKey(RCTConst.cslagHashKeyRound);
    for (int i = 1; i < n + 1; ++i) {
      cToHash[i] = P[i - 1];
      cToHash[i + n] = cNonZero[i - 1];
    }
    cToHash[2 * n + 1] = cOffset;
    cToHash[2 * n + 2] = message;

    cToHash[2 * n + 3] = aG;
    cToHash[2 * n + 4] = aH;
    RctKey c = RCT.hashToScalarKeysVar(cToHash);
    int i;
    i = (l + 1) % n;
    if (i == 0) {
      sigC1 = c.clone();
    }
    final KeyV sigS = List.generate(n, (_) => RCT.zero());
    RctKey cNew = RCT.zero();

    while (i != l) {
      sigS[i] = RCT.skGenVar();
      cNew = RCT.zero();
      final cP = Ed25519Utils.scMulVar(muP, c);
      final cC = Ed25519Utils.scMulVar(muC, c);
      final pPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(P[i]));
      final cPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(C[i]));
      final L = RCT.addKeysAGbBcCVar(sigS[i], cP, pPrecomp, cC, cPrecomp);
      final hiP3 = RCT.hashToPoint(P[i]);
      final hPrecomp = CryptoOps.geDsmPrecompVar(hiP3);
      final R = RCT.addKeysAAbBcCVar(
        sigS[i],
        hPrecomp,
        cP,
        iPrecomp,
        cC,
        dPrecomp,
      );

      cToHash[2 * n + 3] = L;
      cToHash[2 * n + 4] = R;
      cNew = RCT.hashToScalarKeysVar(cToHash);
      c = cNew.clone();
      i = (i + 1) % n;
      if (i == 0) sigC1 = c.clone();
    }
    _clsagSign(c, a, p, z, muP, muC, sigS[l]);
    return Clsag(s: sigS, c1: sigC1, d: sigD, i: sigI);
  }

  static bool verify(RctKey message, Clsag sig, CtKeyV pubs, RctKey cOffset) {
    try {
      final int n = pubs.length;
      if (n < 1) {
        throw const MoneroCryptoException("Empty pubs");
      }
      if (n != sig.s.length) {
        throw const MoneroCryptoException(
          "Signature scalar vector is the wrong size!",
        );
      }

      for (int i = 0; i < n; i++) {
        if (!Ed25519Utils.scCheckVar(sig.s[i])) {
          throw const MoneroCryptoException("Bad signature scalar!");
        }
      }

      if (!Ed25519Utils.scCheckVar(sig.c1)) {
        throw const MoneroCryptoException("Bad signature commitment!");
      }

      if (sig.i == null ||
          BytesUtils.bytesEqual(sig.i, RCT.identity(clone: false))) {
        throw const MoneroCryptoException("Bad key image!");
      }
      final EDPoint cOffsetCached = RCT.asPoint(cOffset);
      RctKey c = sig.c1.clone();
      final d8 = RCT.scalarmult8PointVar(sig.d);
      if (d8.isZero()) {
        throw const MoneroCryptoException("Bad auxiliary key image!");
      }
      if (sig.i == null) {
        throw const MoneroCryptoException("I is required for verification.");
      }
      final iPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(sig.i!));
      final dPrecomp = CryptoOps.geDsmPrecompVar(d8);
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
      RctKey cNew = RCT.zero();
      int i = 0;
      while (i < n) {
        final cP = Ed25519Utils.scMulVar(muP, c);
        final cC = Ed25519Utils.scMulVar(muC, c);
        final pPrecomp = CryptoOps.geDsmPrecompVar(RCT.asPoint(pubs[i].dest));
        EDPoint tempP3 = RCT.asPoint(pubs[i].mask);
        tempP3 = tempP3 + (-cOffsetCached);
        final cPrecomp = CryptoOps.geDsmPrecompVar(tempP3);

        final L = RCT.addKeysAGbBcCVar(sig.s[i], cP, pPrecomp, cC, cPrecomp);

        final hash8P3 = RCT.hashToPoint(pubs[i].dest);
        final hashPrecomp = CryptoOps.geDsmPrecompVar(hash8P3);
        final R = RCT.addKeysAAbBcCVar(
          sig.s[i],
          hashPrecomp,
          cP,
          iPrecomp,
          cC,
          dPrecomp,
        );

        cToHash[2 * n + 3] = L;
        cToHash[2 * n + 4] = R;
        cNew = RCT.hashToScalarKeys(cToHash);
        if (BytesUtils.bytesEqual(cNew, RCT.zero(clone: false))) {
          throw const MoneroCryptoException("Bad signature hash");
        }
        c = cNew.clone();

        i = i + 1;
      }
      cNew = Ed25519Utils.scSubVar(c, sig.c1);
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
      i: RCT.identity(clone: false),
    );
  }

  static Clsag prove(
    RctKey message,
    CtKeyV pubs,
    CtKey inSk,
    RctKey a,
    RctKey cout,
    int index,
  ) {
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
      final RctKey tmp = RCT.subKeysVar(k.mask, cout);
      C.add(tmp);
    }
    sk[0] = inSk.dest.clone();
    CryptoOps.scSub(sk[1], inSk.mask, a);
    final Clsag result = generate(
      message,
      P,
      sk[0],
      C,
      sk[1],
      cNonZero,
      cout,
      index,
    );
    return result;
  }
}
