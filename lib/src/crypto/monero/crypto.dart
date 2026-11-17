import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';

typedef CbSignatureRendScalar = List<int> Function(int pubIndex);
typedef CbRandScalar = List<int> Function();

class MoneroCrypto {
  // /// Validates a scalar's byte representation and ensures it is valid.

  /// Validates a public key, ensuring it is in the main subgroup and not zero or identity.
  static ED25519MoneroPublicKey asValidPublicKey(
    ED25519MoneroPublicKey publicKey,
  ) {
    if (BytesUtils.bytesEqual(publicKey.toBytes(), RCT.zero(clone: false)) ||
        BytesUtils.bytesEqual(
          publicKey.toBytes(),
          RCT.identity(clone: false),
        )) {
      throw BuError(
        DefaultErrorType.badPublicKey,
        "Public key was not in prime subgroup.",
      );
    }
    return publicKey;
  }

  /// Adds two public keys and returns the resulting public key.
  ///
  static ED25519MoneroPublicKey addPublicKey(
    ED25519MoneroPublicKey a,
    ED25519MoneroPublicKey b,
  ) {
    try {
      return ED25519MoneroPublicKey.fromBytes(
        blockchainUtils.api.ed25519.add(a.toBytes(), b.toBytes()),
      );
    } catch (_) {
      throw BuError(DefaultErrorType.badPublicKey, "Invalid public key.");
    }
  }

