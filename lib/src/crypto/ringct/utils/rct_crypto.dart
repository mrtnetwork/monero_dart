import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';

class RCT {
  static Ed25519CurveApi get ed25519 => blockchainUtils.api.ed25519;

  /// rands
  static BigInt randXmrAmount(BigInt upperAmount) {
    final r = skGen();
    final amount = h2d(r);
    return amount % upperAmount;
  }

  static RctKey pkGen() {
    final scalar = skGen();
    return scalarmultBase(scalar);
  }

  static void skpkGen(List<int> sk, List<int> pk) {
    final gn = skGen();
    pk.setAll(0, scalarmultBase(gn));
    for (int i = 0; i < 32; i++) {
      sk[i] = gn[i];
    }
  }

  static RctKey skGen() {
    while (true) {
      final rand = QuickCrypto.generateRandom();
      final reduced = ed25519.scReduce(rand);
      if (ed25519.scIsNonZero(reduced)) {
        return reduced;
      }
    }
  }

  static RctKey hashToP3Bytes(List<int> k) {
    return ed25519.hashToEc(k);
  }

  static RctKey addKeys(List<int> a, List<int> b) {
    return ed25519.add(a, b);
  }

  static RctKey addKeysBatch(KeyV A) {
    if (A.isEmpty) {
      return identity();
    }
    RctKey acc = A[0].asBytes;
    try {
      for (int i = 1; i < A.length; ++i) {
        acc = ed25519.add(acc, A[i]);
      }
    } catch (_) {
      throw BuError(DefaultErrorType.invalidPoint, "Point conversion failed.");
    }
    return acc;
  }

  static RctKey genC(List<int> a, BigInt amount) {
    return addKeys2(a, d2h(amount), RCTConst.h);
  }

  static RctKey scalarmultBase(List<int> a) {
    return ed25519.reduceMultBase(a);
  }

  static RctKey scalarmultH(List<int> a) {
    // Reduce first: the backend rejects non-canonical scalars while the
    // previous code multiplied raw bytes; (a mod L) * P is the same point.
    return ed25519.mult(ed25519.scReduce(a), RCTConst.h);
  }

  static RctKey commit({required BigInt xmrAmount, required List<int> mask}) {
    return genC(mask, xmrAmount);
  }

  static RctKey scalarmultKey(List<int> p, List<int> a) {
    return ed25519.mult(a, p);
  }

  static RctKey scalarmult8(List<int> p) {
    try {
      return ed25519.mul8(p);
    } catch (_) {
      throw BuError(DefaultErrorType.invalidPoint, "invalid point");
    }
  }

  static EdwardsLimbPoint scalarmult8Point(List<int> p) {
    return asPoint(ed25519.mul8(p));
  }

  static RctKey asValidScalar(List<int> sc) {
    if (!ed25519.scCheck(sc)) {
      throw BuError(DefaultErrorType.invalidScalar, "Invalid scalar bytes.");
    }
    return sc.asBytes;
  }

  static RctKey genAmountEncodingFactor(List<int> k) {
    final data = [
      ..."amount".codeUnits,
      ...k.exc(
        length: 32,
        operation: "genAmountEncodingFactor",
        name: "k",
        reason: "Invalid bytes length.",
      ),
    ];
    return QuickCrypto.keccak256Hash(data);
  }

  static RctKey d2hInt(int v) {
    return BigInt.from(v).toLeBytes(length: 32);
  }

  static RctKey d2h(BigInt amount) {
    return amount.asU64.toLeBytes(length: 32);
  }

  static BigInt h2d(List<int> amoutBytes) {
    return BigintUtils.fromBytes(
      amoutBytes,
      byteOrder: Endian.little,
    ).toUnsigned(64);
  }

  static RctKey identity({bool clone = true}) {
    if (clone) {
      return RCTConst.i.clone();
    }
    return RCTConst.i;
  }

  static RctKey zero({bool clone = true}) {
    if (clone) {
      return RCTConst.z.clone();
    }
    return RCTConst.z;
  }

  static EdwardsLimbPoint asPoint(List<int> key) {
    return EdwardsLimbPoint.fromBytes(key);
  }

  static RctKey subKeys(List<int> A, List<int> B) {
    return ed25519.sub(A, B);
  }

  static RctKey genCommitmentMask(List<int> key) {
    final data = <int>[..."commitment_mask".codeUnits, ...key];
    return hashToScalar(data);
  }

  static RctKey hashToScalar(List<int> data) {
    return ed25519.scReduce(QuickCrypto.keccak256Hash(data));
  }

  static RctKey hashToScalarKeys(KeyV data) {
    return ed25519.scReduce(
      QuickCrypto.keccak256Hash(data.expand((e) => e).toList()),
    );
  }

  static void _xor8(List<int> v, List<int> k) {
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
      _xor8(amount, amountFactor);
      return EcdhTuple(amount: amount, mask: mask, version: EcdhInfoVersion.v2);
    } else {
      final e = ecdh.cast<EcdhInfoV1>();
      final RctKey sharedSec1 = RCT.hashToScalar(sharedSec);
      final RctKey sharedSec2 = RCT.hashToScalar(sharedSec1);
      final RctKey mask = BuBytes.fill(32);
      final RctKey amount = BuBytes.fill(32);

      mask.setAll(0, ed25519.scSub(e.mask, sharedSec1));
      amount.setAll(0, ed25519.scSub(e.amount, sharedSec2));
      return EcdhTuple(amount: amount, mask: mask, version: EcdhInfoVersion.v1);
    }
  }

  static EcdhInfo ecdhEncode(EcdhTuple unmasked, List<int> sharedSec) {
    if (unmasked.version == EcdhInfoVersion.v2) {
      if (unmasked.amount.length != 32) {
        throw BuError(DefaultErrorType.invalidLength, 
          "Invalid unmasked amount length ${unmasked.amount.length}: expected 32 bytes.",
        );
      }
      final amount = unmasked.amount.clone();
      _xor8(amount, genAmountEncodingFactor(sharedSec));
      return EcdhInfoV2(amount.sublist(0, 8));
    } else {
      final RctKey sharedSec1 = hashToScalar(sharedSec);
      final RctKey sharedSec2 = hashToScalar(sharedSec1);
      final mask = unmasked.mask.clone();
      final amount = unmasked.amount.clone();

      mask.setAll(0, ed25519.scAdd(mask, sharedSec1));
      amount.setAll(0, ed25519.scAdd(amount, sharedSec2));
      return EcdhInfoV1(amount: amount, mask: mask);
    }
  }

  static RctKey strToKey(String data) {
    List<int> toBytes = data.codeUnits;

    if (toBytes.length > 32) {
      throw BuError(DefaultErrorType.invalidLength, 
        "Invalid key string: length ${toBytes.length} exceeds 32 bytes.",
      );
    }
    final key = RCT.zero();
    for (int i = 0; i < toBytes.length; i++) {
      key[i] = toBytes[i];
    }
    return key;
  }

  static RctKey addKeys2(List<int> a, List<int> b, List<int> B) {
    // Preserve current validation order: invalid point throws before the
    // all-zero-scalars identity shortcut below.
    asPoint(B);
    if (!ed25519.scIsNonZero(a) && !ed25519.scIsNonZero(b)) {
      return identity();
    }
    // NOTE swapped: the backend computes `a-param * point + b-param * G`,
    // while here `a` scales G and `b` scales the point.
    return ed25519.geDoubleScalarMultBasePointVar(a: b, g: B, b: a);
  }
}
