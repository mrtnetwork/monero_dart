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
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';

class RCT {
  /// rands
  static BigInt randXmrAmount(BigInt upperAmount) {
    final r = skGen_();
    final amount = h2d(r);
    return amount % upperAmount;
  }

  static List<int> pkGenVar() {
    final scalar = skGen_();
    return scalarmultBaseVar(scalar);
  }

  static List<int> pkGen() {
    final scalar = skGen_();
    return scalarmultBase(scalar);
  }

  static void skpkGen(RctKey sk, RctKey pk) {
    skGen(sk);
    scalarmultBase(sk, result: pk);
  }

  static List<int> skGen_() {
    while (true) {
      final rand = QuickCrypto.generateRandom();
      CryptoOps.scReduce32(rand);
      if (CryptoOps.scIsNonZero(rand) != 0) {
        return rand;
      }
    }
  }

  static List<int> skGenVar() {
    while (true) {
      final rand = Ed25519Utils.scalarReduceVar(QuickCrypto.generateRandom());
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

  // static bool toPointCheckOrder(GroupElementP3 p, List<int> data) {
  //   if (CryptoOps.geFromBytesVartime_(p, data) != 0) {
  //     return false;
  //   }
  //   final GroupElementP2 R = GroupElementP2();
  //   CryptoOps.geScalarMult(R, RCTConst.l, p);
  //   final RctKey tmp = zero();
  //   CryptoOps.geToBytes(tmp, R);
  //   return BytesUtils.bytesEqual(tmp, identity(clone: false));
  // }

  static void hashToP3(GroupElementP3 p3, List<int> k) {
    final hashKey = QuickCrypto.keccack256Hash(k);
    final GroupElementP2 hashP2 = GroupElementP2();
    CryptoOps.geFromfeFrombytesVartime(hashP2, hashKey);
    final GroupElementP1P1 hash8P1p1 = GroupElementP1P1();
    CryptoOps.geMul8(hash8P1p1, hashP2);
    CryptoOps.geP1P1ToP3(p3, hash8P1p1);
  }

  static List<int> hashToP3Bytes(List<int> k) {
    final GroupElementP3 p3 = GroupElementP3();
    hashToP3(p3, k);
    return CryptoOps.geP3Tobytes_(p3);
  }

  static EDPoint hashToPoint(List<int> k) {
    return asPoint(hashToP3Bytes(k));
  }

  static List<int> addKeysVar(List<int> a, List<int> b) {
    final A = asPoint(a);
    final B = asPoint(b);
    return (A + B).toBytes();
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
    final b2 = Ed25519Utils.asPoint(b);
    final a2 = Ed25519Utils.asPoint(a);
    return (b2 + a2).toBytes();
  }

  static List<int> addKeys2_(List<int> a, List<int> b, List<int> pB) {
    final RctKey aGbB = zero();
    _addKeys2(aGbB, a, b, pB);
    return aGbB;
  }

  static void _addKeys2(RctKey aGbB, RctKey a, RctKey b, RctKey B) {
    final GroupElementP2 rv = GroupElementP2();
    final GroupElementP3 b2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, B) != 0) {
      throw const MoneroCryptoException("Invalid point.");
    }
    CryptoOps.geDoubleScalarMultBaseVartime(rv, b, b2, a);
    CryptoOps.geToBytes(aGbB, rv);
  }

  static void addKeys3_(
    RctKey aAbB,
    RctKey a,
    GroupElementDsmp A,
    RctKey b,
    GroupElementDsmp B,
  ) {
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
    _addKeys2(c, a, d2h(amount), RCTConst.h);
  }

  static RctKey genCVar(RctKey a, BigInt amount) {
    return addKeys2Var(a, d2h(amount), RCTConst.h);
  }

  static List<int> scalarmultBase(List<int> a, {List<int>? result}) {
    final List<int> ag = result ?? zero();
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.scReduce32Copy(ag, a);
    CryptoOps.geScalarMultBase(point, ag);
    CryptoOps.geP3Tobytes(ag, point);
    return ag;
  }

