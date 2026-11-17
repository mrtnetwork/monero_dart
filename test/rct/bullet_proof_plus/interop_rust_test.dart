/// Bulletproofs+ Dart <-> Rust interop.
///
/// monero_dart's pure-Dart prover/verifier and the Rust core
/// (`blockchain-utils/src/monero`, exposed via FFI) only ever tested
/// against themselves. This file locks them together in both directions
/// using deterministic vectors (fixed RNG stream, amount 0):
///
/// 1. Dart prove -> pack -> Rust `bpPlusVerify` (must be true).
/// 2. Rust `bpPlusProveAmounts` -> Dart `bulletproofPlusVerify` (true).
/// 3. Tampered blob -> Rust verify returns false (not a crash/throw).
///
/// Skipped cleanly when the native library is absent (same pattern as
/// `blockchain_utils_connector/test/monero_unlock_ffi_test.dart`).
library;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/monero/api/api.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void nativeProof() {
  MoneroBpPlusProof toWire(BulletproofPlus p) => p.toNative();
  BulletproofPlus fromWire(MoneroBpPlusProof p) =>
      BulletproofPlus.fromNative(p);

  group(
    'Bulletproofs+ Dart<->Rust interop',
    skip: blockchainUtils.hasNativeBackend ? null : 'native lib missing.',
    () {
      test('Dart prove -> Rust verify', () {
        installSeededTestRng();
        final gamma = [RCT.skGen()];
        final dartProof = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts([
          BigInt.zero,
        ], gamma);
        // Sanity: pure-Dart self-verify first.
        expect(
          BulletproofsPlusGenerator.bulletproofPlusVerify([dartProof]),
          isTrue,
          reason: 'dart self-verify',
        );
        final ok = blockchainUtils.api.monero.bpPlusVerify([toWire(dartProof)]);
        expect(ok, isTrue, reason: 'rust verifies dart proof');
      });

      test('Rust prove -> Dart verify', () {
        final gamma = List<int>.filled(32, 0)..[0] = 7;
        final seed = List<int>.filled(32, 9);
        final wireProof = blockchainUtils.api.monero.bpPlusProveAmounts(
          amounts: [BigInt.zero],
          gamma: [gamma],
          seed: seed,
        );
        // Rust self-consistency through the same FFI path.
        expect(
          blockchainUtils.api.monero.bpPlusVerify([wireProof]),
          isTrue,
          reason: 'rust self-verify',
        );
        // Cross-verify with the pure-Dart verifier.
        expect(
          BulletproofsPlusGenerator.bulletproofPlusVerify([
            fromWire(wireProof),
          ]),
          isTrue,
          reason: 'dart verifies rust proof',
        );
      });

      test('tampered blob rejected by Rust verify', () {
        final gamma = List<int>.filled(32, 0)..[0] = 7;
        final seed = List<int>.filled(32, 9);
        final wireProof = blockchainUtils.api.monero.bpPlusProveAmounts(
          amounts: [BigInt.zero],
          gamma: [gamma],
          seed: seed,
        );
        final blob = wireProof.toBlob().toList();
        blob[blob.length - 1] ^= 0x01;
        final tampered = MoneroBpPlusProof.fromBlob(blob);
        expect(
          blockchainUtils.api.monero.bpPlusVerify([tampered]),
          isFalse,
          reason: 'tampered proof must not verify',
        );
      });
    },
  );
}
