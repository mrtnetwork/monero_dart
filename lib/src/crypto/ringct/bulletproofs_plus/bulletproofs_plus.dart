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
import 'package:monero_dart/src/crypto/models/bullet_proof_data.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/cached/cached_exponet.dart';
import 'package:monero_dart/src/monero_base.dart';

class BulletproofsPlusGenerator {
  static const int maxN = 64;
  static const int maxM = 16;

  // Live-object scalar constants (decoded once): the hot path below runs
  // entirely on `Ed25519Fr`/points — bytes only cross at entry (inputs),
  // transcript hashing, multiexp digits, and proof assembly.
  static final Ed25519Fr _frOne = Ed25519Fr.fromBytes(RCTConst.i);
  static final Ed25519Fr _frInvEight = Ed25519Fr.fromBytes(RCTConst.invEight);
  static final Ed25519Fr _frTwo = Ed25519Fr.fromBytes(RCTConst.two);
  static final Ed25519Fr _frMinusOne = Ed25519Fr.fromBytes(RCTConst.minusOne);
  static final Ed25519Fr _frMinusInvEight = Ed25519Fr.fromBytes(
    RCTConst.minusInvEight,
  );
  static final Ed25519Fr _fr264m1 = Ed25519Fr.fromBytes(
    RCTConst.twoSixtyFourMinusOne,
  );

  static EdwardsLimbPoint _getExponentBytes({
    required RctKey base,
    required int idx,
  }) {
    if (idx >= 0 && idx < cachedExponet.length) {
      return cachedExponet[idx];
    }
    final indexBytes = MoneroLayoutConst.varintInt().serialize(idx);
    final hash = QuickCrypto.keccak256Hash([
      ...base,
      ...RCTConst.bulletproofPlusHashKey,
      ...indexBytes,
    ]);

    return RCT.asPoint(RCT.hashToP3Bytes(hash));
  }

  static EdwardsLimbPoint _getGiP3Bytes(int index) {
    return _getExponentBytes(base: RCTConst.h, idx: index * 2 + 1);
  }

  static EdwardsLimbPoint _getHiP3Bytes(int index) {
    return _getExponentBytes(base: RCTConst.h, idx: index * 2);
  }

  static RctKey _multiexp({
    required List<MultiexpData> data,
    int higiSize = 0,
  }) {
    if (higiSize > 0) {
      if (higiSize <= 232 && data.length == higiSize) {
        return Multiexp.straus(data: data, step: 0).toBytes();
      }
      return Multiexp.pippenger(
        data: data,
        cacheSize: higiSize,
        c: Multiexp.getPippengerC(data.length),
      ).toBytes();
    }
    if (data.length <= 95) {
      return Multiexp.straus(data: data).toBytes();
    }
    return Multiexp.pippenger(
      data: data,
      cacheSize: 0,
      c: Multiexp.getPippengerC(data.length),
    ).toBytes();
  }

  static RctKey _vectorExponentVar({
    required List<Ed25519Fr> a,
    required List<Ed25519Fr> b,
  }) {
    if (a.length != b.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible sizes of a and b");
    }
    if (a.length > maxN * maxM) {
      throw BuError(MoneroErrorType.crypto, "Incompatible sizes of a and maxN");
    }
    final List<MultiexpData> multiexpDataVar = [];
    for (int i = 0; i < a.length; i++) {
      multiexpDataVar.add(
        MultiexpData(scalar: a[i].toBytes(), point: _getGiP3Bytes(i)),
      );
      multiexpDataVar.add(
        MultiexpData(scalar: b[i].toBytes(), point: _getHiP3Bytes(i)),
      );
    }
    return _multiexp(data: multiexpDataVar, higiSize: a.length * 2);
  }

  static RctKey _computeLRVar(
    int size,
    Ed25519Fr y,
    List<EdwardsLimbPoint> G,
    int g0,
    List<EdwardsLimbPoint> H,
    int h0,
    List<Ed25519Fr> a,
    int a0,
    List<Ed25519Fr> b,
    int b0,
    Ed25519Fr c,
    Ed25519Fr d,
    EdwardsLimbPoint hPoint,
    EdwardsLimbPoint gPoint,
  ) {
    if (size + g0 > G.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible size for G");
    }
    if (size + h0 > H.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible size for H");
    }
    if (size + a0 > a.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible size for a");
    }
    if (size + b0 > b.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible size for b");
    }
    if (size > maxN * maxM) {
      throw BuError(MoneroErrorType.crypto, "size is too large");
    }
    final List<MultiexpData?> multiexpData = List.filled(size * 2 + 2, null);
    for (int i = 0; i < size; ++i) {
      final scalar =
          EdwardsLimbOps.scMulField(
            EdwardsLimbOps.scMulField(a[a0 + i], y),
            _frInvEight,
          ).toBytes();
      multiexpData[i * 2] = MultiexpData(scalar: scalar, point: G[g0 + i]);
      final scalar2 =
          EdwardsLimbOps.scMulField(b[b0 + i], _frInvEight).toBytes();
      multiexpData[i * 2 + 1] = MultiexpData(scalar: scalar2, point: H[h0 + i]);
    }
    final scBytes = EdwardsLimbOps.scMulField(c, _frInvEight).toBytes();
    multiexpData[2 * size] = MultiexpData(scalar: scBytes, point: hPoint);
    final scBytes2 = EdwardsLimbOps.scMulField(d, _frInvEight).toBytes();
    multiexpData[2 * size + 1] = MultiexpData(scalar: scBytes2, point: gPoint);
    return _multiexp(data: multiexpData.cast(), higiSize: 0);
  }

