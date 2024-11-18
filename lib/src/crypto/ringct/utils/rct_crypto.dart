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

import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class RCT {
  static List<List<List<int>>> keyMInit(int rows, int cols) {
    final rv = List<List<List<int>>>.filled(cols, []);
    for (int i = 0; i < cols; i++) {
      rv[i] = List<List<int>>.generate(rows, (_) => zero());
    }
    return rv;
  }

  static bool toPointCheckOrder(GroupElementP3 p, List<int> data) {
    if (CryptoOps.geFromBytesVartime_(p, data) != 0) {
      return false;
    }
    final GroupElementP2 R = GroupElementP2();
    CryptoOps.geScalarMult(R, RCTConst.l, p);
    final RctKey tmp = zero();
    CryptoOps.geToBytes(tmp, R);
    return BytesUtils.bytesEqual(tmp, identity(clone: false));
  }

  // static bool less32(List<int> k0, List<int> k1) {
  //   for (int n = 31; n >= 0; --n) {
  //     if (k0[n] < k1[n]) return true;
  //     if (k0[n] > k1[n]) return false;
  //   }
  //   return false;
  // }

  static List<int> skGen_() {
    while (true) {
      final rand = QuickCrypto.generateRandom();
      // if (!less32(rand, RCTConst.limit)) {
      //   continue;
      // }
      CryptoOps.scReduce32(rand);
      if (CryptoOps.scIsNonZero(rand) != 0) {
        return rand;
      }
    }
  }

  static void skGen(RctKey key) {
    final gn = skGen_();
    for (int i = 0; i < 32; i++) {
      key[i] = gn[i];
    }
  }

  static GroupElementP3 hashToP3_(List<int> k) {
    final GroupElementP3 generator = GroupElementP3();
    hashToP3(generator, k);
    return generator;
  }

  static void hashToP3(GroupElementP3 p3, List<int> k) {
    final hashKey = QuickCrypto.keccack256Hash(k);
    final GroupElementP2 hashP2 = GroupElementP2();
    CryptoOps.geFromfeFrombytesVartime(hashP2, hashKey);
    final GroupElementP1P1 hash8P1p1 = GroupElementP1P1();
    CryptoOps.geMul8(hash8P1p1, hashP2);
    CryptoOps.geP1P1ToP3(p3, hash8P1p1);
  }

  static BigInt randXmrAmount(BigInt upperAmount) {
    final r = skGen_();
    final amount = h2d(r);
    return amount % upperAmount;
  }

  static List<int> pkGen() {
    final scalar = skGen_();
    return _pkGen(scalar);
  }

  static List<int> _pkGen(List<int> scalar) {
    return scalarmultBase_(scalar);
  }

  static Tuple<List<int>, List<int>> skpkGen_() {
    final secret = skGen_();
    final pk = _pkGen(secret);
    return Tuple(secret, pk);
  }

  static void skpkGen(RctKey sk, RctKey pk) {
    skGen(sk);
    scalarmultBase(pk, sk);
  }

  static void addKeys(List<int> ab, List<int> a, List<int> b) {
    final GroupElementP3 b2 = GroupElementP3(), a2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, b) != 0) {
      throw const MoneroCryptoException("Invalid pount.");
    }
    if (CryptoOps.geFromBytesVartime_(a2, a) != 0) {
      throw const MoneroCryptoException("Invalid pount.");
    }
    final GroupElementCached tmp2 = GroupElementCached();
    CryptoOps.geP3ToCached(tmp2, b2);
    final GroupElementP1P1 tmp3 = GroupElementP1P1();
    CryptoOps.geAdd(tmp3, a2, tmp2);
    CryptoOps.geP1P1ToP3(a2, tmp3);
    CryptoOps.geP3Tobytes(ab, a2);
  }

  static RctKey addKeysBatch(KeyV A) {
    if (A.isEmpty) {
      return identity();
    }
    final GroupElementP3 p3 = GroupElementP3(), tmp = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(p3, A[0]) != 0) {
      throw const MoneroCryptoException("point convertion failed.");
    }
    for (int i = 1; i < A.length; ++i) {
      if (CryptoOps.geFromBytesVartime_(tmp, A[i]) != 0) {
        throw const MoneroCryptoException("point convertion failed.");
      }
      final GroupElementCached p2 = GroupElementCached();
      CryptoOps.geP3ToCached(p2, tmp);
      final GroupElementP1P1 p1 = GroupElementP1P1();
      CryptoOps.geAdd(p1, p3, p2);
      CryptoOps.geP1P1ToP3(p3, p1);
    }
    final RctKey res = zero();
    CryptoOps.geP3Tobytes(res, p3);
    return res;
  }

  static List<int> addKeys_(List<int> a, List<int> b) {
    final List<int> ab = zero();
    addKeys(ab, a, b);
    return ab;
  }

  static List<int> pk2rct(List<int> pubkey) {
    return pubkey;
  }

  static List<int> addKeys2_(List<int> a, List<int> b, List<int> pB) {
    final RctKey aGbB = zero();
    addKeys2(aGbB, a, b, pB);
    return aGbB;
  }

  static void addKeys2(RctKey aGbB, RctKey a, RctKey b, RctKey B) {
    final GroupElementP2 rv = GroupElementP2();
    final GroupElementP3 b2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, B) != 0) {
      throw const MoneroCryptoException("Invalid point.");
    }
    CryptoOps.geDoubleScalarMultBaseVartime(rv, b, b2, a);
    CryptoOps.geToBytes(aGbB, rv);
  }

  static void addKeys3(
      RctKey aAbB, RctKey a, RctKey A, RctKey b, GroupElementDsmp B) {
    final GroupElementP2 rv = GroupElementP2();
    final GroupElementP3 a2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(a2, A) != 0) {
      throw const MoneroCryptoException("Invalid point");
    }
    CryptoOps.geDoubleScalarMultPrecompVartime(rv, a, a2, b, B);
    CryptoOps.geToBytes(aAbB, rv);
  }

  static void addKeys3_(
      RctKey aAbB, RctKey a, GroupElementDsmp A, RctKey b, GroupElementDsmp B) {
    final GroupElementP2 rv = GroupElementP2();
    CryptoOps.geDoubleScalarMultPrecompVartime2(rv, a, A, b, B);
    CryptoOps.geToBytes(aAbB, rv);
  }

  static List<int> genC_(List<int> a, BigInt amount) {
    final RctKey c = zero();
    genC(c, a, amount);
    return c;
  }

  static void genC(RctKey c, RctKey a, BigInt amount) {
    addKeys2(c, a, d2h(amount), RCTConst.h);
  }

  static List<int> scalarmultBase_(List<int> a) {
    final List<int> ag = zero();
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.scReduce32Copy(ag, a);
    CryptoOps.geScalarMultBase(point, ag);
    CryptoOps.geP3Tobytes(ag, point);
    return ag;
  }

  static void scalarmultBase(List<int> ag, List<int> a) {
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.scReduce32Copy(ag, a);
    CryptoOps.geScalarMultBase(point, ag);
    CryptoOps.geP3Tobytes(ag, point);
  }

  static List<int> scalarmultH(List<int> a) {
    final GroupElementP2 R = GroupElementP2();
    CryptoOps.geScalarMult(R, a, RCTConst.geP3H);
    final aP = zero();
    CryptoOps.geToBytes(aP, R);
    return aP;
  }

  static Tuple<CtKey, CtKey> ctskpkGen(BigInt xmrAmount) {
    final am = d2h(xmrAmount);
    final bh = scalarmultH(am);
    return ctskpkGenfromBh(bh);
  }

  static Tuple<CtKey, CtKey> ctskpkGenfromBh(List<int> bh) {
    final sk = skpkGen_();
    final pk = skpkGen_();
    final mask = addKeys_(pk.item2, bh);
    return Tuple(CtKey(dest: sk.item1, mask: pk.item1),
        CtKey(dest: sk.item2, mask: mask));
  }

  static List<int> commit({
    required BigInt xmrAmount,
    required List<int> mask,
  }) {
    return genC_(mask, xmrAmount);
  }

  static List<int> scalarmultKey_(List<int> p, List<int> a) {
    final ap = zero();
    scalarmultKey(ap, p, a);
    return ap;
  }

  static void scalarmultKey(RctKey ap, List<int> p, List<int> a) {
    final GroupElementP3 aP3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(aP3, p) != 0) {
      throw const MoneroCryptoException("Invalid scalar key.");
    }
    final GroupElementP2 r = GroupElementP2();
    CryptoOps.geScalarMult(r, a, aP3);
    CryptoOps.geToBytes(ap, r);
  }

  static void scalarmult8(GroupElementP3 res, List<int> p) {
    final GroupElementP3 p3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(p3, p) != 0) {
      throw const MoneroCryptoException("invalid point");
    }
    final GroupElementP2 p2 = GroupElementP2();
    CryptoOps.geP3ToP2(p2, p3);
    final GroupElementP1P1 p1 = GroupElementP1P1();
    CryptoOps.geMul8(p1, p2);
    CryptoOps.geP1P1ToP3(res, p1);
  }

  static RctKey scalarmult8_(RctKey p) {
    final GroupElementP3 p3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(p3, p) != 0) {
      throw const MoneroCryptoException("invalid point");
    }
    final GroupElementP2 p2 = GroupElementP2();
    CryptoOps.geP3ToP2(p2, p3);
    final GroupElementP1P1 p1 = GroupElementP1P1();
    CryptoOps.geMul8(p1, p2);
    CryptoOps.geP1P1ToP2(p2, p1);
    final RctKey res = RCT.zero();
    CryptoOps.geToBytes(res, p2);
    return res;
  }

  static bool isInMainSubgroup(List<int> a) {
    final GroupElementP3 p = GroupElementP3();
    return toPointCheckOrder(p, a);
  }

  static void addKeys1(
      {required RctKey aGbB, required RctKey a, required RctKey b}) {
    final ag = scalarmultBase_(a);
    addKeys(aGbB, ag, b);
  }

  static List<int> genAmountEncodingFactor(List<int> k) {
    final data = [..."amount".codeUnits, ...k.exceptedLen(32)];
    return QuickCrypto.keccack256Hash(data);
  }

  static List<int> d2hInt(int v) {
    return BigintUtils.toBytes(BigInt.from(v),
        length: 32, order: Endian.little);
  }

  static List<int> d2h(BigInt amount) {
    return BigintUtils.toBytes(amount.asUint64,
        length: 32, order: Endian.little);
  }

  static BigInt h2d(List<int> amoutBytes) {
    return BigintUtils.fromBytes(amoutBytes, byteOrder: Endian.little)
        .toUnsigned(64);
  }

  static List<int> zeroCommit(BigInt amount) {
    final am = d2h(amount);
    final bh = scalarmultH(am);
    return addKeys_(RCTConst.g, bh);
  }

  static List<int> identity({bool clone = true}) {
    if (clone) {
      return RCTConst.i.clone();
    }
    return RCTConst.i;
  }

  static List<int> zero({bool clone = true}) {
    if (clone) {
      return RCTConst.z.clone();
    }
    return RCTConst.z;
  }

  static Bits bits() {
    return List<int>.filled(64, 0);
  }

  static void d2b(Bits amountb, BigInt val) {
    int i = 0;
    while (i < 64) {
      amountb[i++] = (val & BigInt.one).toInt();
      val >>= 1;
    }
  }

  static void subKeys(RctKey ab, RctKey A, RctKey B) {
    final GroupElementP3 b2 = GroupElementP3(), a2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, B) != 0) {
      throw const MoneroCryptoException("Invalid point");
    }
    if (CryptoOps.geFromBytesVartime_(a2, A) != 0) {
      throw const MoneroCryptoException("Invalid point");
    }
    final GroupElementCached tmp2 = GroupElementCached();
    CryptoOps.geP3ToCached(tmp2, b2);
    final GroupElementP1P1 tmp3 = GroupElementP1P1();
    CryptoOps.geSub(tmp3, a2, tmp2);
    CryptoOps.geP1P1ToP3(a2, tmp3);
    CryptoOps.geP3Tobytes(ab, a2);
  }

  static List<int> genCommitmentMask(List<int> key) {
    final data = <int>[..."commitment_mask".codeUnits, ...key];
    return hashToScalarBytes(data);
  }

  static void hashToScalar(List<int> res, List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    CryptoOps.scReduce32(h);
    for (int i = 0; i < h.length; i++) {
      res[i] = h[i];
    }
  }

  static List<int> scalarFast(List<int> scalar) {
    final toint = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final reduce = toint % Curves.generatorED25519.order!;
    final tobytes = BigintUtils.toBytes(reduce,
        order: Endian.little,
        length: BigintUtils.orderLen(Curves.generatorED25519.order!));
    return tobytes;
  }

  static List<int> hashToScalarFast_(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    return scalarFast(h);
  }

  static List<int> hashToScalar_(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    CryptoOps.scReduce32(h);
    return h;
  }

  static List<int> hashToScalarKeys(KeyV data) {
    final h = QuickCrypto.keccack256Hash(data.expand((e) => e).toList());
    CryptoOps.scReduce32(h);
    return h;
  }

  static void addKeysAGbBcC(RctKey aGbBcC, RctKey a, RctKey b,
      GroupElementDsmp B, RctKey c, GroupElementDsmp C) {
    final GroupElementP2 rv = GroupElementP2();
    CryptoOps.geTripleScalarMultBaseVartime(rv, a, b, B, c, C);
    CryptoOps.geToBytes(aGbBcC, rv);
  }

  static void addKeysAAbBcC(RctKey aAbBcC, RctKey a, GroupElementDsmp A,
      RctKey b, GroupElementDsmp B, RctKey c, GroupElementDsmp C) {
    final GroupElementP2 rv = GroupElementP2();
    CryptoOps.geTripleScalarMultBasePrecompVartime(rv, a, A, b, B, c, C);
    CryptoOps.geToBytes(aAbBcC, rv);
  }

  static List<int> hashToScalarBytes(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    CryptoOps.scReduce32(h);
    return h;
  }

  static void precomp(GroupElementDsmp rv, RctKey b) {
    final GroupElementP3 b2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, b) != 0) {
      throw const MoneroCryptoException("Invalid point");
    }
    CryptoOps.geDsmPrecomp(rv, b2);
  }

  static void xor8(List<int> v, List<int> k) {
    for (int i = 0; i < 8; ++i) {
      v[i] ^= k[i];
    }
  }

  static EcdhTuple ecdhDecode(
      {required EcdhInfo ecdh, required List<int> sharedSec}) {
    //decode
    if (ecdh.version == EcdhInfoVersion.v2) {
      final mask = genCommitmentMask(sharedSec);
      final amountFactor = genAmountEncodingFactor(sharedSec);
      final amount = zero()..setAll(0, ecdh.amount);
      xor8(amount, amountFactor);
      return EcdhTuple(amount: amount, mask: mask, version: EcdhInfoVersion.v2);
    } else {
      final e = ecdh.cast<EcdhInfoV1>();
      final List<int> sharedSec1 = RCT.hashToScalar_(sharedSec);
      final List<int> sharedSec2 = RCT.hashToScalar_(sharedSec1);
      final List<int> mask = List<int>.filled(32, 0);
      final List<int> amount = List<int>.filled(32, 0);
      CryptoOps.scSub(mask, e.mask, sharedSec1);
      CryptoOps.scSub(amount, e.amount, sharedSec2);
      return EcdhTuple(amount: amount, mask: mask, version: EcdhInfoVersion.v1);
    }
  }

  static EcdhInfo ecdhEncode(EcdhTuple unmasked, RctKey sharedSec) {
    if (unmasked.version == EcdhInfoVersion.v2) {
      final amount = unmasked.amount.clone();
      xor8(amount, genAmountEncodingFactor(sharedSec));
      return EcdhInfoV2(amount.sublist(0, 8));
    } else {
      final RctKey sharedSec1 = hashToScalarBytes(sharedSec);
      final RctKey sharedSec2 = hashToScalarBytes(sharedSec1);
      final mask = unmasked.mask.clone();
      final amount = unmasked.amount.clone();
      CryptoOps.scAdd(mask, mask, sharedSec1);
      CryptoOps.scAdd(amount, amount, sharedSec2);
      return EcdhInfoV1(amount: amount, mask: mask);
    }
  }

  static RctKey strToKey(String data) {
    List<int> toBytes = data.codeUnits;
    if (toBytes.length > 32) {
      toBytes = toBytes.sublist(0, 32);
    }
    final key = RCT.zero();
    for (int i = 0; i < toBytes.length; i++) {
      key[i] = toBytes[i];
    }
    return key;
  }
}