  /// Converts a derivation and output index to a scalar value.
  static BuBytes derivationToScalar({
    required List<int> derivation,
    required int outIndex,
  }) {
    derivation.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "derivationToScalar",
      reason: "Invalid bytes length.",
    );
    final outputIndex = MoneroLayoutConst.varint48.serialize(outIndex);
    final bytes = [...derivation.asImmutableBytes, ...outputIndex];
    final hash = RCT.hashToScalar(bytes);
    return hash;
  }

  /// Derives a public key from a base public key using a derivation and output index.
  static ED25519MoneroPublicKey derivePublicKey({
    required List<int> derivation,
    required int outIndex,
    required ED25519MoneroPublicKey basePublicKey,
  }) {
    derivation.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "derivePublicKey",
      reason: "Invalid bytes length.",
    );
    final ed25519 = blockchainUtils.api.ed25519;
    final RctKey scalar = derivationToScalar(
      derivation: derivation,
      outIndex: outIndex,
    );
    try {
      final derived = ed25519.add(
        ed25519.reduceMultBase(scalar),
        basePublicKey.toBytes(),
      );
      return ED25519MoneroPublicKey.fromBytes(derived);
    } catch (_) {
      throw BuError(DefaultErrorType.badPublicKey, "Invalid public key.");
    }
  }

  static const List<int> _viewTagDomain = [
    118,
    105,
    101,
    119,
    95,
    116,
    97,
    103,
  ];

  /// Derives a view tag from a derivation and output index.
  static int deriveViewTag({
    required List<int> derivation,
    required int outIndex,
  }) {
    derivation.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "deriveViewTag",
      reason: "Invalid bytes length.",
    );
    final outputIndex = MoneroLayoutConst.varint48.serialize(outIndex);
    final hash = QuickCrypto.keccak256Hash([
      ..._viewTagDomain,
      ...derivation,
      ...outputIndex,
    ]);
    return hash[0];
  }

  /// Generates a key image from a public key and private key.
  static BuBytes generateKeyImageBytes({
    required List<int> pubkey,
    required List<int> secretKey,
  }) {
    final BuBytes key = RCT.zero();
    key.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateKeyImageBytes",
      reason: "Invalid bytes length.",
    );
    final ed25519 = blockchainUtils.api.ed25519;
    // Reduce first: the backend rejects non-canonical scalars while the
    // previous code multiplied raw bytes; (x mod L) * P is the same point.
    key.setAll(
      0,
      ed25519.mult(ed25519.scReduce(secretKey), ed25519.hashToEc(pubkey)),
    );
    return key;
  }

  /// Generates key derivation bytes from a public key and secret key.
  /// Fused `8 * (secret * pub)` without intermediate encoding.
  static BuBytes generateKeyDerivationBytes({
    required List<int> pubkey,
    required List<int> secretKey,
  }) {
    final ed25519 = blockchainUtils.api.ed25519;
    final BuBytes result = RCT.zero();
    try {
      result.setAll(0, ed25519.mul8Mult(secretKey, pubkey));
    } catch (_) {
      throw BuError(DefaultErrorType.badPublicKey, "Invalid public key.");
    }
    return result;
  }

  /// Generates a key derivation shared secret from key objects.
  ///
  /// Object wrapper around [generateKeyDerivationBytes] taking
  /// [ED25519MoneroPublicKey]/[ED25519MoneroPrivateKey] instead of raw bytes.
  static List<int> generateKeyDerivation({
    required ED25519MoneroPublicKey pubkey,
    required ED25519MoneroPrivateKey secretKey,
  }) {
    return secretKey.takeSecretKey().useValue(
      (k) => generateKeyDerivationBytes(pubkey: pubkey.toBytes(), secretKey: k),
    );
  }

  static MECSignature generateSignature({
    required List<int> hash,
    required List<int> publicKey,
    required List<int> secretKey,
    List<int>? k,
  }) {
    hash.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateSignature",
      reason: "Invalid bytes length.",
    );
    publicKey.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateSignature",
      reason: "Invalid bytes length.",
    );
    secretKey.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateSignature",
      reason: "Invalid bytes length.",
    );
    while (true) {
      k ??= RCT.skGen();
      RCT.asValidScalar(k);
      final ed25519 = blockchainUtils.api.ed25519;
      final comm = ed25519.reduceMultBase(k);
      final c = RCT.hashToScalar([...hash, ...publicKey, ...comm]);
      if (!ed25519.scIsNonZero(c)) {
        continue;
      }
      final r = RCT.zero();
      r.setAll(0, ed25519.scMulSub(c, secretKey, k));
      if (!ed25519.scIsNonZero(r)) {
        continue;
      }
      return MECSignature(c: c, r: r);
    }
  }

  static bool checkSignature({
    required List<int> hash,
    required List<int> publicKey,
    required MECSignature signature,
  }) {
    hash.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "checkSignature",
      reason: "Invalid bytes length.",
    );
    publicKey.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "checkSignature",
      reason: "Invalid bytes length.",
    );
    final ed25519 = blockchainUtils.api.ed25519;
    if (!ed25519.scCheck(signature.r) ||
        !ed25519.scCheck(signature.c) ||
        BytesUtils.bytesEqual(signature.c, RCT.zero(clone: false))) {
      return false;
    }
    late final List<int> comm;
    try {
      comm = ed25519.mulAdd(
        signature.c,
        publicKey,
        signature.r,
        ed25519.generator(),
      );
    } catch (_) {
      return false;
    }
    if (BytesUtils.bytesEqual(comm, ed25519.identity())) {
      return false;
    }
    RctKey sH = RCT.hashToScalar([...hash, ...publicKey, ...comm]);
    sH = ed25519.scSub(sH, signature.c);
    return !ed25519.scIsNonZero(sH);
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
    hash.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    R.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    A.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    B?.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    d.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    r.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "generateTxProof",
      reason: "Invalid bytes length.",
    );
    final ed25519 = blockchainUtils.api.ed25519;
    if (!BaseEd25519PublicKey.isValidBytes(R)) {
      throw BuError(DefaultErrorType.badPublicKey, "tx pubkey is invalid");
    }
    if (!BaseEd25519PublicKey.isValidBytes(A)) {
      throw BuError(
        DefaultErrorType.badPublicKey,
        "recipient view pubkey is invalid",
      );
    }
    if (B != null && !BaseEd25519PublicKey.isValidBytes(B)) {
      throw BuError(
        DefaultErrorType.badPublicKey,
        "recipient spend pubkey is invalid",
      );
    }
    if (!BaseEd25519PublicKey.isValidBytes(d)) {
      throw BuError(
        DefaultErrorType.badPrivateKey,
        "key derivation is invalid",
      );
    }

    final k = RCT.skGen();

    final sep = QuickCrypto.keccak256Hash("TXPROOF_V2".codeUnits);
    List<int> x;
    List<int> y;
    if (B != null) {
      // compute x = k*B (`k` comes from skGen_, hence canonical)
      x = ed25519.mult(k, B);
    } else {
      // compute x = k*G
      x = ed25519.reduceMultBase(k);
    }

    // compute y = k*A
    y = ed25519.mult(k, A);

    // sig.c = Hs(Msg || d || x || y || sep || R || A || B)
    final c = RCT.hashToScalar([
      ...hash,
      ...d,
      ...x,
      ...y,
      ...sep,
      ...R,
      ...A,
      ...B ?? RCT.zero(clone: false),
    ]);
    final List<int> sigR = RCT.zero();
    sigR.setAll(0, ed25519.scMulSub(c, r, k));
    return MECSignature(c: c, r: sigR);
  }

  /// verify tx proof
  static bool verifyTxProof({
    required List<int> hash,
    required List<int> R,
    required List<int> A,
    required List<int>? B,
    required List<int> d,
    required MECSignature signature,
    required int version,
  }) {
    hash.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "verifyTxProof",
      reason: "Invalid bytes length.",
    );
    R.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "verifyTxProof",
      reason: "Invalid bytes length.",
    );
    A.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "verifyTxProof",
      reason: "Invalid bytes length.",
    );
    B?.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "verifyTxProof",
      reason: "Invalid bytes length.",
    );
    d.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "verifyTxProof",
      reason: "Invalid bytes length.",
    );
    final ed25519 = blockchainUtils.api.ed25519;
    if (!BaseEd25519PublicKey.isValidBytes(R) ||
        !BaseEd25519PublicKey.isValidBytes(A) ||
        !BaseEd25519PublicKey.isValidBytes(d) ||
        (B != null && !BaseEd25519PublicKey.isValidBytes(B))) {
      return false;
    }
    // Reduce first (the legacy ladder reduced raw scalars implicitly).
    final rc = ed25519.scReduce(signature.c);
    final rr = ed25519.scReduce(signature.r);
    late final List<int> x;
    late final List<int> y;
    try {
      x =
          B != null
              ? ed25519.doubleScalarMult(rc, R, rr, B)
              : ed25519.doubleScalarMult(rc, R, rr, ed25519.generator());
      y = ed25519.doubleScalarMult(rc, d, rr, A);
    } catch (_) {
      return false;
    }
    final sep = QuickCrypto.keccak256Hash("TXPROOF_V2".codeUnits);
    List<int> c2;
    if (version == 1) {
      c2 = RCT.hashToScalar([...hash, ...d, ...x, ...y, ...sep]);
    } else if (version == 2) {
      c2 = RCT.hashToScalar([
        ...hash,
        ...d,
        ...x,
        ...y,
        ...sep,
        ...R,
        ...A,
        ...B ?? RCT.zero(clone: false),
      ]);
    } else {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid tx proof version",
        details: {"version": version.toString()},
      );
    }
    c2 = ed25519.scSub(c2, signature.c);
    return !ed25519.scIsNonZero(c2);
  }

  /// Derives a secret key from a derivation, output index, and private spend key.
  static ED25519MoneroPrivateKey deriveSecretKey({
    /// receiver drivation
    required List<int> derivation,
    required int outIndex,
    required List<int> privateSpendKey,
  }) {
    derivation.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "deriveSecretKey",
      reason: "Invalid bytes length.",
    );
    privateSpendKey.exc(
      length: Ed25519KeysConst.privKeyByteLen,
      operation: "deriveSecretKey",
      reason: "Invalid bytes length.",
    );
    if (!blockchainUtils.api.ed25519.scCheck(privateSpendKey)) {
      throw BuError(DefaultErrorType.badPrivateKey, "Invalid secret key.");
    }
    final scalar = derivationToScalar(
      derivation: derivation,
      outIndex: outIndex,
    );
    final List<int> result = RCT.zero();
    result.setAll(
      0,
      blockchainUtils.api.ed25519.scAdd(privateSpendKey, scalar),
    );
    return ED25519MoneroPrivateKey.fromBytes(result);
  }

  /// Adds two secret keys and returns the resulting secret key.
  static ED25519MoneroPrivateKey scSecretAdd({
    required ED25519MoneroPrivateKey a,
    required ED25519MoneroPrivateKey b,
  }) {
    final List<int> result = RCT.zero();
    result.setAll(
      0,
      blockchainUtils.api.ed25519.scAdd(a.takeSecretKey(), b.takeSecretKey()),
    );
    return ED25519MoneroPrivateKey.fromBytes(result);
  }
}