  static List<Ed25519Fr> _vectorOfScalarPowers(Ed25519Fr x, int n) {
    if (n <= 0) {
      throw BuError(MoneroErrorType.crypto, "Need n > 0");
    }
    final res = List<Ed25519Fr>.generate(n, (_) => Ed25519Fr.zero);
    res[0] = _frOne;
    if (n == 1) {
      return res;
    }
    res[1] = x;
    for (int i = 2; i < n; ++i) {
      res[i] = EdwardsLimbOps.scMulField(res[i - 1], x);
    }
    return res;
  }

  static Ed25519Fr _sumOfEvenPowers(Ed25519Fr x, int n) {
    if ((n & (n - 1)) != 0) {
      throw BuError(MoneroErrorType.crypto, "Need n to be a power of 2");
    }
    if (n == 0) {
      throw BuError(MoneroErrorType.crypto, "Need n > 0");
    }

    Ed25519Fr x1 = x;
    x1 = EdwardsLimbOps.scMulField(x1, x1);

    Ed25519Fr res = x1;
    while (n > 2) {
      res = EdwardsLimbOps.scMulAddField(x1, res, res);
      x1 = EdwardsLimbOps.scMulField(x1, x1);
      n ~/= 2;
    }

    return res;
  }

  static Ed25519Fr _sumOfScalarPowers(Ed25519Fr x, int n) {
    if (n == 0) {
      throw BuError(MoneroErrorType.crypto, "Need n > 0");
    }

    Ed25519Fr res = _frOne;
    if (n == 1) {
      return x;
    }

    n += 1;
    Ed25519Fr x1 = x;

    final bool isPowerOf2 = (n & (n - 1)) == 0;
    if (isPowerOf2) {
      res = EdwardsLimbOps.scAddField(res, x1);
      while (n > 2) {
        x1 = EdwardsLimbOps.scMulField(x1, x1);
        res = EdwardsLimbOps.scMulAddField(x1, res, res);
        n ~/= 2;
      }
    } else {
      Ed25519Fr prev = x1;
      for (int i = 1; i < n; ++i) {
        if (i > 1) prev = EdwardsLimbOps.scMulField(prev, x1);
        res = EdwardsLimbOps.scAddField(res, prev);
      }
    }
    res = EdwardsLimbOps.scSubField(res, _frOne);
    return res;
  }

  static Ed25519Fr _weightedInnerProduct(
    List<Ed25519Fr> a,
    List<Ed25519Fr> b,
    Ed25519Fr y,
  ) {
    if (a.length != b.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible sizes of a and b");
    }
    Ed25519Fr res = Ed25519Fr.zero;
    Ed25519Fr yPower = _frOne;
    for (int i = 0; i < a.length; ++i) {
      final temp = EdwardsLimbOps.scMulField(a[i], b[i]);
      yPower = EdwardsLimbOps.scMulField(yPower, y);
      res = EdwardsLimbOps.scMulAddField(temp, yPower, res);
    }
    return res;
  }