  static List<int> scalarmultH(List<int> a) {
    final GroupElementP2 R = GroupElementP2();
    CryptoOps.geScalarMult(R, a, RCTConst.geP3H);
    final aP = zero();
    CryptoOps.geToBytes(aP, R);
    return aP;
  }

  static List<int> commit({
    required BigInt xmrAmount,
    required List<int> mask,
  }) {
    return genC_(mask, xmrAmount);
  }

  static List<int> commitVar({
    required BigInt xmrAmount,
    required List<int> mask,
  }) {
    return genCVar(mask, xmrAmount);
  }

  static List<int> scalarmultKey(List<int> p, List<int> a) {
    final ap = zero();
    _scalarmultKey(ap, p, a);
    return ap;
  }

  static void _scalarmultKey(RctKey ap, List<int> p, List<int> a) {
    final GroupElementP3 aP3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(aP3, p) != 0) {
      throw const MoneroCryptoException("Invalid scalar key.");
    }
    final GroupElementP2 r = GroupElementP2();
    CryptoOps.geScalarMult(r, a, aP3);
    CryptoOps.geToBytes(ap, r);
  }

  static RctKey scalarmultKeyVar(List<int> p, List<int> a) {
    final point = asPoint(p);
    final sc = Ed25519Utils.asScalarInt(a);
    return (point * sc).toBytes();
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

  static EDPoint scalarmult8PointVar(RctKey p) {
    EDPoint p3 = asPoint(p);
    p3 = p3 * BigInt.from(8);
    return p3;
  }

  // static bool isInMainSubgroup(List<int> a) {
  //   final GroupElementP3 p = GroupElementP3();
  //   return toPointCheckOrder(p, a);
  // }

  static List<int> asValidScalar(List<int> sc) {
    final r = CryptoOps.scCheck(sc);
    if (r != 0) {
      throw const MoneroCryptoException("Invalid scalar bytes.");
    }
    return sc;
  }

  static List<int> genAmountEncodingFactor(List<int> k) {
    final data = [
      ..."amount".codeUnits,
      ...k.exc(
        length: 32,
        operation: "genAmountEncodingFactor",
        name: "k",
        reason: "Invalid bytes length.",
      ),
    ];
    return QuickCrypto.keccack256Hash(data);
  }

  static List<int> d2hInt(int v) {
    return BigintUtils.toBytes(
      BigInt.from(v),
      length: 32,
      order: Endian.little,
    );
  }

  static List<int> d2h(BigInt amount) {
    return BigintUtils.toBytes(amount.asU64, length: 32, order: Endian.little);
  }

  static BigInt h2d(List<int> amoutBytes) {
    return BigintUtils.fromBytes(
      amoutBytes,
      byteOrder: Endian.little,
    ).toUnsigned(64);
  }

  // static List<int> zeroCommit(BigInt amount) {
  //   final am = d2h(amount);
  //   final bh = scalarmultH(am);
  //   return addKeys_(RCTConst.g, bh);
  // }

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

  static EDPoint asPoint(RctKey key) {
    return EDPoint.fromBytes(curve: Curves.curveEd25519, data: key);
  }

  static RctKey subKeysVar(RctKey A, RctKey B) {
    final b2 = asPoint(B);
    final a2 = asPoint(A);
    final sub = (a2 + (-b2)).toBytes();
    return sub;
  }

  static List<int> genCommitmentMask(List<int> key) {
    final data = <int>[..."commitment_mask".codeUnits, ...key];
    return hashToScalarBytes(data);
  }

  static List<int> genCommitmentMaskVar(List<int> key) {
    final data = <int>[..."commitment_mask".codeUnits, ...key];
    return hashToScalarBytesVar(data);
  }

  static void hashToScalar(List<int> res, List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    CryptoOps.scReduce32(h);
    for (int i = 0; i < h.length; i++) {
      res[i] = h[i];
    }
  }

  static List<int> hashToScalarVar(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    return Ed25519Utils.scalarReduceVar(h);
  }

  static List<int> hashToScalar_(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    return Ed25519Utils.scalarReduceConst(h);
  }

  static List<int> hashToScalarKeys(KeyV data) {
    final h = QuickCrypto.keccack256Hash(data.expand((e) => e).toList());
    return Ed25519Utils.scalarReduceConst(h);
  }

  static List<int> hashToScalarKeysVar(KeyV data) {
    final h = QuickCrypto.keccack256Hash(data.expand((e) => e).toList());
    return Ed25519Utils.scalarReduceVar(h);
  }

  static RctKey addKeysAGbBcCVar(
    RctKey a,
    RctKey b,
    List<EDPoint> B,
    RctKey c,
    List<EDPoint> C,
  ) {
    return CryptoOps.geTripleScalarMultBasePointVar(
      a: a,
      b: b,
      bI: B,
      c: c,
      cI: C,
    ).toBytes();
  }

  static RctKey addKeysAAbBcCVar(
    RctKey a,
    List<EDPoint> A,
    RctKey b,
    List<EDPoint> B,
    RctKey c,
    List<EDPoint> C,
  ) {
    return CryptoOps.geTripleScalarMultPrecompPointVar(
      a,
      A,
      b,
      B,
      c,
      C,
    ).toBytes();
  }

  static List<int> hashToScalarBytes(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    CryptoOps.scReduce32(h);
    return h;
  }

  static List<int> hashToScalarBytesVar(List<int> data) {
    final h = QuickCrypto.keccack256Hash(data);
    return Ed25519Utils.scalarReduceVar(h);
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

  static EcdhTuple ecdhDecode({
    required EcdhInfo ecdh,
    required List<int> sharedSec,
  }) {
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

  static EcdhTuple ecdhDecodeVar({
    required EcdhInfo ecdh,
    required List<int> sharedSec,
  }) {
    //decode
    if (ecdh.version == EcdhInfoVersion.v2) {
      final mask = genCommitmentMaskVar(sharedSec);
      final amountFactor = genAmountEncodingFactor(sharedSec);
      final amount = zero()..setAll(0, ecdh.amount);
      xor8(amount, amountFactor);
      return EcdhTuple(amount: amount, mask: mask, version: EcdhInfoVersion.v2);
    } else {
      final e = ecdh.cast<EcdhInfoV1>();
      final List<int> sharedSec1 = RCT.hashToScalarVar(sharedSec);
      final List<int> sharedSec2 = RCT.hashToScalarVar(sharedSec1);
      final mask = Ed25519Utils.scSubVar(e.mask, sharedSec1);
      final amount = Ed25519Utils.scSubVar(e.amount, sharedSec2);
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

  static EcdhInfo ecdhEncodeVar(EcdhTuple unmasked, RctKey sharedSec) {
    if (unmasked.version == EcdhInfoVersion.v2) {
      final amount = unmasked.amount.clone();
      xor8(amount, genAmountEncodingFactor(sharedSec));
      return EcdhInfoV2(amount.sublist(0, 8));
    } else {
      final RctKey sharedSec1 = hashToScalarBytesVar(sharedSec);
      final RctKey sharedSec2 = hashToScalarBytesVar(sharedSec1);
      RctKey mask = unmasked.mask.clone();
      RctKey amount = unmasked.amount.clone();
      mask = Ed25519Utils.scAddVar(mask, sharedSec1);
      amount = Ed25519Utils.scAddVar(amount, sharedSec2);
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

  static List<int> scalarmultBaseVar(List<int> a) {
    final sc = Ed25519Utils.asScalarInt(Ed25519Utils.scalarReduceVar(a));
    final data = Curves.generatorED25519 * sc;
    return data.toBytes();
  }

  static List<int> addKeys2Var(RctKey a, RctKey b, RctKey B) {
    final aG = Curves.generatorED25519 * Ed25519Utils.asScalarInt(a);
    final p = asPoint(B);
    final bP = p * Ed25519Utils.asScalarInt(b);
    final r = aG + bP;
    return r.toBytes();
  }
}
