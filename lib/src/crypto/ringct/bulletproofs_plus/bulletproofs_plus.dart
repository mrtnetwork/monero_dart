import 'dart:math';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/multiexp.dart';
import 'package:monero_dart/src/crypto/models/multiexp_data.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class BulletproofsPlusGenerator {
  static const int maxN = 64;
  static const int maxM = 16;

  static GroupElementP3 getExponent({required RctKey base, required int idx}) {
    final indexBytes = MoneroLayoutConst.varintInt().serialize(idx);
    final hash = QuickCrypto.keccack256Hash(
        [...base, ...RCTConst.bulletproofPlusHashKey, ...indexBytes]);

    final GroupElementP3 generator = RCT.hashToP3_(hash);
    final toBytes = CryptoOps.geP3Tobytes_(generator);
    if (BytesUtils.bytesEqual(toBytes, RCT.identity(clone: false))) {
      throw const MoneroCryptoException("Exponent is point at infinity");
    }
    return generator;
  }

  static GroupElementP3 getGiP3(int index) {
    return getExponent(base: RCTConst.h, idx: index * 2 + 1);
  }

  static GroupElementP3 getHiP3(int index) {
    return getExponent(base: RCTConst.h, idx: index * 2);
  }


  static RctKey multiexp({required List<MultiexpData> data, int higiSize = 0}) {
    if (higiSize > 0) {
      if (higiSize <= 232 && data.length == higiSize) {
        return Multiexp.straus(data: data, localCache: null, step: 0);
      }
      return Multiexp.pippenger(
          data: data,
          localCache: null,
          cacheSize: higiSize,
          c: Multiexp.getPippengerC(data.length));
    }
    if (data.length <= 95) {
      return Multiexp.straus(data: data);
    }
    return Multiexp.pippenger(
        data: data,
        localCache: null,
        cacheSize: 0,
        c: Multiexp.getPippengerC(data.length));
  }

  static List<int> vectorExponent({required KeyV a, required KeyV b}) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    if (a.length > maxN * maxM) {
      throw const MoneroCryptoException("Incompatible sizes of a and maxN");
    }
    final List<MultiexpData> multiexpData = [];
    for (int i = 0; i < a.length; i++) {
      multiexpData.add(MultiexpData(
          scalar: a[i],
          point: getGiP3(i))); // Assuming MultiexpData has a constructor
      multiexpData.add(MultiexpData(scalar: b[i], point: getHiP3(i)));
    }
    return multiexp(data: multiexpData, higiSize: a.length * 2);
  }

  static RctKey computeLR(
      int size,
      RctKey y,
      List<GroupElementP3> G,
      int g0,
      List<GroupElementP3> H,
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
    final RctKey temp = RCT.zero();
    for (int i = 0; i < size; ++i) {
      final List<int> scalar = RCT.zero();
      CryptoOps.scMul(temp, a[a0 + i], y);
      CryptoOps.scMul(scalar, temp, RCTConst.invEight);
      multiexpData[i * 2] = MultiexpData(scalar: scalar, point: G[g0 + i]);
      final List<int> scalar2 = RCT.zero();
      CryptoOps.scMul(scalar2, b[b0 + i], RCTConst.invEight);
      multiexpData[i * 2 + 1] = MultiexpData(scalar: scalar2, point: H[h0 + i]);
    }
    // MultiexpData sc = multiexpData[2 * size]!;
    List<int> scBytes = RCT.zero();
    CryptoOps.scMul(scBytes, c, RCTConst.invEight);
    GroupElementP3 hP3 = GroupElementP3();
    CryptoOps.geFromBytesVartime_(hP3, RCTConst.h);
    multiexpData[2 * size] = MultiexpData(scalar: scBytes, point: hP3);
    scBytes = RCT.zero();
    CryptoOps.scMul(scBytes, d, RCTConst.invEight);
    hP3 = GroupElementP3();
    CryptoOps.geFromBytesVartime_(hP3, RCTConst.g);
    multiexpData[2 * size + 1] = MultiexpData(scalar: scBytes, point: hP3);
    return multiexp(data: multiexpData.cast(), higiSize: 0);
  }

  static KeyV vectorOfScalarPowers(RctKey x, int n) {
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
      CryptoOps.scMul(res[i], res[i - 1], x);
    }
    return res;
  }

  static RctKey sumOfEvenPowers(RctKey x, int n) {
    if ((n & (n - 1)) != 0) {
      throw const MoneroCryptoException("Need n to be a power of 2");
    }
    if (n == 0) {
      throw const MoneroCryptoException("Need n > 0");
    }

    final RctKey x1 = x.clone();
    CryptoOps.scMul(x1, x1, x1);

    final RctKey res = x1.clone();
    while (n > 2) {
      CryptoOps.scMulAdd(res, x1, res, res);
      CryptoOps.scMul(x1, x1, x1);
      n ~/= 2;
    }

    return res;
  }

  static RctKey sumOfScalarPowers(RctKey x, int n) {
    if (n == 0) {
      throw const MoneroCryptoException("Need n > 0");
    }

    final RctKey res = RCTConst.i.clone();
    if (n == 1) {
      return x;
    }

    n += 1;
    final RctKey x1 = x.clone();

    final bool isPowerOf2 = (n & (n - 1)) == 0;
    if (isPowerOf2) {
      CryptoOps.scAdd(res, res, x1);
      while (n > 2) {
        CryptoOps.scMul(x1, x1, x1);
        CryptoOps.scMulAdd(res, x1, res, res);
        n ~/= 2;
      }
    } else {
      final RctKey prev = x1.clone();
      for (int i = 1; i < n; ++i) {
        if (i > 1) CryptoOps.scMul(prev, prev, x1);
        CryptoOps.scAdd(res, res, prev);
      }
    }
    CryptoOps.scSub(res, res, RCTConst.i);
    return res;
  }

  static RctKey weightedInnerProduct(List<RctKey> a, List<RctKey> b, RctKey y) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    final RctKey res = RCT.zero();
    final RctKey yPower = RCTConst.i.clone();
    final RctKey temp = RCT.zero();
    for (int i = 0; i < a.length; ++i) {
      CryptoOps.scMul(temp, a[i], b[i]);
      CryptoOps.scMul(yPower, yPower, y);
      CryptoOps.scMulAdd(res, temp, yPower, res);
    }
    return res;
  }

  static List<GroupElementP3> hadamardFold(
      List<GroupElementP3> v, RctKey a, RctKey b) {
    if (v.length.isOdd) {
      throw const MoneroCryptoException("Vector size should be even");
    }
    final int sz = v.length ~/ 2;
    for (int n = 0; n < sz; ++n) {
      final List<List<GroupElementCached>> c = [
        GroupElementCached.dsmp,
        GroupElementCached.dsmp
      ];
      CryptoOps.geDsmPrecomp(c[0], v[n]);
      CryptoOps.geDsmPrecomp(c[1], v[sz + n]);
      CryptoOps.geDoubleScalarMultPrecompVartime2P3(v[n], a, c[0], b, c[1]);
    }
    return v.sublist(0, sz);
  }

  static KeyV vectorAddComponentwise(KeyV a, KeyV b) {
    if (a.length != b.length) {
      throw const MoneroCryptoException("Incompatible sizes of a and b");
    }
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    for (int i = 0; i < a.length; ++i) {
      CryptoOps.scAdd(res[i], a[i], b[i]);
    }
    return res;
  }

  static KeyV vectorAdd(KeyV a, RctKey b) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    for (int i = 0; i < a.length; ++i) {
      CryptoOps.scAdd(res[i], a[i], b);
    }
    return res;
  }

  static KeyV vectorSubtract(KeyV a, RctKey b) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    for (int i = 0; i < a.length; ++i) {
      CryptoOps.scSub(res[i], a[i], b);
    }
    return res;
  }

  static KeyV vectorScalar(List<RctKey> a, RctKey x) {
    final KeyV res = List<List<int>>.generate(a.length, (_) => RCT.zero());
    for (int i = 0; i < a.length; ++i) {
      CryptoOps.scMul(res[i], a[i], x);
    }
    return res;
  }

  static RctKey sm(RctKey y, int n, RctKey x) {
    while (n-- != 0) {
      CryptoOps.scMul(y, y, y);
    }
    CryptoOps.scMul(y, y, x);
    return y;
  }

  static RctKey invert(RctKey x) {
    if (BytesUtils.bytesEqual(x, RCTConst.z)) {
      throw const MoneroCryptoException("Cannot invert zero.");
    }

    RctKey a1 = RCT.zero(),
        a10 = RCT.zero(),
        a100 = RCT.zero(),
        a11 = RCT.zero(),
        a101 = RCT.zero(),
        a111 = RCT.zero(),
        a1001 = RCT.zero(),
        a1011 = RCT.zero(),
        a1111 = RCT.zero();

    a1 = x.clone();
    CryptoOps.scMul(a10, a1, a1);
    CryptoOps.scMul(a100, a10, a10);
    CryptoOps.scMul(a11, a10, a1);
    CryptoOps.scMul(a101, a10, a11);
    CryptoOps.scMul(a111, a10, a101);
    CryptoOps.scMul(a1001, a10, a111);
    CryptoOps.scMul(a1011, a10, a1001);
    CryptoOps.scMul(a1111, a100, a1011);

    RctKey inv = RCT.zero();
    CryptoOps.scMul(inv, a1111, a1);

    inv = sm(inv, 123 + 3, a101);
    inv = sm(inv, 2 + 2, a11);
    inv = sm(inv, 1 + 4, a1111);
    inv = sm(inv, 1 + 4, a1111);
    inv = sm(inv, 4, a1001);
    inv = sm(inv, 2, a11);
    inv = sm(inv, 1 + 4, a1111);
    inv = sm(inv, 1 + 3, a101);
    inv = sm(inv, 3 + 3, a101);
    inv = sm(inv, 3, a111);
    inv = sm(inv, 1 + 4, a1111);
    inv = sm(inv, 2 + 3, a111);
    inv = sm(inv, 2 + 2, a11);
    inv = sm(inv, 1 + 4, a1011);
    inv = sm(inv, 2 + 4, a1011);
    inv = sm(inv, 6 + 4, a1001);
    inv = sm(inv, 2 + 2, a11);
    inv = sm(inv, 3 + 2, a11);
    inv = sm(inv, 3 + 2, a11);
    inv = sm(inv, 1 + 4, a1001);
    inv = sm(inv, 1 + 3, a111);
    inv = sm(inv, 2 + 4, a1111);
    inv = sm(inv, 1 + 4, a1011);
    inv = sm(inv, 3, a101);
    inv = sm(inv, 2 + 4, a1111);
    inv = sm(inv, 3, a101);
    inv = sm(inv, 1 + 2, a11);

    return inv;
  }

  static KeyV invertBatch(KeyV x) {
    final KeyV scratch = [];

    RctKey acc = RCT.identity();
    for (int n = 0; n < x.length; ++n) {
      if (BytesUtils.bytesEqual(x[n], RCT.zero(clone: false))) {
        throw const MoneroCryptoException("Cannot invert zero!");
      }
      scratch.add(acc.clone());
      if (n == 0) {
        acc = x[0].clone();
      } else {
        CryptoOps.scMul(acc, acc, x[n]);
      }
    }

    acc = invert(acc);
    final RctKey tmp = RCT.zero();
    for (int i = x.length; i-- > 0;) {
      CryptoOps.scMul(tmp, acc, x[i]);
      CryptoOps.scMul(x[i], acc, scratch[i]);
      acc = tmp.clone();
    }
    return x;
  }

  static RctKey transcriptUpdateTwo(RctKey transcript, RctKey update) {
    return RCT.hashToScalarBytes([...transcript, ...update]);
  }

  static RctKey transcriptUpdateThree(
      RctKey transcript, RctKey update0, RctKey update1) {
    return RCT.hashToScalarBytes([...transcript, ...update0, ...update1]);
  }

  static bool isReduced(RctKey scalar) {
    return CryptoOps.scCheck(scalar) == 0;
  }


  static BulletproofPlus bulletproofPlusPROVE(KeyV sv, KeyV gamma) {
    if (sv.length != gamma.length) {
      throw const MoneroCryptoException("Incompatible sizes of sv and gamma");
    }
    for (final i in sv) {
      if (!isReduced(i)) {
        throw const MoneroCryptoException("Invalid sv input");
      }
    }
    for (final i in gamma) {
      if (!isReduced(i)) {
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
    final KeyV V = List<List<int>>.generate(sv.length, (_) => RCT.zero());
    final KeyV aL = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aR = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aL8 = List<List<int>>.generate(mn, (_) => RCT.zero());
    final KeyV aR8 = List<List<int>>.generate(mn, (_) => RCT.zero());
    RctKey temp = RCT.zero();
    final RctKey temp2 = RCT.zero();

    for (int i = 0; i < sv.length; ++i) {
      final RctKey gamma8 = RCT.zero(), sv8 = RCT.zero();
      CryptoOps.scMul(gamma8, gamma[i], RCTConst.invEight);
      CryptoOps.scMul(sv8, sv[i], RCTConst.invEight);
      RCT.addKeys2(V[i], gamma8, sv8, RCTConst.h);
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
      transcript = transcriptUpdateTwo(transcript, RCT.hashToScalarKeys(V));
      final RctKey alpha = RCT.skGen_();
      final RctKey preA = vectorExponent(a: aL8, b: aR8);
      final RctKey A = RCT.zero();
      CryptoOps.scMul(temp, alpha, RCTConst.invEight);
      RCT.addKeys(A, preA, RCT.scalarmultBase_(temp));
      final RctKey y = transcriptUpdateTwo(transcript, A);

      if (BytesUtils.bytesEqual(y, RCT.zero(clone: false))) {
        return tryAgain();
      }
      transcript = RCT.hashToScalar_(y);
      // RctKey z = transcript.clone();
      if (BytesUtils.bytesEqual(transcript, RCT.zero(clone: false))) {
        return tryAgain();
      }
      final RctKey zSquared = RCT.zero();
      CryptoOps.scMul(zSquared, transcript, transcript);
      final KeyV d = List.generate(mn, (_) => RCT.zero());
      d[0] = zSquared;
      for (int i = 1; i < N; i++) {
        CryptoOps.scMul(d[i], d[i - 1], RCTConst.two);
      }
      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          CryptoOps.scMul(d[j * N + i], d[(j - 1) * N + i], zSquared);
        }
      }
      final KeyV yPowers = vectorOfScalarPowers(y, mn + 2);
      final KeyV aL1 = vectorSubtract(aL, transcript);
      KeyV aR1 = vectorAdd(aR, transcript);
      final KeyV dy = List.generate(mn, (i) => RCT.zero());

      for (int i = 0; i < mn; i++) {
        CryptoOps.scMul(dy[i], d[i], yPowers[mn - i]);
      }
      aR1 = vectorAddComponentwise(aR1, dy);
      final RctKey alpha1 = alpha.clone();
      temp = RCTConst.i.clone();
      for (int j = 0; j < sv.length; j++) {
        CryptoOps.scMul(temp, temp, zSquared);
        CryptoOps.scMul(temp2, yPowers[mn + 1], temp);
        CryptoOps.scMulAdd(alpha1, temp2, gamma[j], alpha1);
      }
      int nprime = mn;
      List<GroupElementP3> gPrime = List.generate(mn, (_) => GroupElementP3());
      List<GroupElementP3> hPrime = List.generate(mn, (_) => GroupElementP3());
      KeyV aprime = List.generate(mn, (_) => RCT.zero());
      KeyV bprime = List.generate(mn, (_) => RCT.zero());
      final RctKey yinv = invert(y);
      final KeyV yinvpow = List.generate(mn, (_) => RCT.zero());
      yinvpow[0] = RCTConst.i.clone();
      for (int i = 0; i < mn; ++i) {
        gPrime[i] = getGiP3(i);
        hPrime[i] = getHiP3(i);
        if (i > 0) {
          CryptoOps.scMul(yinvpow[i], yinvpow[i - 1], yinv);
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
        final RctKey cL = weightedInnerProduct(
            aprime.sublist(0, nprime), bprime.sublist(nprime), y);
        final RctKey cR = weightedInnerProduct(
            vectorScalar(aprime.sublist(nprime), yPowers[nprime]),
            bprime.sublist(0, nprime),
            y);
        final RctKey dL = RCT.skGen_();
        final RctKey dR = RCT.skGen_();
        L[round] = computeLR(nprime, yinvpow[nprime], gPrime, nprime, hPrime, 0,
            aprime, 0, bprime, nprime, cL, dL);
        R[round] = computeLR(nprime, yPowers[nprime], gPrime, 0, hPrime, nprime,
            aprime, nprime, bprime, 0, cR, dR);

        final RctKey challenge =
            transcriptUpdateThree(transcript, L[round], R[round]);
        transcript = challenge.clone();
        if (BytesUtils.bytesEqual(challenge, RCT.zero(clone: false))) {
          return tryAgain();
        }

        final RctKey cInv = invert(challenge);
        CryptoOps.scMul(temp, yinvpow[nprime], challenge);
        gPrime = hadamardFold(gPrime, cInv, temp);
        hPrime = hadamardFold(hPrime, challenge, cInv);

        CryptoOps.scMul(temp, cInv, yPowers[nprime]);
        aprime = vectorAddComponentwise(
            vectorScalar(aprime.sublist(0, nprime), challenge),
            vectorScalar(aprime.sublist(nprime), temp));
        bprime = vectorAddComponentwise(
            vectorScalar(bprime.sublist(0, nprime), cInv),
            vectorScalar(bprime.sublist(nprime), challenge));
        final RctKey cSq = RCT.zero();
        CryptoOps.scMul(cSq, challenge, challenge);
        final RctKey cSqInv = RCT.zero();
        CryptoOps.scMul(cSqInv, cInv, cInv);
        CryptoOps.scMulAdd(alpha1, dL, cSq, alpha1);
        CryptoOps.scMulAdd(alpha1, dR, cSqInv, alpha1);
        ++round;
      }
      // Final round computations

      final RctKey r = RCT.skGen_();
      final RctKey s = RCT.skGen_();
      final RctKey d_ = RCT.skGen_();
      final RctKey eta = RCT.skGen_();

      final List<MultiexpData> data = [];
      final RctKey sc1 = RCT.zero();
      CryptoOps.scMul(sc1, r, RCTConst.invEight);
      data.add(MultiexpData(scalar: sc1, point: gPrime[0]));
      CryptoOps.scMul(sc1, s, RCTConst.invEight);
      data.add(MultiexpData(scalar: sc1, point: hPrime[0]));
      CryptoOps.scMul(sc1, d_, RCTConst.invEight);
      final GroupElementP3 gP3 = GroupElementP3();
      CryptoOps.geFromBytesVartime_(gP3, RCTConst.g);
      data.add(MultiexpData(scalar: sc1, point: gP3));

      CryptoOps.scMul(temp, r, y);
      CryptoOps.scMul(temp, temp, bprime[0]);
      CryptoOps.scMul(temp2, s, y);
      CryptoOps.scMul(temp2, temp2, aprime[0]);
      CryptoOps.scAdd(temp, temp, temp2);
      CryptoOps.scMul(sc1, temp, RCTConst.invEight);
      final GroupElementP3 hP3 = GroupElementP3();
      CryptoOps.geFromBytesVartime_(hP3, RCTConst.h);
      data.add(MultiexpData(scalar: sc1, point: hP3));

      final RctKey a1 = multiexp(data: data, higiSize: 0);

      CryptoOps.scMul(temp, r, y);
      CryptoOps.scMul(temp, temp, s);
      CryptoOps.scMul(temp, temp, RCTConst.invEight);
      CryptoOps.scMul(temp2, eta, RCTConst.invEight);
      final RctKey B = RCT.zero();
      RCT.addKeys2(B, temp2, temp, RCTConst.h);

      final RctKey e = transcriptUpdateThree(transcript, a1, B);
      if (BytesUtils.bytesEqual(e, RCT.zero(clone: false))) {
        return tryAgain();
      }
      final RctKey eSq = RCT.zero();
      CryptoOps.scMul(eSq, e, e);

      final RctKey r1 = RCT.zero();
      CryptoOps.scMulAdd(r1, aprime[0], e, r);

      final RctKey s1 = RCT.zero();
      CryptoOps.scMulAdd(s1, bprime[0], e, s);

      final RctKey d1 = RCT.zero();
      CryptoOps.scMulAdd(d1, d_, e, eta);
      CryptoOps.scMulAdd(d1, alpha1, eSq, d1);
      return BulletproofPlus(
          a: A, a1: a1, b: B, r1: r1, d1: d1, s1: s1, l: L, r: R, v: V);
    }

    return tryAgain();
  }

  static BulletproofPlus bulletproofPlusPROVEAmouts(
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
    const int logN = 6;
    const int N = 1 << logN;
    int maxLength = 0;
    int invOffset = 0;
    int maxLogM = 0;
    final List<BpPlusProofData> proofData = [];
    List<RctKey> toInvert = [];
    for (final proof in proofs) {
      if (!isReduced(proof.r1)) {
        throw const MoneroCryptoException("Input scalar r1 not in range");
      }
      if (!isReduced(proof.s1)) {
        throw const MoneroCryptoException("Input scalar s1 not in range");
      }
      if (!isReduced(proof.d1)) {
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
      maxLength = max(maxLength, proof.l.length);
      RctKey transcript = RCTConst.bulletproofPlusinitialTranscript.clone();
      transcript =
          transcriptUpdateTwo(transcript, RCT.hashToScalarKeys(proof.v));
      final y = transcript = transcriptUpdateTwo(transcript, proof.a);
      if (BytesUtils.bytesEqual(y, RCT.zero(clone: false))) {
        throw const MoneroCryptoException("y == 0");
      }
      final z = transcript = RCT.hashToScalar_(y);
      if (BytesUtils.bytesEqual(z, RCT.zero(clone: false))) {
        throw const MoneroCryptoException("z == 0");
      }
      int M = 0;
      int logM = 0;
      for (logM = 0; (M = 1 << logM) <= maxM && M < proof.v.length; ++logM) {}
      if (proof.l.length != 6 + logM) {
        throw const MoneroCryptoException("Proof is not the expected size");
      }
      // CHECK_AND_ASSERT_MES(proof.L.size() == 6+pd.logM, false, "Proof is not the expected size");
      maxLogM = max(logM, maxLogM);

      final int rounds = logM + logN;
      if (rounds <= 0) {
        throw const MoneroCryptoException("Zero rounds");
      }
      final List<RctKey> challenges =
          List<RctKey>.generate(rounds, (_) => RCT.zero());
      for (int j = 0; j < rounds; ++j) {
        final update = transcript =
            transcriptUpdateThree(transcript, proof.l[j], proof.r[j]);
        challenges[j] = update.clone();

        if (BytesUtils.bytesEqual(challenges[j], RCT.zero(clone: false))) {
          throw const MoneroCryptoException("Some challanges is zoro");
        }
      }
      final e =
          transcript = transcriptUpdateThree(transcript, proof.a1, proof.b);
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
    final RctKey temp = RCT.zero();
    final RctKey temp2 = RCT.zero();
    List<MultiexpData> data = [];
    toInvert = invertBatch(toInvert.map((e) => e.clone()).toList());
    final RctKey gScalar = RCT.zero();
    final RctKey hScalar = RCT.zero();
    final KeyV giScalars = List.generate(maxMN, (_) => RCT.zero());
    final KeyV hiScalars = List.generate(maxMN, (_) => RCT.zero());

    int dataIndex = 0;
    KeyV cCache = [];
    final List<GroupElementP3> proof8V = [], proof8L = [], proof8R = [];
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
        final p3 = GroupElementP3();
        RCT.scalarmult8(p3, proof.v[i]);
        proof8V.add(p3);
      }
      for (int i = 0; i < proof.l.length; ++i) {
        final p3 = GroupElementP3();
        RCT.scalarmult8(p3, proof.l[i]);
        proof8L.add(p3);
      }
      for (int i = 0; i < proof.r.length; ++i) {
        final p3 = GroupElementP3();
        RCT.scalarmult8(p3, proof.r[i]);
        proof8R.add(p3);
      }
      final GroupElementP3 proof8A1 = GroupElementP3();
      final GroupElementP3 proof8B = GroupElementP3();
      final GroupElementP3 proof8A = GroupElementP3();
      RCT.scalarmult8(proof8A1, proof.a1);
      RCT.scalarmult8(proof8B, proof.b);
      RCT.scalarmult8(proof8A, proof.a);
      final RctKey yMN = pd.y.clone();
      final RctKey yMN1 = RCT.zero();
      int tempMN = mn;
      while (tempMN > 1) {
        CryptoOps.scMul(yMN, yMN, yMN);
        tempMN ~/= 2;
      }
      CryptoOps.scMul(yMN1, yMN, pd.y);
      final RctKey eSq = RCT.zero();
      CryptoOps.scMul(eSq, pd.e, pd.e);
      final RctKey zSquared = RCT.zero();
      CryptoOps.scMul(zSquared, pd.z, pd.z);
      CryptoOps.scSub(temp, RCTConst.z, eSq);
      CryptoOps.scMul(temp, temp, yMN1);
      CryptoOps.scMul(temp, temp, weight);
      for (int j = 0; j < proof8V.length; j++) {
        CryptoOps.scMul(temp, temp, zSquared);
        data.add(MultiexpData(scalar: temp, point: proof8V[j]));
      }
      CryptoOps.scMul(temp, RCTConst.minusOne, weight);
      data.add(MultiexpData(scalar: temp, point: proof8B));
      CryptoOps.scMul(temp, temp, pd.e);
      data.add(MultiexpData(scalar: temp, point: proof8A1));
      final RctKey mWeightESquared = RCT.zero();
      CryptoOps.scMul(mWeightESquared, temp, pd.e);
      data.add(MultiexpData(scalar: mWeightESquared, point: proof8A));
      CryptoOps.scMulAdd(gScalar, weight, proof.d1, gScalar);
      final KeyV d = List<List<int>>.generate(mn, (_) => RCT.zero());
      d[0] = zSquared.clone();
      for (int i = 1; i < N; i++) {
        CryptoOps.scAdd(d[i], d[i - 1], d[i - 1]);
      }

      for (int j = 1; j < M; j++) {
        for (int i = 0; i < N; i++) {
          CryptoOps.scMul(d[j * N + i], d[(j - 1) * N + i], zSquared);
        }
      }
      final RctKey sumD = RCT.zero();
      CryptoOps.scMul(
          sumD, RCTConst.twoSixtyFourMinusOne, sumOfEvenPowers(pd.z, 2 * M));
      final RctKey sumY = sumOfScalarPowers(pd.y, mn);
      CryptoOps.scSub(temp, zSquared, pd.z);
      CryptoOps.scMul(temp, temp, sumY);
      CryptoOps.scMul(temp2, yMN1, pd.z);
      CryptoOps.scMul(temp2, temp2, sumD);
      CryptoOps.scAdd(temp, temp, temp2);
      CryptoOps.scMul(temp, temp, eSq);
      CryptoOps.scMul(temp2, proof.r1, pd.y);
      CryptoOps.scMul(temp2, temp2, proof.s1);
      CryptoOps.scAdd(temp, temp, temp2);
      CryptoOps.scMulAdd(hScalar, temp, weight, hScalar);
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
          CryptoOps.scMul(cCache[s], cCache[s ~/ 2], pd.challenges[j]);
          CryptoOps.scMul(cCache[s - 1], cCache[s ~/ 2], cInv[j]);
        }
      }
      final RctKey eR1WY = RCT.zero();
      CryptoOps.scMul(eR1WY, pd.e, proof.r1);
      CryptoOps.scMul(eR1WY, eR1WY, weight);
      final RctKey eS1W = RCT.zero();
      CryptoOps.scMul(eS1W, pd.e, proof.s1);
      CryptoOps.scMul(eS1W, eS1W, weight);
      final RctKey eSquaredZW = RCT.zero();
      CryptoOps.scMul(eSquaredZW, eSq, pd.z);
      CryptoOps.scMul(eSquaredZW, eSquaredZW, weight);
      final RctKey minusESquaredZW = RCT.zero();
      CryptoOps.scSub(minusESquaredZW, RCTConst.z, eSquaredZW);
      final RctKey minusESquaredWY = RCT.zero();
      CryptoOps.scSub(minusESquaredWY, RCTConst.z, eSq);
      CryptoOps.scMul(minusESquaredWY, minusESquaredWY, weight);
      CryptoOps.scMul(minusESquaredWY, minusESquaredWY, yMN);
      for (int i = 0; i < mn; ++i) {
        final RctKey gSc = eR1WY.clone();
        final RctKey hSc = RCT.zero();

        // Use the binary decomposition of the index
        CryptoOps.scMulAdd(gSc, gSc, cCache[i], eSquaredZW);
        CryptoOps.scMulAdd(hSc, eS1W, cCache[(~i) & (mn - 1)], minusESquaredZW);

        // Complete the scalar derivation
        CryptoOps.scAdd(giScalars[i], giScalars[i], gSc);
        CryptoOps.scMulAdd(hSc, minusESquaredWY, d[i], hSc);
        CryptoOps.scAdd(hiScalars[i], hiScalars[i], hSc);

        // Update iterated values
        CryptoOps.scMul(eR1WY, eR1WY, yinv);
        CryptoOps.scMul(minusESquaredWY, minusESquaredWY, yinv);
      }
      for (int j = 0; j < rounds; ++j) {
        CryptoOps.scMul(temp, pd.challenges[j], pd.challenges[j]);
        CryptoOps.scMul(temp, temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp, point: proof8L[j]));
        CryptoOps.scMul(temp, cInv[j], cInv[j]);
        CryptoOps.scMul(temp, temp, mWeightESquared);
        data.add(MultiexpData(scalar: temp, point: proof8R[j]));
      }
    }

    data.add(MultiexpData(
        scalar: gScalar, point: CryptoOps.geFromBytesVartime(RCTConst.g)));
    data.add(MultiexpData(
        scalar: hScalar, point: CryptoOps.geFromBytesVartime(RCTConst.h)));

    final List<MultiexpData?> nd = List.filled(2 * maxMN, null);
    for (int i = 0; i < maxMN; ++i) {
      nd[i * 2] = MultiexpData(scalar: giScalars[i], point: getGiP3(i));
      nd[i * 2 + 1] = MultiexpData(scalar: hiScalars[i], point: getHiP3(i));
    }
    data = [...nd.cast(), ...data];
    final mp = multiexp(data: data, higiSize: 2 * maxMN);
    if (BytesUtils.bytesEqual(mp, RCT.identity(clone: false))) {
      return true;
    }
    return false;
  }
}

class BpPlusProofData {
  final RctKey y;
  final RctKey z;
  final RctKey e;
  final List<RctKey> challenges;
  final int logM;
  final int invOffset;
  BpPlusProofData(
      {required RctKey y,
      required RctKey z,
      required RctKey e,
      required List<RctKey> challenges,
      required this.logM,
      required this.invOffset})
      : y = y.asImmutableBytes,
        z = z.asImmutableBytes,
        e = e.asImmutableBytes,
        challenges =
            challenges.map((e) => e.asImmutableBytes).toList().immutable;
}