  static List<EdwardsLimbPoint> _hadamardFoldVar(
    List<EdwardsLimbPoint> v,
    Ed25519Fr a,
    Ed25519Fr b,
  ) {
    if (v.length.isOdd) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Vector size should be even",
      );
    }
    // Pure-point fold: tables and result stay live `EdwardsLimbPoint`s —
    // no bytes encode/decode per element (was ~10x slower through bytes).
    final vC = v.clone();
    final int size = v.length ~/ 2;
    final aBytes = a.toBytes();
    final bBytes = b.toBytes();
    for (int n = 0; n < size; ++n) {
      vC[n] = EdwardsLimbOps.doubleScalarMultPrecompPoints(
        aBytes,
        EdwardsLimbOps.dsmPrecompPoints(v[n]),
        bBytes,
        EdwardsLimbOps.dsmPrecompPoints(v[size + n]),
      );
    }
    return vC.sublist(0, size);
  }

  static List<Ed25519Fr> _vectorAddComponentwise(
    List<Ed25519Fr> a,
    List<Ed25519Fr> b,
  ) {
    if (a.length != b.length) {
      throw BuError(MoneroErrorType.crypto, "Incompatible sizes of a and b");
    }
    final res = List<Ed25519Fr>.generate(a.length, (_) => Ed25519Fr.zero);
    for (int i = 0; i < a.length; ++i) {
      res[i] = EdwardsLimbOps.scAddField(a[i], b[i]);
    }
    return res;
  }

  static List<Ed25519Fr> _vectorAdd(List<Ed25519Fr> a, Ed25519Fr b) {
    final res = List<Ed25519Fr>.generate(a.length, (_) => Ed25519Fr.zero);
    for (int i = 0; i < a.length; ++i) {
      res[i] = EdwardsLimbOps.scAddField(a[i], b);
    }
    return res;
  }

  static List<Ed25519Fr> _vectorSubtract(List<Ed25519Fr> a, Ed25519Fr b) {
    final res = List<Ed25519Fr>.generate(a.length, (_) => Ed25519Fr.zero);
    for (int i = 0; i < a.length; ++i) {
      res[i] = EdwardsLimbOps.scSubField(a[i], b);
    }
    return res;
  }

  static List<Ed25519Fr> _vectorScalar(List<Ed25519Fr> a, Ed25519Fr x) {
    final res = List<Ed25519Fr>.generate(a.length, (_) => Ed25519Fr.zero);
    for (int i = 0; i < a.length; ++i) {
      res[i] = EdwardsLimbOps.scMulField(a[i], x);
    }
    return res;
  }

  static Ed25519Fr _sm(Ed25519Fr y, int n, Ed25519Fr x) {
    while (n-- != 0) {
      y = EdwardsLimbOps.scMulField(y, y);
    }
    y = EdwardsLimbOps.scMulField(y, x);
    return y;
  }

  static Ed25519Fr _invert(Ed25519Fr x) {
    if (x == Ed25519Fr.zero) {
      throw BuError(DefaultErrorType.invalidArgument, "Cannot invert zero.");
    }

    /// Ed25519Utils
    final Ed25519Fr a1 = x;
    final Ed25519Fr a10 = EdwardsLimbOps.scMulField(a1, a1);
    final Ed25519Fr a100 = EdwardsLimbOps.scMulField(a10, a10);
    final Ed25519Fr a11 = EdwardsLimbOps.scMulField(a10, a1);
    final Ed25519Fr a101 = EdwardsLimbOps.scMulField(a10, a11);
    final Ed25519Fr a111 = EdwardsLimbOps.scMulField(a10, a101);
    final Ed25519Fr a1001 = EdwardsLimbOps.scMulField(a10, a111);
    final Ed25519Fr a1011 = EdwardsLimbOps.scMulField(a10, a1001);
    final Ed25519Fr a1111 = EdwardsLimbOps.scMulField(a100, a1011);

    Ed25519Fr inv = EdwardsLimbOps.scMulField(a1111, a1);

    inv = _sm(inv, 123 + 3, a101);
    inv = _sm(inv, 2 + 2, a11);
    inv = _sm(inv, 1 + 4, a1111);
    inv = _sm(inv, 1 + 4, a1111);
    inv = _sm(inv, 4, a1001);
    inv = _sm(inv, 2, a11);
    inv = _sm(inv, 1 + 4, a1111);
    inv = _sm(inv, 1 + 3, a101);
    inv = _sm(inv, 3 + 3, a101);
    inv = _sm(inv, 3, a111);
    inv = _sm(inv, 1 + 4, a1111);
    inv = _sm(inv, 2 + 3, a111);
    inv = _sm(inv, 2 + 2, a11);
    inv = _sm(inv, 1 + 4, a1011);
    inv = _sm(inv, 2 + 4, a1011);
    inv = _sm(inv, 6 + 4, a1001);
    inv = _sm(inv, 2 + 2, a11);
    inv = _sm(inv, 3 + 2, a11);
    inv = _sm(inv, 3 + 2, a11);
    inv = _sm(inv, 1 + 4, a1001);
    inv = _sm(inv, 1 + 3, a111);
    inv = _sm(inv, 2 + 4, a1111);
    inv = _sm(inv, 1 + 4, a1011);
    inv = _sm(inv, 3, a101);
    inv = _sm(inv, 2 + 4, a1111);
    inv = _sm(inv, 3, a101);
    inv = _sm(inv, 1 + 2, a11);

    return inv;
  }

  static List<Ed25519Fr> _invertBatchVar(List<Ed25519Fr> x) {
    final List<Ed25519Fr> scratch = [];

    Ed25519Fr acc = _frOne;
    for (int n = 0; n < x.length; ++n) {
      if (x[n] == Ed25519Fr.zero) {
        throw BuError(DefaultErrorType.invalidArgument, "Cannot invert zero.");
      }
      scratch.add(acc);
      if (n == 0) {
        acc = x[0];
      } else {
        acc = EdwardsLimbOps.scMulField(acc, x[n]);
      }
    }

    acc = _invert(acc);
    for (int i = x.length; i-- > 0;) {
      final tmp = EdwardsLimbOps.scMulField(acc, x[i]);
      x[i] = EdwardsLimbOps.scMulField(acc, scratch[i]);
      acc = tmp;
    }
    return x;
  }

  static RctKey _transcriptUpdateTwo(RctKey transcript, RctKey update) {
    return RCT.hashToScalar([...transcript, ...update]);
  }

  static RctKey _transcriptUpdateThree(
    RctKey transcript,
    RctKey update0,
    RctKey update1,
  ) {
    return RCT.hashToScalar([...transcript, ...update0, ...update1]);
  }

  static bool _isReduced(RctKey scalar) {
    return EdwardsLimbOps.scCheck(scalar);
  }

  static BulletproofPlus bulletproofPlusPROVE(KeyV sv, KeyV gamma) {
    try {
      return _bulletproofPlusPROVE(sv, gamma);
    } catch (e) {
      throw BuError(
        DefaultErrorType.internal,
        "Failed to generate Bulletproof Plus.",
        details: {"error": e.toString()},
      );
    }
  }

  static BulletproofPlus _bulletproofPlusPROVE(KeyV sv, KeyV gamma) {
    if (sv.length != gamma.length) {
      throw BuError(
        MoneroErrorType.crypto,
        "Incompatible sizes of sv and gamma",
      );
    }
    for (final i in sv) {
      if (!_isReduced(i)) {
        throw BuError(DefaultErrorType.invalidArgument, "Invalid sv input");
      }
    }
    for (final i in gamma) {
      if (!_isReduced(i)) {
        throw BuError(DefaultErrorType.invalidArgument, "Invalid gamma input");
      }
    }
    final hPoint = RCT.asPoint(RCTConst.h);
    final gPoint = RCT.asPoint(RCTConst.g);
    const int logN = 6;
    const int N = 1 << logN;
    int M = 0, logM = 0;
    while ((M = 1 << logM) <= maxM && M < sv.length) {
      logM++;
    }
    if (M > maxM) {
      throw BuError(MoneroErrorType.crypto, "sv/gamma are too large");
    }
    final int logMN = logM + logN;
    final int mn = M * N;
    final KeyV V = [];
    final svFr = sv.map(Ed25519Fr.fromBytes).toList();
    final gammaFr = gamma.map(Ed25519Fr.fromBytes).toList();
    final aL = List<Ed25519Fr>.generate(mn, (_) => Ed25519Fr.zero);
    final aR = List<Ed25519Fr>.generate(mn, (_) => Ed25519Fr.zero);
    final aL8 = List<Ed25519Fr>.generate(mn, (_) => Ed25519Fr.zero);
    final aR8 = List<Ed25519Fr>.generate(mn, (_) => Ed25519Fr.zero);
    for (int i = 0; i < sv.length; ++i) {
      final gamma8 = EdwardsLimbOps.scMulField(gammaFr[i], _frInvEight);
      final sv8 = EdwardsLimbOps.scMulField(svFr[i], _frInvEight);
      V.add(RCT.addKeys2(gamma8.toBytes(), sv8.toBytes(), RCTConst.h));
    }

    for (int j = 0; j < M; ++j) {
      for (int i = N; i-- > 0;) {
        if (j < sv.length && (sv[j][i ~/ 8] & (1 << (i % 8))) != 0) {
          aL[j * N + i] = _frOne;
          aL8[j * N + i] = _frInvEight;
          aR[j * N + i] = aR8[j * N + i] = Ed25519Fr.zero;
        } else {
          aL[j * N + i] = aL8[j * N + i] = Ed25519Fr.zero;
          aR[j * N + i] = _frMinusOne;
          aR8[j * N + i] = _frMinusInvEight;
        }
      }
    }
    BulletproofPlus tryAgain() {
      RctKey transcript = RCTConst.bulletproofPlusinitialTranscript.clone();
      transcript = _transcriptUpdateTwo(transcript, RCT.hashToScalarKeys(V));
      final alpha = Ed25519Fr.fromBytes(RCT.skGen());
      final RctKey preA = _vectorExponentVar(a: aL8, b: aR8);
      final tempAlpha = EdwardsLimbOps.scMulField(alpha, _frInvEight);
      final RctKey A = RCT.addKeys(
        preA,
        RCT.scalarmultBase(tempAlpha.toBytes()),
      );
      final y = Ed25519Fr.fromBytes(_transcriptUpdateTwo(transcript, A));
      if (y == Ed25519Fr.zero) {
        return tryAgain();
      }
      transcript = RCT.hashToScalar(y.toBytes());
      final transcriptFr = Ed25519Fr.fromBytes(transcript);
      if (transcriptFr == Ed25519Fr.zero) {
        return tryAgain();
      }
      final zSquared = EdwardsLimbOps.scMulField(transcriptFr, transcriptFr);
      final d = List.generate(mn, (_) => Ed25519Fr.zero);
      d[0] = zSquared;
      for (int i = 1; i < N; i++) {
        d[i] = EdwardsLimbOps.scMulField(d[i - 1], _frTwo);
      }

      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          d[j * N + i] = EdwardsLimbOps.scMulField(
            d[(j - 1) * N + i],
            zSquared,
          );
        }
      }

      final yPowers = _vectorOfScalarPowers(y, mn + 2);

      final aL1 = _vectorSubtract(aL, transcriptFr);

      List<Ed25519Fr> aR1 = _vectorAdd(aR, transcriptFr);

      final dy = List.generate(mn, (i) => Ed25519Fr.zero);

      for (int i = 0; i < mn; i++) {
        dy[i] = EdwardsLimbOps.scMulField(d[i], yPowers[mn - i]);
      }

      aR1 = _vectorAddComponentwise(aR1, dy);

      Ed25519Fr alpha1 = alpha;
      Ed25519Fr temp = _frOne;
      Ed25519Fr temp2 = Ed25519Fr.zero;
      for (int j = 0; j < sv.length; j++) {
        temp = EdwardsLimbOps.scMulField(temp, zSquared);
        temp2 = EdwardsLimbOps.scMulField(yPowers[mn + 1], temp);
        alpha1 = EdwardsLimbOps.scMulAddField(temp2, gammaFr[j], alpha1);
      }

      int nprime = mn;
      List<EdwardsLimbPoint> gPrime = [];
      List<EdwardsLimbPoint> hPrime = [];
      List<Ed25519Fr> aprime = List.generate(mn, (_) => Ed25519Fr.zero);
      List<Ed25519Fr> bprime = List.generate(mn, (_) => Ed25519Fr.zero);
      final Ed25519Fr yinv = _invert(y);
      final yinvpow = List.generate(mn, (_) => Ed25519Fr.zero);
      yinvpow[0] = _frOne;
      for (int i = 0; i < mn; ++i) {
        gPrime.add(_getGiP3Bytes(i));
        hPrime.add(_getHiP3Bytes(i));
        if (i > 0) {
          yinvpow[i] = EdwardsLimbOps.scMulField(yinvpow[i - 1], yinv);
        }
        aprime[i] = aL1[i];
        bprime[i] = aR1[i];
      }
      final KeyV L = List.generate(logMN, (_) => RCT.zero());
      final KeyV R = List.generate(logMN, (_) => RCT.zero());

      int round = 0;
      // Inner-product rounds
      while (nprime > 1) {
        nprime ~/= 2;
        final cL = _weightedInnerProduct(
          aprime.sublist(0, nprime),
          bprime.sublist(nprime),
          y,
        );
        final cR = _weightedInnerProduct(
          _vectorScalar(aprime.sublist(nprime), yPowers[nprime]),
          bprime.sublist(0, nprime),
          y,
        );
        final dL = Ed25519Fr.fromBytes(RCT.skGen());
        final dR = Ed25519Fr.fromBytes(RCT.skGen());
        L[round] = _computeLRVar(
          nprime,
          yinvpow[nprime],
          gPrime,
          nprime,
          hPrime,
          0,
          aprime,
          0,
          bprime,
          nprime,
          cL,
          dL,
          hPoint,
          gPoint,
        );
        R[round] = _computeLRVar(
          nprime,
          yPowers[nprime],
          gPrime,
          0,
          hPrime,
          nprime,
          aprime,
          nprime,
          bprime,
          0,
          cR,
          dR,
          hPoint,
          gPoint,
        );

        final challenge = Ed25519Fr.fromBytes(
          _transcriptUpdateThree(transcript, L[round], R[round]),
        );
        transcript = challenge.toBytes();
        if (challenge == Ed25519Fr.zero) {
          return tryAgain();
        }
        final cInv = _invert(challenge);
        temp = EdwardsLimbOps.scMulField(yinvpow[nprime], challenge);
        gPrime = _hadamardFoldVar(gPrime, cInv, temp);
        hPrime = _hadamardFoldVar(hPrime, challenge, cInv);
        temp = EdwardsLimbOps.scMulField(cInv, yPowers[nprime]);
        aprime = _vectorAddComponentwise(
          _vectorScalar(aprime.sublist(0, nprime), challenge),
          _vectorScalar(aprime.sublist(nprime), temp),
        );
        bprime = _vectorAddComponentwise(
          _vectorScalar(bprime.sublist(0, nprime), cInv),
          _vectorScalar(bprime.sublist(nprime), challenge),
        );
        final cSq = EdwardsLimbOps.scMulField(challenge, challenge);
        final cSqInv = EdwardsLimbOps.scMulField(cInv, cInv);
        alpha1 = EdwardsLimbOps.scMulAddField(dL, cSq, alpha1);
        alpha1 = EdwardsLimbOps.scMulAddField(dR, cSqInv, alpha1);
        ++round;
      }
      final r = Ed25519Fr.fromBytes(RCT.skGen());
      final s = Ed25519Fr.fromBytes(RCT.skGen());
      final d_ = Ed25519Fr.fromBytes(RCT.skGen());
      final eta = Ed25519Fr.fromBytes(RCT.skGen());

      final List<MultiexpData> data = [];
      Ed25519Fr sc1 = EdwardsLimbOps.scMulField(r, _frInvEight);
      data.add(MultiexpData(scalar: sc1.toBytes(), point: gPrime[0]));
      sc1 = EdwardsLimbOps.scMulField(s, _frInvEight);
      data.add(MultiexpData(scalar: sc1.toBytes(), point: hPrime[0]));
      sc1 = EdwardsLimbOps.scMulField(d_, _frInvEight);
      data.add(MultiexpData(scalar: sc1.toBytes(), point: gPoint));
      temp = EdwardsLimbOps.scMulField(r, y);
      temp = EdwardsLimbOps.scMulField(temp, bprime[0]);
      temp2 = EdwardsLimbOps.scMulField(s, y);
      temp2 = EdwardsLimbOps.scMulField(temp2, aprime[0]);
      temp = EdwardsLimbOps.scAddField(temp, temp2);
      sc1 = EdwardsLimbOps.scMulField(temp, _frInvEight);
      data.add(MultiexpData(scalar: sc1.toBytes(), point: hPoint));

      final RctKey a1 = _multiexp(data: data, higiSize: 0);
      temp = EdwardsLimbOps.scMulField(r, y);
      temp = EdwardsLimbOps.scMulField(temp, s);
      temp = EdwardsLimbOps.scMulField(temp, _frInvEight);
      temp2 = EdwardsLimbOps.scMulField(eta, _frInvEight);
      final RctKey B = RCT.addKeys2(
        temp2.toBytes(),
        temp.toBytes(),
        RCTConst.h,
      );
      final e = Ed25519Fr.fromBytes(_transcriptUpdateThree(transcript, a1, B));
      if (e == Ed25519Fr.zero) {
        return tryAgain();
      }
      final eSq = EdwardsLimbOps.scMulField(e, e);
      final r1 = EdwardsLimbOps.scMulAddField(aprime[0], e, r);
      final s1 = EdwardsLimbOps.scMulAddField(bprime[0], e, s);
      Ed25519Fr d1 = EdwardsLimbOps.scMulAddField(d_, e, eta);
      d1 = EdwardsLimbOps.scMulAddField(alpha1, eSq, d1);
      return BulletproofPlus(
        a: A,
        a1: a1,
        b: B,
        r1: r1.toBytes(),
        d1: d1.toBytes(),
        s1: s1.toBytes(),
        l: L,
        r: R,
        v: V,
      );
    }

    return tryAgain();
  }

  static BulletproofPlus bulletproofPlusPROVEAmouts(
    List<BigInt> v,
    KeyV gamma,
  ) {
    try {
      return _bulletproofPlusPROVEAmouts(v, gamma);
    } catch (e) {
      throw BuError(
        DefaultErrorType.internal,
        "Failed to generate Bulletproof Plus.",
        details: {"error": e.toString()},
      );
    }
  }

  static BulletproofPlus _bulletproofPlusPROVEAmouts(
    List<BigInt> v,
    KeyV gamma,
  ) {
    if (v.length != gamma.length) {
      throw BuError(
        MoneroErrorType.crypto,
        "Incompatible sizes of v and gamma",
      );
    }

    // vG + gammaH
    final KeyV sv = List<RctKey>.generate(v.length, (_) => RCT.zero());
    for (int i = 0; i < v.length; ++i) {
      sv[i] = RCT.d2h(v[i]);
    }
    return bulletproofPlusPROVE(sv, gamma);
  }

  static bool bulletproofPlusVerify(List<BulletproofPlus> proofs) {
    try {
      return _bulletproofPlusVerify(proofs);
    } catch (e) {
      throw BuError(
        DefaultErrorType.cryptoVerifyFailed,
        "Failed to verify Bulletproof Plus.",
        details: {"error": e.toString()},
      );
    }
  }

  static bool _bulletproofPlusVerify(List<BulletproofPlus> proofs) {
    const int logN = 6;
    const int N = 1 << logN;
    int maxLength = 0;
    int invOffset = 0;
    int maxLogM = 0;
    final List<BpPlusProofData> proofData = [];
    List<Ed25519Fr> toInvert = [];
    final hPoint = RCT.asPoint(RCTConst.h);
    final gPoint = RCT.asPoint(RCTConst.g);
    for (final proof in proofs) {
      if (!_isReduced(proof.r1)) {
        throw BuError(MoneroErrorType.crypto, "Input scalar r1 not in range");
      }
      if (!_isReduced(proof.s1)) {
        throw BuError(MoneroErrorType.crypto, "Input scalar s1 not in range");
      }
      if (!_isReduced(proof.d1)) {
        throw BuError(MoneroErrorType.crypto, "Input scalar d1 not in range");
      }

      if (proof.v.isEmpty) {
        throw BuError(
          MoneroErrorType.crypto,
          "V does not have at least one element",
        );
      }
      if (proof.l.length != proof.l.length) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Mismatched L and R sizes",
        );
      }
      if (proof.l.isEmpty) {
        throw BuError(MoneroErrorType.crypto, "Empty proof");
      }
      maxLength = IntUtils.max(maxLength, proof.l.length);
      RctKey transcript = RCTConst.bulletproofPlusinitialTranscript.clone();
      transcript = _transcriptUpdateTwo(
        transcript,
        RCT.hashToScalarKeys(proof.v),
      );
      final y = Ed25519Fr.fromBytes(
        transcript = _transcriptUpdateTwo(transcript, proof.a),
      );
      if (y == Ed25519Fr.zero) {
        throw BuError(MoneroErrorType.crypto, "y == 0");
      }
      final z = Ed25519Fr.fromBytes(transcript = RCT.hashToScalar(y.toBytes()));
      if (z == Ed25519Fr.zero) {
        throw BuError(MoneroErrorType.crypto, "z == 0");
      }
      int M = 0;
      int logM = 0;
      for (logM = 0; (M = 1 << logM) <= maxM && M < proof.v.length; ++logM) {}
      if (proof.l.length != 6 + logM) {
        throw BuError(MoneroErrorType.crypto, "Proof is not the expected size");
      }
      maxLogM = IntUtils.max(logM, maxLogM);

      final int rounds = logM + logN;
      if (rounds <= 0) {
        throw BuError(MoneroErrorType.crypto, "Zero rounds");
      }
      final List<Ed25519Fr> challenges = List<Ed25519Fr>.generate(
        rounds,
        (_) => Ed25519Fr.zero,
      );
      for (int j = 0; j < rounds; ++j) {
        final update = Ed25519Fr.fromBytes(
          transcript = _transcriptUpdateThree(
            transcript,
            proof.l[j],
            proof.r[j],
          ),
        );
        challenges[j] = update;

        if (challenges[j] == Ed25519Fr.zero) {
          throw BuError(MoneroErrorType.crypto, "Some challenges are zero.");
        }
      }
      final e = Ed25519Fr.fromBytes(
        transcript = _transcriptUpdateThree(transcript, proof.a1, proof.b),
      );
      if (e == Ed25519Fr.zero) {
        throw BuError(MoneroErrorType.crypto, "e == 0");
      }
      for (int j = 0; j < rounds; ++j) {
        toInvert.add(challenges[j]);
      }
      toInvert.add(y);
      proofData.add(
        BpPlusProofData(
          y: y,
          z: z,
          e: e,
          challenges: challenges,
          logM: logM,
          invOffset: invOffset,
        ),
      );
      invOffset += rounds + 1;
    }

    if (maxLength >= 32) {
      throw BuError(MoneroErrorType.crypto, "At least one proof is too large");
    }
    final int maxMN = 1 << maxLength;
    List<MultiexpData> data = [];
    toInvert = _invertBatchVar(toInvert);
    Ed25519Fr gScalar = Ed25519Fr.zero;
    Ed25519Fr hScalar = Ed25519Fr.zero;
    final giScalars = List.generate(maxMN, (_) => Ed25519Fr.zero);
    final hiScalars = List.generate(maxMN, (_) => Ed25519Fr.zero);

    int dataIndex = 0;
    List<Ed25519Fr> cCache = [];
    final List<EdwardsLimbPoint> proof8V = [], proof8L = [], proof8R = [];

    for (final proof in proofs) {
      proof8V.clear();
      proof8L.clear();
      proof8R.clear();
      cCache.clear();
      final pd = proofData[dataIndex++];
      if (proof.l.length != pd.logM + 6) {
        throw BuError(MoneroErrorType.crypto, "Proof is not the expected size");
      }
      final int M = 1 << pd.logM;
      final int mn = M * N;
      Ed25519Fr weight = Ed25519Fr.zero;
      while (weight == Ed25519Fr.zero) {
        weight = Ed25519Fr.fromBytes(RCT.skGen());
      }
      for (int i = 0; i < proof.v.length; ++i) {
        proof8V.add(RCT.scalarmult8Point(proof.v[i]));
      }
      for (int i = 0; i < proof.l.length; ++i) {
        proof8L.add(RCT.scalarmult8Point(proof.l[i]));
      }
      for (int i = 0; i < proof.r.length; ++i) {
        proof8R.add(RCT.scalarmult8Point(proof.r[i]));
      }
      final proof8A1 = RCT.scalarmult8Point(proof.a1);
      final proof8B = RCT.scalarmult8Point(proof.b);
      final proof8A = RCT.scalarmult8Point(proof.a);
      Ed25519Fr yMN = pd.y;
      Ed25519Fr yMN1 = Ed25519Fr.zero;
      int tempMN = mn;
      while (tempMN > 1) {
        yMN = EdwardsLimbOps.scMulField(yMN, yMN);
        tempMN ~/= 2;
      }
      yMN1 = EdwardsLimbOps.scMulField(yMN, pd.y);
      final eSq = EdwardsLimbOps.scMulField(pd.e, pd.e);
      // final RctKey zSquared = RCT.zero();
      final zSquared = EdwardsLimbOps.scMulField(pd.z, pd.z);
      Ed25519Fr temp = EdwardsLimbOps.scSubField(Ed25519Fr.zero, eSq);
      temp = EdwardsLimbOps.scMulField(temp, yMN1);
      temp = EdwardsLimbOps.scMulField(temp, weight);
      for (int j = 0; j < proof8V.length; j++) {
        temp = EdwardsLimbOps.scMulField(temp, zSquared);

        data.add(MultiexpData(scalar: temp.toBytes(), point: proof8V[j]));
      }
      temp = EdwardsLimbOps.scMulField(_frMinusOne, weight);
      data.add(MultiexpData(scalar: temp.toBytes(), point: proof8B));
      temp = EdwardsLimbOps.scMulField(temp, pd.e);
      data.add(MultiexpData(scalar: temp.toBytes(), point: proof8A1));
      // RctKey mWeightESquared = RCT.zero();
      final mWeightESquared = EdwardsLimbOps.scMulField(temp, pd.e);
      data.add(MultiexpData(scalar: mWeightESquared.toBytes(), point: proof8A));
      gScalar = EdwardsLimbOps.scMulAddField(
        weight,
        Ed25519Fr.fromBytes(proof.d1),
        gScalar,
      );
      final d = List.generate(mn, (_) => Ed25519Fr.zero);
      d[0] = zSquared;
      for (int i = 1; i < N; i++) {
        d[i] = EdwardsLimbOps.scAddField(d[i - 1], d[i - 1]);
      }

      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          d[j * N + i] = EdwardsLimbOps.scMulField(
            d[(j - 1) * N + i],
            zSquared,
          );
        }
      }
      // final RctKey sumD = RCT.zero();
      final sumD = EdwardsLimbOps.scMulField(
        _fr264m1,
        _sumOfEvenPowers(pd.z, 2 * M),
      );

      final sumY = _sumOfScalarPowers(pd.y, mn);
      temp = EdwardsLimbOps.scSubField(zSquared, pd.z);
      temp = EdwardsLimbOps.scMulField(temp, sumY);
      Ed25519Fr temp2 = EdwardsLimbOps.scMulField(yMN1, pd.z);
      temp2 = EdwardsLimbOps.scMulField(temp2, sumD);
      temp = EdwardsLimbOps.scAddField(temp, temp2);
      temp = EdwardsLimbOps.scMulField(temp, eSq);
      temp2 = EdwardsLimbOps.scMulField(Ed25519Fr.fromBytes(proof.r1), pd.y);
      temp2 = EdwardsLimbOps.scMulField(temp2, Ed25519Fr.fromBytes(proof.s1));
      temp = EdwardsLimbOps.scAddField(temp, temp2);
      hScalar = EdwardsLimbOps.scMulAddField(temp, weight, hScalar);
      final int rounds = pd.logM + logN;
      if (rounds <= 0) {
        throw BuError(MoneroErrorType.crypto, "Zero rounds");
      }

      final List<Ed25519Fr> cInv = toInvert.sublist(pd.invOffset);
      final yinv = toInvert[pd.invOffset + rounds];
      cCache = List<Ed25519Fr>.generate(1 << rounds, (_) => Ed25519Fr.zero);
      cCache[0] = cInv[0];
      cCache[1] = pd.challenges[0];
      for (int j = 1; j < rounds; ++j) {
        final int slots = 1 << (j + 1);
        for (int s = slots; s-- > 0; --s) {
          cCache[s] = EdwardsLimbOps.scMulField(
            cCache[s ~/ 2],
            pd.challenges[j],
          );
          cCache[s - 1] = EdwardsLimbOps.scMulField(cCache[s ~/ 2], cInv[j]);
        }
      }
      Ed25519Fr eR1WY = EdwardsLimbOps.scMulField(
        pd.e,
        Ed25519Fr.fromBytes(proof.r1),
      );
      eR1WY = EdwardsLimbOps.scMulField(eR1WY, weight);
      Ed25519Fr eS1W = EdwardsLimbOps.scMulField(
        pd.e,
        Ed25519Fr.fromBytes(proof.s1),
      );
      eS1W = EdwardsLimbOps.scMulField(eS1W, weight);
      Ed25519Fr eSquaredZW = EdwardsLimbOps.scMulField(eSq, pd.z);
      eSquaredZW = EdwardsLimbOps.scMulField(eSquaredZW, weight);
      final minusESquaredZW = EdwardsLimbOps.scSubField(
        Ed25519Fr.zero,
        eSquaredZW,
      );
      Ed25519Fr minusESquaredWY = EdwardsLimbOps.scSubField(
        Ed25519Fr.zero,
        eSq,
      );
      minusESquaredWY = EdwardsLimbOps.scMulField(minusESquaredWY, weight);
      minusESquaredWY = EdwardsLimbOps.scMulField(minusESquaredWY, yMN);
      for (int i = 0; i < mn; ++i) {
        Ed25519Fr gSc = eR1WY;
        Ed25519Fr hSc = Ed25519Fr.zero;

        // Use the binary decomposition of the index
        gSc = EdwardsLimbOps.scMulAddField(gSc, cCache[i], eSquaredZW);
        hSc = EdwardsLimbOps.scMulAddField(
          eS1W,
          cCache[(~i) & (mn - 1)],
          minusESquaredZW,
        );

        // Complete the scalar derivation
        giScalars[i] = EdwardsLimbOps.scAddField(giScalars[i], gSc);
        hSc = EdwardsLimbOps.scMulAddField(minusESquaredWY, d[i], hSc);
        hiScalars[i] = EdwardsLimbOps.scAddField(hiScalars[i], hSc);

        // Update iterated values
        eR1WY = EdwardsLimbOps.scMulField(eR1WY, yinv);
        minusESquaredWY = EdwardsLimbOps.scMulField(minusESquaredWY, yinv);
      }

      for (int j = 0; j < rounds; ++j) {
        temp = EdwardsLimbOps.scMulField(pd.challenges[j], pd.challenges[j]);
        temp = EdwardsLimbOps.scMulField(temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp.toBytes(), point: proof8L[j]));
        temp = EdwardsLimbOps.scMulField(cInv[j], cInv[j]);
        temp = EdwardsLimbOps.scMulField(temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp.toBytes(), point: proof8R[j]));
      }
    }

    data.add(MultiexpData(scalar: gScalar.toBytes(), point: gPoint));
    data.add(MultiexpData(scalar: hScalar.toBytes(), point: hPoint));

    final List<MultiexpData?> nd = List.filled(2 * maxMN, null);
    for (int i = 0; i < maxMN; ++i) {
      nd[i * 2] = MultiexpData(
        scalar: giScalars[i].toBytes(),
        point: _getGiP3Bytes(i),
      );
      nd[i * 2 + 1] = MultiexpData(
        scalar: hiScalars[i].toBytes(),
        point: _getHiP3Bytes(i),
      );
    }
    data = [...nd.cast(), ...data];

    final mp = _multiexp(data: data, higiSize: 2 * maxMN);
    if (BytesUtils.bytesEqual(mp, RCT.identity(clone: false))) {
      return true;
    }
    return false;
  }
}
