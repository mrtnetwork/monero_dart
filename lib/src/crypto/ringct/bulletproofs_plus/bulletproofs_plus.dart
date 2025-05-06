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

// import 'dart:math';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/models/bullet_proof_data.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/cached/cached_exponet.dart';
import 'package:monero_dart/src/monero_base.dart';

class BulletproofsPlusGenerator {
  static const int maxN = 64;
  static const int maxM = 16;
  static final _hPoint = RCT.asPoint(RCTConst.h);
  static final _gPoint = RCT.asPoint(RCTConst.g);

  static EDPoint _getExponentBytes({required RctKey base, required int idx}) {
    final cached = cachedExponet[idx.toString()];
    if (cached != null) {
      return RCT.asPoint(BytesUtils.fromHexString(cached));
    }
    final indexBytes = MoneroLayoutConst.varintInt().serialize(idx);
    final hash = QuickCrypto.keccack256Hash(
        [...base, ...RCTConst.bulletproofPlusHashKey, ...indexBytes]);

    return RCT.asPoint(RCT.hashToP3Bytes(hash));
  }

  static EDPoint _getGiP3Bytes(int index) {
    return _getExponentBytes(base: RCTConst.h, idx: index * 2 + 1);
  }

  static EDPoint _getHiP3Bytes(int index) {
    return _getExponentBytes(base: RCTConst.h, idx: index * 2);
  }

  static RctKey _multiexp(
      {required List<MultiexpData> data, int higiSize = 0}) {
    if (higiSize > 0) {
      if (higiSize <= 232 && data.length == higiSize) {
        return Multiexp.straus(data: data, step: 0).toBytes();
      }
      return Multiexp.pippenger(
              data: data,
              cacheSize: higiSize,
              c: Multiexp.getPippengerC(data.length))
          .toBytes();
    }
    if (data.length <= 95) {
      return Multiexp.straus(data: data).toBytes();
    }
    return Multiexp.pippenger(
            data: data, cacheSize: 0, c: Multiexp.getPippengerC(data.length))
        .toBytes();
  }

