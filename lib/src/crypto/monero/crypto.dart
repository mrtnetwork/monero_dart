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
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';

typedef ONRINGSIGNATURERANDOMSCALAR = List<int> Function(int pubIndex);
typedef ONRANDOMSCALAR = List<int> Function();

class MoneroCrypto {
  // /// Validates a scalar's byte representation and ensures it is valid.

  /// Validates a public key, ensuring it is in the main subgroup and not zero or identity.
  static MoneroPublicKey asValidPublicKey(MoneroPublicKey publicKey) {
    if (BytesUtils.bytesEqual(publicKey.key, RCT.zero(clone: false)) ||
        BytesUtils.bytesEqual(publicKey.key, RCT.identity(clone: false))) {
      throw const MoneroCryptoException(
          "Public key was not in prime subgroup.");
    }
    // !RCT.isInMainSubgroup(publicKey.key)
    return publicKey;
  }

  /// Adds two public keys and returns the resulting public key.
  static MoneroPublicKey addPublicKey(MoneroPublicKey a, MoneroPublicKey b) {
    final GroupElementP3 b2 = GroupElementP3(), a2 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(b2, b.key) != 0) {
      throw const MoneroCryptoException("Invalid public key.");
    }
    if (CryptoOps.geFromBytesVartime_(a2, a.key) != 0) {
      throw const MoneroCryptoException("Invalid public key.");
    }
    final GroupElementCached tmp2 = GroupElementCached();
    CryptoOps.geP3ToCached(tmp2, b2);
    final GroupElementP1P1 tmp3 = GroupElementP1P1();
    CryptoOps.geAdd(tmp3, a2, tmp2);
    CryptoOps.geP1P1ToP3(a2, tmp3);
    final resultKey = RCT.zero();
    CryptoOps.geP3Tobytes(resultKey, a2);
    return MoneroPublicKey.fromBytes(resultKey);
  }

  /// Converts a derivation and output index to a scalar value.
  static List<int> derivationToScalar(
      {required List<int> derivation, required int outIndex}) {
    derivation.as32Bytes("derivationToScalar");
    final outputIndex = MoneroLayoutConst.varint48.serialize(outIndex);
    final bytes = [...derivation.asImmutableBytes, ...outputIndex];
    final hash = RCT.hashToScalar_(bytes);
    return hash;
  }

  /// Converts a derivation and output index to a scalar value.
  static List<int> derivationToScalarVar(
      {required List<int> derivation, required int outIndex}) {
    derivation.as32Bytes("derivationToScalar");
    final outputIndex = MoneroLayoutConst.varint48.serialize(outIndex);
    final bytes = [...derivation.asImmutableBytes, ...outputIndex];
    return RCT.hashToScalarVar(bytes);
  }

  /// Derives a public key from a base public key using a derivation and output index.
  static MoneroPublicKey derivePublicKeyVar(
      {required List<int> derivation,
      required int outIndex,
      required MoneroPublicKey basePublicKey}) {
    derivation.as32Bytes("derivePublicKey");
    final RctKey scalar =
        derivationToScalarVar(derivation: derivation, outIndex: outIndex);
    final sc = Ed25519Utils.asScalarInt(scalar);
    EDPoint mb = Curves.generatorED25519 * sc;
    mb += basePublicKey.point;
    return MoneroPublicKey.fromBytes(mb.toBytes());
  }

  static List<int> derivePublicKeyBytesVar(
      {required List<int> derivation,
      required int outIndex,
      required MoneroPublicKey basePublicKey}) {
    derivation.as32Bytes("derivePublicKey");
    final RctKey scalar =
        derivationToScalarVar(derivation: derivation, outIndex: outIndex);
    final sc = Ed25519Utils.scalarAsBig(scalar);
    EDPoint mb = Curves.generatorED25519 * sc;
    mb += basePublicKey.point;
    return mb.toBytes();
  }

  /// Derives a public key from a base public key using a derivation and output index.
  static MoneroPublicKey derivePublicKey({
    required List<int> derivation,
    required int outIndex,
    required MoneroPublicKey basePublicKey,
  }) {
    derivation.as32Bytes("derivePublicKey");
    final GroupElementP3 point1 = GroupElementP3();
    final GroupElementP3 point2 = GroupElementP3();
    final GroupElementCached point3 = GroupElementCached();
    final GroupElementP1P1 point4 = GroupElementP1P1();
    final GroupElementP2 point5 = GroupElementP2();
    if (CryptoOps.geFromBytesVartime_(point1, basePublicKey.key) != 0) {
      throw const MoneroCryptoException("Invalid public key.");
    }
    final RctKey scalar =
        derivationToScalar(derivation: derivation, outIndex: outIndex);
    CryptoOps.geScalarMultBase(point2, scalar);
    CryptoOps.geP3ToCached(point3, point2);
    CryptoOps.geAdd(point4, point1, point3);
    CryptoOps.geP1P1ToP2(point5, point4);
    final resultKey = RCT.zero();
    CryptoOps.geToBytes(resultKey, point5);
    return MoneroPublicKey.fromBytes(resultKey);
  }

  static const List<int> _viewTagDomain = [
    118,
    105,
    101,
    119,
    95,
    116,
    97,
    103
  ];

  /// Derives a view tag from a derivation and output index.
  static int deriveViewTag(
      {required List<int> derivation, required int outIndex}) {
    derivation.as32Bytes("deriveViewTag");
    final outputIndex = MoneroLayoutConst.varint48.serialize(outIndex);
    final hash = QuickCrypto.keccack256Hash(
        [..._viewTagDomain, ...derivation, ...outputIndex]);
    return hash[0];
  }

  /// Generates a key image from a public key and private key.
  static List<int> generateKeyImageBytes(
      {required List<int> pubkey,
      required List<int> secretKey,
      RctKey? resultKey}) {
    final GroupElementP3 point = GroupElementP3();
    final GroupElementP2 point2 = GroupElementP2();
    RCT.hashToP3(point, pubkey);
    CryptoOps.geScalarMult(point2, secretKey, point);
    resultKey ??= RCT.zero();
    resultKey.as32Bytes("generateKeyImage");
    CryptoOps.geToBytes(resultKey, point2);
    return resultKey;
  }

  /// Generates a key image from a public key and private key.
  static List<int> generateKeyImage(
      {required MoneroPublicKey pubkey,
      required MoneroPrivateKey secretKey,
      RctKey? resultKey}) {
    final GroupElementP3 point = GroupElementP3();
    final GroupElementP2 point2 = GroupElementP2();
    RCT.hashToP3(point, pubkey.key);
    CryptoOps.geScalarMult(point2, secretKey.key, point);
    resultKey ??= RCT.zero();
    resultKey.as32Bytes("generateKeyImage");
    CryptoOps.geToBytes(resultKey, point2);
    return resultKey;
  }

  /// Generates key derivation bytes from a public key and secret key.
  static List<int> generateKeyDerivationBytes(
      {required RctKey pubkey, required RctKey secretKey, RctKey? resultKey}) {
    if (CryptoOps.scCheck(secretKey) != 0) {
      throw const MoneroCryptoException("Invalid secret key.");
    }
    final GroupElementP3 point = GroupElementP3();
    final GroupElementP2 point2 = GroupElementP2();
    final GroupElementP1P1 point3 = GroupElementP1P1();
    if (CryptoOps.geFromBytesVartime_(point, pubkey) != 0) {
      throw const MoneroCryptoException("Invalid public key.");
    }
    CryptoOps.geScalarMult(point2, secretKey, point);
    CryptoOps.geMul8(point3, point2);
    CryptoOps.geP1P1ToP2(point2, point3);
    resultKey ??= RCT.zero();
    CryptoOps.geToBytes(resultKey, point2);
    return resultKey;
  }

  /// Generates key derivation bytes from a public key and secret key.
  static List<int> generateKeyDerivationVar(
      {required MoneroPublicKey pubkey,
      required MoneroPrivateKey secretKey,
      RctKey? resultKey}) {
    final sc = secretKey.privateKey.secret;
    final p = pubkey.point;
    EDPoint se = p * sc;
    se = se * BigInt.from(8);
    return se.toBytes();
  }

  static List<int> generateKeyDerivationBytesVar(
      {required List<int> pubkey,
      required List<int> secretKey,
      RctKey? resultKey}) {
    final sc = Ed25519Utils.asScalarInt(secretKey);
    final p = RCT.asPoint(pubkey);
    EDPoint se = p * sc;
    se = se * BigInt.from(8);
    return se.toBytes();
  }

  static List<int> generateKeyDerivationBigVar(
      {required List<int> pubkey,
      required BigInt secretKey,
      RctKey? resultKey}) {
    final p = RCT.asPoint(pubkey);
    EDPoint se = p * secretKey;

    se = se * BigInt.from(8);

    return se.toBytes();
  }

  /// Generates key derivation bytes from a public key and secret key.
  static List<int> generateKeyDerivation(
      {required MoneroPublicKey pubkey,
      required MoneroPrivateKey secretKey,
      RctKey? resultKey}) {
    return generateKeyDerivationBytes(
        pubkey: pubkey.key, secretKey: secretKey.key, resultKey: resultKey);
  }

  static MECSignature generateSignature(
      {required RctKey hash,
      required RctKey publicKey,
      required RctKey secretKey,
      RctKey? k}) {
    hash.as32Bytes("generateSignature");
    publicKey.as32Bytes("generateSignature");
    secretKey.as32Bytes("generateSignature");
    while (true) {
      final GroupElementP3 tmp3 = GroupElementP3();
      k ??= RCT.skGen_();
      RCT.asValidScalar(k);
      CryptoOps.geScalarMultBase(tmp3, k);
      final comm = CryptoOps.geP3Tobytes_(tmp3);
      final c = RCT.hashToScalar_([...hash, ...publicKey, ...comm]);
      if (CryptoOps.scIsNonZero(c) == 0) {
        continue;
      }
      final r = RCT.zero();
      CryptoOps.scMulSub(r, c, secretKey, k);
      if (CryptoOps.scIsNonZero(r) == 0) {
        continue;
      }
      return MECSignature(c: c, r: r);
    }
  }

  static bool checkSignature(
      {required List<int> hash,
      required List<int> publicKey,
      required MECSignature signature}) {
    hash.as32Bytes("checkSignature");
    publicKey.as32Bytes("checkSignature");
    final p = RCT.asPoint(publicKey);

    final sR = Ed25519Utils.scCheckVar(signature.r);
    final sC = Ed25519Utils.scCheckVar(signature.c);
    if (!sR ||
        !sC ||
        BytesUtils.bytesEqual(signature.c, RCT.zero(clone: false))) {
      return false;
    }
    final comm = CryptoOps.geDoubleScalarMultBasePointVar(
            a: signature.c, gA: p, b: signature.r)
        .toBytes();

    if (BytesUtils.bytesEqual(comm, CryptoOpsConst.infinity)) {
      return false;
    }
    RctKey sH = RCT.hashToScalarBytes([...hash, ...publicKey, ...comm]);
    sH = Ed25519Utils.scSubVar(sH, signature.c);
    return CryptoOps.scIsNonZero(sH) == 0;
  }

  static MECSignature generateTxProofVar({
    required List<int> hash,
    required List<int> R,
    required List<int> A,
    required List<int>? B,
    required List<int> d,
    required List<int> r,
  }) {
    hash.as32Bytes("generateTxProof");
    R.as32Bytes("generateTxProof");
    A.as32Bytes("generateTxProof");
    B?.as32Bytes("generateTxProof");
    d.as32Bytes("generateTxProof");
    r.as32Bytes("generateTxProof");
    // sanity check
    final rP3 = Ed25519Utils.mybeAsPoint(R);
    final aP3 = Ed25519Utils.mybeAsPoint(A);
    EDPoint? bP3;
    final dP3 = Ed25519Utils.mybeAsPoint(d);
    if (rP3 == null || aP3 == null || dP3 == null) {
      throw const MoneroCryptoException("Invalid tx public keys.");
    }
    if (B != null) {
      bP3 = Ed25519Utils.mybeAsPoint(B);
      if (bP3 == null) {
        throw const MoneroCryptoException("Invalid tx public keys.");
      }
    }
    final k = RCT.skGen_();
    final sK = Ed25519Utils.asScalarInt(k);

    final sep = QuickCrypto.keccack256Hash("TXPROOF_V2".codeUnits);
    List<int> x;
    List<int> y;
    if (bP3 != null) {
      x = (bP3 * sK).toBytes();
    } else {
      x = (Curves.generatorED25519 * sK).toBytes();
    }
    y = (aP3 * sK).toBytes();
    final c = RCT.hashToScalar_([
      ...hash,
      ...d,
      ...x,
      ...y,
      ...sep,
      ...R,
      ...A,
      ...B ?? CryptoOpsConst.zero
    ]);
    final List<int> sigR = RCT.zero();
    CryptoOps.scMulSub(sigR, c, r, k);
    return MECSignature(c: c, r: sigR);
  }

  /// generate tx proof
  static MECSignature generateTxProof({
    required List<int> hash,
    required List<int> R,
    required List<int> A,
    required List<int>? B,
    required List<int> d,
    required List<int> r,
  }) {
    hash.as32Bytes("generateTxProof");
    R.as32Bytes("generateTxProof");
    A.as32Bytes("generateTxProof");
    B?.as32Bytes("generateTxProof");
    d.as32Bytes("generateTxProof");
    r.as32Bytes("generateTxProof");
    // sanity check
    final GroupElementP3 rP3 = GroupElementP3();
    final GroupElementP3 aP3 = GroupElementP3();
    final GroupElementP3 bP3 = GroupElementP3();
    final GroupElementP3 dP3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(rP3, R) != 0) {
      throw const MoneroCryptoException("tx pubkey is invalid");
    }
    if (CryptoOps.geFromBytesVartime_(aP3, A) != 0) {
      throw const MoneroCryptoException("recipient view pubkey is invalid");
    }
    if (B != null && CryptoOps.geFromBytesVartime_(bP3, B) != 0) {
      throw const MoneroCryptoException("recipient spend pubkey is invalid");
    }
    if (CryptoOps.geFromBytesVartime_(dP3, d) != 0) {
      throw const MoneroCryptoException("key derivation is invalid");
    }

    final k = RCT.skGen_();

    final sep = QuickCrypto.keccack256Hash("TXPROOF_V2".codeUnits);
    List<int> x;
    List<int> y;
    if (B != null) {
      // compute x = k*B
      final GroupElementP2 xP2 = GroupElementP2();
      CryptoOps.geScalarMult(xP2, k, bP3);
      x = CryptoOps.geTobytes_(xP2);
    } else {
      // compute x = k*G
      final GroupElementP3 xP3 = GroupElementP3();
      CryptoOps.geScalarMultBase(xP3, k);
      x = CryptoOps.geP3Tobytes_(xP3);
    }

    // compute y = k*A
    final GroupElementP2 yP2 = GroupElementP2();
    CryptoOps.geScalarMult(yP2, k, aP3);
    y = CryptoOps.geTobytes_(yP2);

    // sig.c = Hs(Msg || d || x || y || sep || R || A || B)
    final c = RCT.hashToScalar_([
      ...hash,
      ...d,
      ...x,
      ...y,
      ...sep,
      ...R,
      ...A,
      ...B ?? CryptoOpsConst.zero
    ]);
    final List<int> sigR = RCT.zero();
    CryptoOps.scMulSub(sigR, c, r, k);
    return MECSignature(c: c, r: sigR);
  }

  /// verify tx proof
  static bool verifyTxProof(
      {required RctKey hash,
      required RctKey R,
      required RctKey A,
      required RctKey? B,
      required RctKey d,
      required MECSignature signature,
      required int version}) {
    hash.as32Bytes("verifyTxProof");
    R.as32Bytes("verifyTxProof");
    A.as32Bytes("verifyTxProof");
    B?.as32Bytes("verifyTxProof");
    d.as32Bytes("verifyTxProof");
    final GroupElementP3 rP3 = GroupElementP3();
    final GroupElementP3 aP3 = GroupElementP3();
    final GroupElementP3 bP3 = GroupElementP3();
    final GroupElementP3 dP3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(rP3, R) != 0) return false;
    if (CryptoOps.geFromBytesVartime_(aP3, A) != 0) return false;
    if (B != null && CryptoOps.geFromBytesVartime_(bP3, B) != 0) return false;
    if (CryptoOps.geFromBytesVartime_(dP3, d) != 0) return false;
    final GroupElementP3 crP32 = GroupElementP3();
    {
      final GroupElementP2 crP2 = GroupElementP2();
      CryptoOps.geScalarMult(crP2, signature.c, rP3);
      final cR = CryptoOps.geTobytes_(crP2);
      if (CryptoOps.geFromBytesVartime_(crP32, cR) != 0) return false;
    }
    final GroupElementP1P1 xP1P1 = GroupElementP1P1();
    if (B != null) {
      final GroupElementP2 rbP2 = GroupElementP2();
      CryptoOps.geScalarMult(rbP2, signature.r, bP3);
      final rB = CryptoOps.geTobytes_(rbP2);
      final GroupElementP3 rbP3 = GroupElementP3();
      if (CryptoOps.geFromBytesVartime_(rbP3, rB) != 0) return false;
      final GroupElementCached rbCached = GroupElementCached();
      CryptoOps.geP3ToCached(rbCached, rbP3);
      CryptoOps.geAdd(xP1P1, crP32, rbCached);
    } else {
      final GroupElementP3 rgP3 = GroupElementP3();
      CryptoOps.geScalarMultBase(rgP3, signature.r);
      final GroupElementCached rgCached = GroupElementCached();
      CryptoOps.geP3ToCached(rgCached, rgP3);
      CryptoOps.geAdd(xP1P1, crP32, rgCached);
    }
    final GroupElementP2 xP2 = GroupElementP2();
    CryptoOps.geP1P1ToP2(xP2, xP1P1);

    // compute sig.c*d
    final GroupElementP2 cdP2 = GroupElementP2();
    CryptoOps.geScalarMult(cdP2, signature.c, dP3);

    // compute sig.r*A
    final GroupElementP2 raP2 = GroupElementP2();
    CryptoOps.geScalarMult(raP2, signature.r, aP3);

    final cD = CryptoOps.geTobytes_(cdP2);
    final rA = CryptoOps.geTobytes_(raP2);
    final GroupElementP3 cdP3 = GroupElementP3();
    final GroupElementP3 raP3 = GroupElementP3();
    if (CryptoOps.geFromBytesVartime_(cdP3, cD) != 0) return false;
    if (CryptoOps.geFromBytesVartime_(raP3, rA) != 0) return false;
    final GroupElementCached raCached = GroupElementCached();
    CryptoOps.geP3ToCached(raCached, raP3);
    final GroupElementP1P1 yP1P1 = GroupElementP1P1();
    CryptoOps.geAdd(yP1P1, cdP3, raCached);
    final GroupElementP2 yP2 = GroupElementP2();
    CryptoOps.geP1P1ToP2(yP2, yP1P1);
    final sep = QuickCrypto.keccack256Hash("TXPROOF_V2".codeUnits);
    final x = CryptoOps.geTobytes_(xP2);
    final y = CryptoOps.geTobytes_(yP2);
    List<int> c2;
    if (version == 1) {
      c2 = RCT.hashToScalar_([...hash, ...d, ...x, ...y, ...sep]);
    } else if (version == 2) {
      c2 = RCT.hashToScalar_([
        ...hash,
        ...d,
        ...x,
        ...y,
        ...sep,
        ...R,
        ...A,
        ...B ?? RCT.zero(clone: false)
      ]);
    } else {
      throw MoneroCryptoException("Invalid tx proof version",
          details: {"version": version});
    }
    CryptoOps.scSub(c2, c2, signature.c);
    return CryptoOps.scIsNonZero(c2) == 0;
  }

  /// verify tx proof
  static bool verifyTxProofVar(
      {required RctKey hash,
      required RctKey R,
      required RctKey A,
      required RctKey? B,
      required RctKey d,
      required MECSignature signature,
      required int version}) {
    hash.as32Bytes("verifyTxProof");
    R.as32Bytes("verifyTxProof");
    A.as32Bytes("verifyTxProof");
    B?.as32Bytes("verifyTxProof");
    d.as32Bytes("verifyTxProof");
    final rP3 = Ed25519Utils.mybeAsPoint(R);
    final aP3 = Ed25519Utils.mybeAsPoint(A);
    final bP3 = B == null ? null : Ed25519Utils.asPoint(B);
    final dP3 = Ed25519Utils.mybeAsPoint(d);
    if (rP3 == null || aP3 == null || dP3 == null) return false;
    final crP32 = rP3 * Ed25519Utils.asScalarInt(signature.c);
    if (crP32.isInfinity) return false;
    EDPoint xP1P1;
    if (bP3 != null) {
      final rbP3 = bP3 * Ed25519Utils.asScalarInt(signature.r);
      if (rbP3.isInfinity) return false;
      xP1P1 = crP32 + rbP3;
    } else {
      xP1P1 = crP32 +
          (Curves.generatorED25519 * Ed25519Utils.asScalarInt(signature.r));
    }
    final EDPoint cdP2 = dP3 * Ed25519Utils.asScalarInt(signature.c);
    final raP2 = aP3 * Ed25519Utils.asScalarInt(signature.r);
    if (cdP2.isInfinity || raP2.isInfinity) return false;
    final yP2 = cdP2 + raP2;
    final sep = QuickCrypto.keccack256Hash("TXPROOF_V2".codeUnits);
    List<int> c2;
    if (version == 1) {
      c2 = RCT.hashToScalarVar(
          [...hash, ...d, ...xP1P1.toBytes(), ...yP2.toBytes(), ...sep]);
    } else if (version == 2) {
      c2 = RCT.hashToScalarVar([
        ...hash,
        ...d,
        ...xP1P1.toBytes(),
        ...yP2.toBytes(),
        ...sep,
        ...R,
        ...A,
        ...B ?? RCT.zero(clone: false)
      ]);
    } else {
      throw MoneroCryptoException("Invalid tx proof version",
          details: {"version": version});
    }
    final c = Ed25519Utils.scSubVar(c2, signature.c);
    return CryptoOps.scIsNonZero(c) == 0;
  }

  /// Derives a secret key from a derivation, output index, and private spend key.
  static MoneroPrivateKey deriveSecretKey(
      {
      /// receiver drivation
      required RctKey derivation,
      required int outIndex,
      required RctKey privateSpendKey,

      /// store key here
      RctKey? resultKey}) {
    derivation.as32Bytes("deriveSecretKey");
    privateSpendKey.as32Bytes("deriveSecretKey");
    if (CryptoOps.scCheck(privateSpendKey) != 0) {
      throw const MoneroCryptoException("Invalid secret key.");
    }
    final scalar =
        derivationToScalar(derivation: derivation, outIndex: outIndex);
    resultKey ??= RCT.zero();
    CryptoOps.scAdd(resultKey, privateSpendKey, scalar);
    return MoneroPrivateKey.fromBytes(resultKey);
  }

  /// Adds two secret keys and returns the resulting secret key.
  static MoneroPrivateKey scSecretAdd(
      {required MoneroPrivateKey a,
      required MoneroPrivateKey b,
      RctKey? resultKey}) {
    resultKey?.as32Bytes("secretKeyToPubKey");
    resultKey ??= RCT.zero();
    CryptoOps.scAdd(resultKey, a.key, b.key);
    return MoneroPrivateKey.fromBytes(resultKey);
  }
}