  static List<int> _vectorExponentVar({required KeyV a, required KeyV b}) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    if (a.length > maxN * maxM) {
      throw const MoneroCryptoException("Incompatible sizes of a and maxN");
    }
    final List<MultiexpData> multiexpDataVar = [];
    for (int i = 0; i < a.length; i++) {
      multiexpDataVar.add(MultiexpData(
          scalar: a[i],
          point: _getGiP3Bytes(i))); // Assuming MultiexpData has a constructor
      multiexpDataVar.add(MultiexpData(scalar: b[i], point: _getHiP3Bytes(i)));
    }
    return _multiexp(data: multiexpDataVar, higiSize: a.length * 2);
  }

  static RctKey _computeLRVar(
      int size,
      RctKey y,
      List<EDPoint> G,
      int g0,
      List<EDPoint> H,
      int h0,
      KeyV a,
      int a0,
      KeyV b,
      int b0,
      RctKey c,
      RctKey d) {
    if (size + g0 > G.length) {
      throw const MoneroCryptoException("Incompatible size for G");
    }
    if (size + h0 > H.length) {
      throw const MoneroCryptoException("Incompatible size for H");
    }
    if (size + a0 > a.length) {
      throw const MoneroCryptoException("Incompatible size for a");
    }
    if (size + b0 > b.length) {
      throw const MoneroCryptoException("Incompatible size for b");
    }
    if (size > maxN * maxM) {
      throw const MoneroCryptoException("size is too large");
    }
    final List<MultiexpData?> multiexpData = List.filled(size * 2 + 2, null);
    RctKey temp = RCT.zero();
    for (int i = 0; i < size; ++i) {
      temp = Ed25519Utils.scMulVar(a[a0 + i], y);
      final RctKey scalar =
          Ed25519Utils.scMulVarBigInt(temp, RCTConst.invEightBig);
      multiexpData[i * 2] = MultiexpData(scalar: scalar, point: G[g0 + i]);
      final RctKey scalar2 =
          Ed25519Utils.scMulVarBigInt(b[b0 + i], RCTConst.invEightBig);
      multiexpData[i * 2 + 1] = MultiexpData(scalar: scalar2, point: H[h0 + i]);
    }
    RctKey scBytes = Ed25519Utils.scMulVarBigInt(c, RCTConst.invEightBig);
    multiexpData[2 * size] = MultiexpData(scalar: scBytes, point: _hPoint);
    scBytes = Ed25519Utils.scMulVarBigInt(d, RCTConst.invEightBig);
    multiexpData[2 * size + 1] = MultiexpData(scalar: scBytes, point: _gPoint);
    return _multiexp(data: multiexpData.cast(), higiSize: 0);
  }

  static KeyV _vectorOfScalarPowers(RctKey x, int n) {
    if (n <= 0) {
      throw const MoneroCryptoException("Need n > 0");
    }
    final res = List<List<int>>.generate(n, (_) => RCT.zero());
    res[0] = RCT.identity();
    if (n == 1) {
      return res;
    }
    res[1] = x.clone();
    for (int i = 2; i < n; ++i) {
      res[i] = Ed25519Utils.scMulVar(res[i - 1], x);
    }
    return res;
  }

  static RctKey _sumOfEvenPowers(RctKey x, int n) {
    if ((n & (n - 1)) != 0) {
      throw const MoneroCryptoException("Need n to be a power of 2");
    }
    if (n == 0) {
      throw const MoneroCryptoException("Need n > 0");
    }

    RctKey x1 = x.clone();
    x1 = Ed25519Utils.scMulVar(x1, x1);

    RctKey res = x1.clone();
    while (n > 2) {
      res = Ed25519Utils.scMulAddVar(x1, res, res);
      x1 = Ed25519Utils.scMulVar(x1, x1);
      n ~/= 2;
    }

    return res;
  }

  static RctKey _sumOfScalarPowers(RctKey x, int n) {
    if (n == 0) {
      throw const MoneroCryptoException("Need n > 0");
    }

    RctKey res = RCTConst.i.clone();
    if (n == 1) {
      return x;
    }

    n += 1;
    RctKey x1 = x.clone();

    final bool isPowerOf2 = (n & (n - 1)) == 0;
    if (isPowerOf2) {
      res = Ed25519Utils.scAddVar(res, x1);
      while (n > 2) {
        x1 = Ed25519Utils.scMulVar(x1, x1);
        res = Ed25519Utils.scMulAddVar(x1, res, res);
        n ~/= 2;
      }
    } else {
      RctKey prev = x1.clone();
      for (int i = 1; i < n; ++i) {
        if (i > 1) prev = Ed25519Utils.scMulVar(prev, x1);
        res = Ed25519Utils.scAddVar(res, prev);
      }
    }
    res = Ed25519Utils.scSubVar(res, RCTConst.i);
    return res;
  }

  static RctKey _weightedInnerProduct(
      List<RctKey> a, List<RctKey> b, RctKey y) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    RctKey res = RCT.zero();
    RctKey yPower = RCTConst.i.clone();
    RctKey temp = RCT.zero();
    for (int i = 0; i < a.length; ++i) {
      temp = Ed25519Utils.scMulVar(a[i], b[i]);
      yPower = Ed25519Utils.scMulVar(yPower, y);
      res = Ed25519Utils.scMulAddVar(temp, yPower, res);
    }
    return res;
  }

  static List<EDPoint> _hadamardFoldVar(List<EDPoint> v, RctKey a, RctKey b) {
    if (v.length.isOdd) {
      throw const MoneroCryptoException("Vector size should be even");
    }
    final vC = v.clone();
    final int size = v.length ~/ 2;
    for (int n = 0; n < size; ++n) {
      vC[n] = CryptoOps.geDoubleScalarMultPrecompPointVar(
          a,
          CryptoOps.geDsmPrecompVar(v[n]),
          b,
          CryptoOps.geDsmPrecompVar(v[size + n]));
    }
    return vC.sublist(0, size);
  }

  static KeyV _vectorAddComponentwise(KeyV a, KeyV b) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    for (int i = 0; i < a.length; ++i) {
      res[i] = Ed25519Utils.scAddVar(a[i], b[i]);
    }
    return res;
  }

  static KeyV _vectorAdd(KeyV a, RctKey b) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    final bBig = Ed25519Utils.scalarAsBig(b);
    for (int i = 0; i < a.length; ++i) {
      res[i] = Ed25519Utils.scAddVarBig(a[i], bBig);
    }
    return res;
  }

  static KeyV _vectorSubtract(KeyV a, RctKey b) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    final bBig = Ed25519Utils.scalarAsBig(b);
    for (int i = 0; i < a.length; ++i) {
      res[i] = Ed25519Utils.scSubVarBigInt(a[i], bBig);
    }
    return res;
  }

  static KeyV _vectorScalar(List<RctKey> a, RctKey x) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    final xBig = Ed25519Utils.scalarAsBig(x);
    for (int i = 0; i < a.length; ++i) {
      res[i] = Ed25519Utils.scMulVarBigInt(a[i], xBig);
    }
    return res;
  }

  static RctKey _sm(RctKey y, int n, RctKey x) {
    while (n-- != 0) {
      y = Ed25519Utils.scMulVar(y, y);
    }
    y = Ed25519Utils.scMulVar(y, x);
    return y;
  }

  static RctKey _invert(RctKey x) {
    if (BytesUtils.bytesEqual(x, RCTConst.z)) {
      throw const MoneroCryptoException("Cannot invert zero.");
    }

    /// Ed25519Utils
    final RctKey a1 = x.clone();
    final RctKey a10 = Ed25519Utils.scMulVar(a1, a1);
    final RctKey a100 = Ed25519Utils.scMulVar(a10, a10);
    final RctKey a11 = Ed25519Utils.scMulVar(a10, a1);
    final RctKey a101 = Ed25519Utils.scMulVar(a10, a11);
    final RctKey a111 = Ed25519Utils.scMulVar(a10, a101);
    final RctKey a1001 = Ed25519Utils.scMulVar(a10, a111);
    final RctKey a1011 = Ed25519Utils.scMulVar(a10, a1001);
    final RctKey a1111 = Ed25519Utils.scMulVar(a100, a1011);

    RctKey inv = Ed25519Utils.scMulVar(a1111, a1);

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

  static KeyV _invertBatchVar(KeyV x) {
    final KeyV scratch = [];

    RctKey acc = RCT.identity();
    for (int n = 0; n < x.length; ++n) {
      if (BytesUtils.bytesEqual(x[n], RCT.zero(clone: false))) {
        throw const MoneroCryptoException("Cannot _invert zero!");
      }
      scratch.add(acc.clone());
      if (n == 0) {
        acc = x[0].clone();
      } else {
        acc = Ed25519Utils.scMulVar(acc, x[n]);
      }
    }

    acc = _invert(acc);
    RctKey tmp = RCT.zero(clone: false);
    for (int i = x.length; i-- > 0;) {
      tmp = Ed25519Utils.scMulVar(acc, x[i]);
      x[i] = Ed25519Utils.scMulVar(acc, scratch[i]);
      acc = tmp.clone();
    }
    return x;
  }

  static RctKey _transcriptUpdateTwo(RctKey transcript, RctKey update) {
    return RCT.hashToScalarBytesVar([...transcript, ...update]);
  }

  static RctKey _transcriptUpdateThree(
      RctKey transcript, RctKey update0, RctKey update1) {
    return RCT.hashToScalarBytesVar([...transcript, ...update0, ...update1]);
  }

  static bool _isReduced(RctKey scalar) {
    return Ed25519Utils.scCheckVar(scalar);
  }

  static BulletproofPlus bulletproofPlusPROVE(KeyV sv, KeyV gamma) {
    try {
      return _bulletproofPlusPROVE(sv, gamma);
    } catch (e) {
      throw MoneroCryptoException("Failed to generate Bulletproof Plus.",
          details: {"error": e.toString()});
    }
  }

  static BulletproofPlus _bulletproofPlusPROVE(KeyV sv, KeyV gamma) {
    if (sv.length != gamma.length) {
      throw const MoneroCryptoException("Incompatible sizes of sv and gamma");
    }
    for (final i in sv) {
      if (!_isReduced(i)) {
        throw const MoneroCryptoException("Invalid sv input");
      }
    }
    for (final i in gamma) {
      if (!_isReduced(i)) {
        throw const MoneroCryptoException("Invalid gamma input");
      }
    }
    const int logN = 6;
    const int N = 1 << logN;
    int M = 0, logM = 0;
    while ((M = 1 << logM) <= maxM && M < sv.length) {
      logM++;
    }
    if (M > maxM) {
      throw const MoneroCryptoException("sv/gamma are too large");
    }
    final int logMN = logM + logN;
    final int mn = M * N;
    final KeyV V = [];
    final KeyV aL = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aR = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aL8 = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aR8 = List<List<int>>.generate(mn, (_) => RCT.zero());
    RctKey temp = RCT.zero();
    RctKey temp2 = RCT.zero();
    for (int i = 0; i < sv.length; ++i) {
      final RctKey gamma8 =
          Ed25519Utils.scMulVarBigInt(gamma[i], RCTConst.invEightBig);
      final RctKey sv8 =
          Ed25519Utils.scMulVarBigInt(sv[i], RCTConst.invEightBig);
      V.add(RCT.addKeys2Var(gamma8, sv8, RCTConst.h));
    }

    for (int j = 0; j < M; ++j) {
      for (int i = N; i-- > 0;) {
        if (j < sv.length && (sv[j][i ~/ 8] & (1 << (i % 8))) != 0) {
          aL[j * N + i] = RCT.identity();
          aL8[j * N + i] = RCTConst.invEight;
          aR[j * N + i] = aR8[j * N + i] = RCT.zero();
        } else {
          aL[j * N + i] = aL8[j * N + i] = RCT.zero();
          aR[j * N + i] = RCTConst.minusOne;
          aR8[j * N + i] = RCTConst.minusInvEight;
        }
      }
    }
    BulletproofPlus tryAgain() {
      RctKey transcript = RCTConst.bulletproofPlusinitialTranscript.clone();
      transcript = _transcriptUpdateTwo(transcript, RCT.hashToScalarKeys(V));
      final RctKey alpha = RCT.skGen_();
      final RctKey preA = _vectorExponentVar(a: aL8, b: aR8);
      temp = Ed25519Utils.scMulVarBigInt(alpha, RCTConst.invEightBig);
      final RctKey A = RCT.addKeysVar(preA, RCT.scalarmultBaseVar(temp));
      final RctKey y = _transcriptUpdateTwo(transcript, A);
      if (BytesUtils.bytesEqual(y, RCT.zero(clone: false))) {
        return tryAgain();
      }
      transcript = RCT.hashToScalarVar(y);
      if (BytesUtils.bytesEqual(transcript, RCT.zero(clone: false))) {
        return tryAgain();
      }
      final RctKey zSquared = Ed25519Utils.scMulVar(transcript, transcript);
      final KeyV d = List.generate(mn, (_) => RCT.zero());
      d[0] = zSquared;
      for (int i = 1; i < N; i++) {
        d[i] = Ed25519Utils.scMulVar(d[i - 1], RCTConst.two);
      }

      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          d[j * N + i] = Ed25519Utils.scMulVar(d[(j - 1) * N + i], zSquared);
        }
      }

      final KeyV yPowers = _vectorOfScalarPowers(y, mn + 2);

      final KeyV aL1 = _vectorSubtract(aL, transcript);

      KeyV aR1 = _vectorAdd(aR, transcript);

      final KeyV dy = List.generate(mn, (i) => RCT.zero());

      for (int i = 0; i < mn; i++) {
        dy[i] = Ed25519Utils.scMulVar(d[i], yPowers[mn - i]);
      }

      aR1 = _vectorAddComponentwise(aR1, dy);

      RctKey alpha1 = alpha.clone();
      temp = RCTConst.i.clone();
      for (int j = 0; j < sv.length; j++) {
        temp = Ed25519Utils.scMulVar(temp, zSquared);
        temp2 = Ed25519Utils.scMulVar(yPowers[mn + 1], temp);
        alpha1 = Ed25519Utils.scMulAddVar(temp2, gamma[j], alpha1);
      }

      int nprime = mn;
      List<EDPoint> gPrime = [];
      List<EDPoint> hPrime = [];
      KeyV aprime = List.generate(mn, (_) => RCT.zero());
      KeyV bprime = List.generate(mn, (_) => RCT.zero());
      final RctKey yinv = _invert(y);
      final KeyV yinvpow = List.generate(mn, (_) => RCT.zero());
      yinvpow[0] = RCTConst.i.clone();
      for (int i = 0; i < mn; ++i) {
        gPrime.add(_getGiP3Bytes(i));
        hPrime.add(_getHiP3Bytes(i));
        if (i > 0) {
          yinvpow[i] = Ed25519Utils.scMulVar(yinvpow[i - 1], yinv);
        }
        aprime[i] = aL1[i].clone();
        bprime[i] = aR1[i].clone();
      }
      final KeyV L = List.generate(logMN, (_) => RCT.zero());
      final KeyV R = List.generate(logMN, (_) => RCT.zero());

      int round = 0;
      // Inner-product rounds
      while (nprime > 1) {
        nprime ~/= 2;
        final RctKey cL = _weightedInnerProduct(
            aprime.sublist(0, nprime), bprime.sublist(nprime), y);
        final RctKey cR = _weightedInnerProduct(
            _vectorScalar(aprime.sublist(nprime), yPowers[nprime]),
            bprime.sublist(0, nprime),
            y);
        final RctKey dL = RCT.skGen_();
        final RctKey dR = RCT.skGen_();
        L[round] = _computeLRVar(nprime, yinvpow[nprime], gPrime, nprime,
            hPrime, 0, aprime, 0, bprime, nprime, cL, dL);
        R[round] = _computeLRVar(nprime, yPowers[nprime], gPrime, 0, hPrime,
            nprime, aprime, nprime, bprime, 0, cR, dR);

        final RctKey challenge =
            _transcriptUpdateThree(transcript, L[round], R[round]);
        transcript = challenge.clone();
        if (BytesUtils.bytesEqual(challenge, RCT.zero(clone: false))) {
          return tryAgain();
        }
        final RctKey cInv = _invert(challenge);
        temp = Ed25519Utils.scMulVar(yinvpow[nprime], challenge);
        gPrime = _hadamardFoldVar(gPrime, cInv, temp);
        hPrime = _hadamardFoldVar(hPrime, challenge, cInv);
        temp = Ed25519Utils.scMulVar(cInv, yPowers[nprime]);
        aprime = _vectorAddComponentwise(
            _vectorScalar(aprime.sublist(0, nprime), challenge),
            _vectorScalar(aprime.sublist(nprime), temp));
        bprime = _vectorAddComponentwise(
            _vectorScalar(bprime.sublist(0, nprime), cInv),
            _vectorScalar(bprime.sublist(nprime), challenge));
        final RctKey cSq = Ed25519Utils.scMulVar(challenge, challenge);
        final RctKey cSqInv = Ed25519Utils.scMulVar(cInv, cInv);
        alpha1 = Ed25519Utils.scMulAddVar(dL, cSq, alpha1);
        alpha1 = Ed25519Utils.scMulAddVar(dR, cSqInv, alpha1);
        ++round;
      }
      final RctKey r = RCT.skGen_();
      final RctKey s = RCT.skGen_();
      final RctKey d_ = RCT.skGen_();
      final RctKey eta = RCT.skGen_();

      final List<MultiexpData> data = [];
      RctKey sc1 = Ed25519Utils.scMulVarBigInt(r, RCTConst.invEightBig);
      data.add(MultiexpData(scalar: sc1, point: gPrime[0]));
      sc1 = Ed25519Utils.scMulVarBigInt(s, RCTConst.invEightBig);
      data.add(MultiexpData(scalar: sc1, point: hPrime[0]));
      sc1 = Ed25519Utils.scMulVarBigInt(d_, RCTConst.invEightBig);
      data.add(MultiexpData(scalar: sc1, point: _gPoint));
      temp = Ed25519Utils.scMulVar(r, y);
      temp = Ed25519Utils.scMulVar(temp, bprime[0]);
      temp2 = Ed25519Utils.scMulVar(s, y);
      temp2 = Ed25519Utils.scMulVar(temp2, aprime[0]);
      temp = Ed25519Utils.scAddVar(temp, temp2);
      sc1 = Ed25519Utils.scMulVarBigInt(temp, RCTConst.invEightBig);
      data.add(MultiexpData(scalar: sc1, point: _hPoint));

      final RctKey a1 = _multiexp(data: data, higiSize: 0);
      temp = Ed25519Utils.scMulVar(r, y);
      temp = Ed25519Utils.scMulVar(temp, s);
      temp = Ed25519Utils.scMulVarBigInt(temp, RCTConst.invEightBig);
      temp2 = Ed25519Utils.scMulVarBigInt(eta, RCTConst.invEightBig);
      final RctKey B = RCT.addKeys2Var(temp2, temp, RCTConst.h);
      final RctKey e = _transcriptUpdateThree(transcript, a1, B);
      if (BytesUtils.bytesEqual(e, RCT.zero(clone: false))) {
        return tryAgain();
      }
      final RctKey eSq = Ed25519Utils.scMulVar(e, e);
      final RctKey r1 = Ed25519Utils.scMulAddVar(aprime[0], e, r);
      final RctKey s1 = Ed25519Utils.scMulAddVar(bprime[0], e, s);
      RctKey d1 = Ed25519Utils.scMulAddVar(d_, e, eta);
      d1 = Ed25519Utils.scMulAddVar(alpha1, eSq, d1);
      return BulletproofPlus(
          a: A, a1: a1, b: B, r1: r1, d1: d1, s1: s1, l: L, r: R, v: V);
    }

    return tryAgain();
  }

  static BulletproofPlus bulletproofPlusPROVEAmouts(
      List<BigInt> v, KeyV gamma) {
    try {
      return _bulletproofPlusPROVEAmouts(v, gamma);
    } catch (e) {
      throw MoneroCryptoException("Failed to generate Bulletproof Plus.",
          details: {"error": e.toString()});
    }
  }

  static BulletproofPlus _bulletproofPlusPROVEAmouts(
      List<BigInt> v, KeyV gamma) {
    if (v.length != gamma.length) {
      throw const MoneroCryptoException("Incompatible sizes of v and gamma");
    }

    // vG + gammaH
    final KeyV sv = List<List<int>>.generate(v.length, (_) => RCT.zero());
    for (int i = 0; i < v.length; ++i) {
      sv[i] = RCT.d2h(v[i]);
    }
    return bulletproofPlusPROVE(sv, gamma);
  }

  static bool bulletproofPlusVerify(List<BulletproofPlus> proofs) {
    try {
      return _bulletproofPlusVerify(proofs);
    } catch (e) {
      throw MoneroCryptoException("Failed to verify Bulletproof Plus.",
          details: {"error": e.toString()});
    }
  }

  static bool _bulletproofPlusVerify(List<BulletproofPlus> proofs) {
    const int logN = 6;
    const int N = 1 << logN;
    int maxLength = 0;
    int invOffset = 0;
    int maxLogM = 0;
    final List<BpPlusProofData> proofData = [];
    List<RctKey> toInvert = [];
    for (final proof in proofs) {
      if (!_isReduced(proof.r1)) {
        throw const MoneroCryptoException("Input scalar r1 not in range");
      }
      if (!_isReduced(proof.s1)) {
        throw const MoneroCryptoException("Input scalar s1 not in range");
      }
      if (!_isReduced(proof.d1)) {
        throw const MoneroCryptoException("Input scalar d1 not in range");
      }

      if (proof.v.isEmpty) {
        throw const MoneroCryptoException(
            "V does not have at least one element");
      }
      if (proof.l.length != proof.l.length) {
        throw const MoneroCryptoException("Mismatched L and R sizes");
      }
      if (proof.l.isEmpty) {
        throw const MoneroCryptoException("Empty proof");
      }
      maxLength = IntUtils.max(maxLength, proof.l.length);
      RctKey transcript = RCTConst.bulletproofPlusinitialTranscript.clone();
      transcript =
          _transcriptUpdateTwo(transcript, RCT.hashToScalarKeysVar(proof.v));
      final y = transcript = _transcriptUpdateTwo(transcript, proof.a);
      if (BytesUtils.bytesEqual(y, RCT.zero(clone: false))) {
        throw const MoneroCryptoException("y == 0");
      }
      final z = transcript = RCT.hashToScalarVar(y);
      if (BytesUtils.bytesEqual(z, RCT.zero(clone: false))) {
        throw const MoneroCryptoException("z == 0");
      }
      int M = 0;
      int logM = 0;
      for (logM = 0; (M = 1 << logM) <= maxM && M < proof.v.length; ++logM) {}
      if (proof.l.length != 6 + logM) {
        throw const MoneroCryptoException("Proof is not the expected size");
      }
      maxLogM = IntUtils.max(logM, maxLogM);

      final int rounds = logM + logN;
      if (rounds <= 0) {
        throw const MoneroCryptoException("Zero rounds");
      }
      final List<RctKey> challenges =
          List<RctKey>.generate(rounds, (_) => RCT.zero());
      for (int j = 0; j < rounds; ++j) {
        final update = transcript =
            _transcriptUpdateThree(transcript, proof.l[j], proof.r[j]);
        challenges[j] = update;

        if (BytesUtils.bytesEqual(challenges[j], RCT.zero(clone: false))) {
          throw const MoneroCryptoException("Some challanges is zoro");
        }
      }
      final e =
          transcript = _transcriptUpdateThree(transcript, proof.a1, proof.b);
      if (BytesUtils.bytesEqual(e, RCT.zero(clone: false))) {
        throw const MoneroCryptoException("e == 0");
      }
      for (int j = 0; j < rounds; ++j) {
        toInvert.add(challenges[j]);
      }
      toInvert.add(y);
      proofData.add(BpPlusProofData(
          y: y,
          z: z,
          e: e,
          challenges: challenges,
          logM: logM,
          invOffset: invOffset));
      invOffset += rounds + 1;
    }

    if (maxLength >= 32) {
      throw const MoneroCryptoException("At least one proof is too large");
    }
    final int maxMN = 1 << maxLength;
    RctKey temp = RCT.zero();
    RctKey temp2 = RCT.zero();
    List<MultiexpData> data = [];
    toInvert = _invertBatchVar(toInvert.map((e) => e.clone()).toList());
    RctKey gScalar = RCT.zero();
    RctKey hScalar = RCT.zero();
    final KeyV giScalars = List.generate(maxMN, (_) => RCT.zero());
    final KeyV hiScalars = List.generate(maxMN, (_) => RCT.zero());

    int dataIndex = 0;
    KeyV cCache = [];
    final List<EDPoint> proof8V = [], proof8L = [], proof8R = [];

    for (final proof in proofs) {
      proof8V.clear();
      proof8L.clear();
      proof8R.clear();
      cCache.clear();
      final pd = proofData[dataIndex++];
      if (proof.l.length != pd.logM + 6) {
        throw const MoneroCryptoException("Proof is not the expected size");
      }
      final int M = 1 << pd.logM;
      final int mn = M * N;
      RctKey weight = RCT.zero(clone: false);
      while (BytesUtils.bytesEqual(weight, RCT.zero(clone: false))) {
        weight = RCT.skGen_();
      }
      for (int i = 0; i < proof.v.length; ++i) {
        proof8V.add(RCT.scalarmult8PointVar(proof.v[i]));
      }
      for (int i = 0; i < proof.l.length; ++i) {
        proof8L.add(RCT.scalarmult8PointVar(proof.l[i]));
      }
      for (int i = 0; i < proof.r.length; ++i) {
        proof8R.add(RCT.scalarmult8PointVar(proof.r[i]));
      }
      final proof8A1 = RCT.scalarmult8PointVar(proof.a1);
      final proof8B = RCT.scalarmult8PointVar(proof.b);
      final proof8A = RCT.scalarmult8PointVar(proof.a);
      RctKey yMN = pd.y.clone();
      RctKey yMN1 = RCT.zero();
      int tempMN = mn;
      while (tempMN > 1) {
        yMN = Ed25519Utils.scMulVar(yMN, yMN);
        tempMN ~/= 2;
      }
      yMN1 = Ed25519Utils.scMulVar(yMN, pd.y);
      final RctKey eSq = Ed25519Utils.scMulVar(pd.e, pd.e);
      // final RctKey zSquared = RCT.zero();
      final RctKey zSquared = Ed25519Utils.scMulVar(pd.z, pd.z);
      temp = Ed25519Utils.scSubVar(RCTConst.z, eSq);
      temp = Ed25519Utils.scMulVar(temp, yMN1);
      temp = Ed25519Utils.scMulVar(temp, weight);
      for (int j = 0; j < proof8V.length; j++) {
        temp = Ed25519Utils.scMulVar(temp, zSquared);

        data.add(MultiexpData(scalar: temp, point: proof8V[j]));
      }
      temp = Ed25519Utils.scMulVar(RCTConst.minusOne, weight);
      data.add(MultiexpData(scalar: temp, point: proof8B));
      temp = Ed25519Utils.scMulVar(temp, pd.e);
      data.add(MultiexpData(scalar: temp, point: proof8A1));
      // RctKey mWeightESquared = RCT.zero();
      final RctKey mWeightESquared = Ed25519Utils.scMulVar(temp, pd.e);
      data.add(MultiexpData(scalar: mWeightESquared, point: proof8A));
      gScalar = Ed25519Utils.scMulAddVar(weight, proof.d1, gScalar);
      final KeyV d = List<List<int>>.generate(mn, (_) => RCT.zero());
      d[0] = zSquared.clone();
      for (int i = 1; i < N; i++) {
        d[i] = Ed25519Utils.scAddVar(d[i - 1], d[i - 1]);
      }

      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          d[j * N + i] = Ed25519Utils.scMulVar(d[(j - 1) * N + i], zSquared);
        }
      }
      // final RctKey sumD = RCT.zero();
      final sumD = Ed25519Utils.scMulVar(
          RCTConst.twoSixtyFourMinusOne, _sumOfEvenPowers(pd.z, 2 * M));

      final RctKey sumY = _sumOfScalarPowers(pd.y, mn);
      temp = Ed25519Utils.scSubVar(zSquared, pd.z);
      temp = Ed25519Utils.scMulVar(temp, sumY);
      temp2 = Ed25519Utils.scMulVar(yMN1, pd.z);
      temp2 = Ed25519Utils.scMulVar(temp2, sumD);
      temp = Ed25519Utils.scAddVar(temp, temp2);
      temp = Ed25519Utils.scMulVar(temp, eSq);
      temp2 = Ed25519Utils.scMulVar(proof.r1, pd.y);
      temp2 = Ed25519Utils.scMulVar(temp2, proof.s1);
      temp = Ed25519Utils.scAddVar(temp, temp2);
      hScalar = Ed25519Utils.scMulAddVar(temp, weight, hScalar);
      final int rounds = pd.logM + logN;
      if (rounds <= 0) {
        throw const MoneroCryptoException("Zero rounds");
      }

      final List<RctKey> cInv = toInvert.sublist(pd.invOffset);
      final RctKey yinv = toInvert[pd.invOffset + rounds].clone();
      cCache = List<List<int>>.generate(1 << rounds, (_) => RCT.zero());
      cCache[0] = cInv[0].clone();
      cCache[1] = pd.challenges[0].clone();
      for (int j = 1; j < rounds; ++j) {
        final int slots = 1 << (j + 1);
        for (int s = slots; s-- > 0; --s) {
          cCache[s] = Ed25519Utils.scMulVar(cCache[s ~/ 2], pd.challenges[j]);
          cCache[s - 1] = Ed25519Utils.scMulVar(cCache[s ~/ 2], cInv[j]);
        }
      }
      RctKey eR1WY = Ed25519Utils.scMulVar(pd.e, proof.r1);
      eR1WY = Ed25519Utils.scMulVar(eR1WY, weight);
      RctKey eS1W = Ed25519Utils.scMulVar(pd.e, proof.s1);
      eS1W = Ed25519Utils.scMulVar(eS1W, weight);
      RctKey eSquaredZW = Ed25519Utils.scMulVar(eSq, pd.z);
      eSquaredZW = Ed25519Utils.scMulVar(eSquaredZW, weight);
      final RctKey minusESquaredZW =
          Ed25519Utils.scSubVar(RCTConst.z, eSquaredZW);
      RctKey minusESquaredWY = Ed25519Utils.scSubVar(RCTConst.z, eSq);
      minusESquaredWY = Ed25519Utils.scMulVar(minusESquaredWY, weight);
      minusESquaredWY = Ed25519Utils.scMulVar(minusESquaredWY, yMN);
      for (int i = 0; i < mn; ++i) {
        RctKey gSc = eR1WY.clone();
        RctKey hSc = RCT.zero();

        // Use the binary decomposition of the index
        gSc = Ed25519Utils.scMulAddVar(gSc, cCache[i], eSquaredZW);
        hSc = Ed25519Utils.scMulAddVar(
            eS1W, cCache[(~i) & (mn - 1)], minusESquaredZW);

        // Complete the scalar derivation
        giScalars[i] = Ed25519Utils.scAddVar(giScalars[i], gSc);
        hSc = Ed25519Utils.scMulAddVar(minusESquaredWY, d[i], hSc);
        hiScalars[i] = Ed25519Utils.scAddVar(hiScalars[i], hSc);

        // Update iterated values
        eR1WY = Ed25519Utils.scMulVar(eR1WY, yinv);
        minusESquaredWY = Ed25519Utils.scMulVar(minusESquaredWY, yinv);
      }

      for (int j = 0; j < rounds; ++j) {
        temp = Ed25519Utils.scMulVar(pd.challenges[j], pd.challenges[j]);
        temp = Ed25519Utils.scMulVar(temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp, point: proof8L[j]));
        temp = Ed25519Utils.scMulVar(cInv[j], cInv[j]);
        temp = Ed25519Utils.scMulVar(temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp, point: proof8R[j]));
      }
    }

    data.add(MultiexpData(scalar: gScalar, point: _gPoint));
    data.add(MultiexpData(scalar: hScalar, point: _hPoint));

    final List<MultiexpData?> nd = List.filled(2 * maxMN, null);
    for (int i = 0; i < maxMN; ++i) {
      nd[i * 2] = MultiexpData(scalar: giScalars[i], point: _getGiP3Bytes(i));
      nd[i * 2 + 1] =
          MultiexpData(scalar: hiScalars[i], point: _getHiP3Bytes(i));
    }
    data = [...nd.cast(), ...data];

    final mp = _multiexp(data: data, higiSize: 2 * maxMN);
    if (BytesUtils.bytesEqual(mp, RCT.identity(clone: false))) {
      return true;
    }
    return false;
  }
}
