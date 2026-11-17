// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/crypto/crypto.dart';
import 'package:monero_dart/src/models/models.dart';

/// One batch-unlocked output plus the account it belongs to. The account
/// is carried explicitly because attribution via the subaddress index is
/// ambiguous: several accounts can watch the same index.
typedef MoneroBatchLockedOutput<A extends MoneroBaseAccountKeys> =
    ({A account, MoneroLockedOutput output});

/// Opt-in native batch scan (fast unlock) via the Rust `monero::scan` core.
///
/// Same semantics as [MoneroTransactionHelper.getLockedOutputs] for the scan
/// portion (key derivation + view-tag prefilter + stealth-key recompute),
/// but the hot loop runs in native code instead of Dart. Amount decode,
/// key images and all types stay exactly the existing Dart ones.
///
/// Requires the native backend (`blockchainUtils.setRustApi(...)` with a
/// monero-enabled native library) before use. Nothing here changes default
/// behavior: the pure-Dart path is untouched. Throws
/// [BuError] on invalid input or native failure (including
/// use on the pure-Dart backend); returns empty list (never null) when
/// nothing is ours.
abstract final class MoneroNativeUnlock {
  /// Scan every output of [tx] for [account] in ONE native batch call.
  static List<MoneroLockedOutput>? unlockTxOutputs({
    required MoneroTransaction tx,
    required MoneroBaseAccountKeys account,
  }) {
    if (tx.vout.isEmpty) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Transaction has no outputs.",
      );
    }
    final txPubKey = tx.txPubkeyBytes();
    final additionalPubKeys = tx.additionalPubKeys?.pubKeys;
    if (txPubKey == null ||
        (additionalPubKeys != null &&
            additionalPubKeys.length != tx.vout.length)) {
      return null;
    }
    final scanOutputs = <BuMoneroScanOutput>[];
    final voutIdx = <int>[];
    for (var i = 0; i < tx.vout.length; i++) {
      final outPublicKey = tx.vout[i].target.getPublicKeyBytes();
      if (outPublicKey == null) continue;
      voutIdx.add(i);
      scanOutputs.add(
        BuMoneroScanOutput(
          outKey: outPublicKey,
          txPub: txPubKey,
          additionalPub:
              additionalPubKeys == null ? null : additionalPubKeys[i],
          viewTag: tx.vout[i].target.getViewTag(),
        ),
      );
    }
    if (scanOutputs.isEmpty) return [];
    final spendPubs =
        account.indexes
            .map((e) => account.getSpendPublicKey(e).toBytes())
            .toList();
    final List<BuMoneroUnlockMatch> matches;
    try {
      matches = blockchainUtils.api.monero.unlockBatch(
        accounts: [
          BuMoneroScanAccount(
            viewSecret: account.account.privVkey.takeSecretKey(),
            spendPubs: spendPubs,
          ),
        ],
        outputs: scanOutputs,
      );
    } catch (e) {
      throw BuError(
        MoneroErrorType.plugin,
        "Native unlock failed: ${e is BuError ? e.message : e}",
      );
    } // One output can (degenerately) match twice when additional == tx pubkey;
    // keep the first, like the Dart loop's early return.
    final seen = <int>{};
    final result = <MoneroLockedOutput>[];
    for (final m in matches) {
      if (m.outIndex >= voutIdx.length ||
          m.addressPos >= account.indexes.length) {
        continue;
      }
      if (!seen.add(m.outIndex)) continue;
      final realIndex = voutIdx[m.outIndex];
      final locked = _toLockedOutput(
        tx: tx,
        account: account,
        realIndex: realIndex,
        outPublicKey: tx.vout[realIndex].target.getPublicKeyBytes()!,
        derivation: m.derivation,
        subIndex: account.indexes[m.addressPos],
      );
      if (locked != null) result.add(locked);
    }
    return result;
  }

  /// Scan every output of [txs] for every [accounts] in ONE native batch call.
  ///
  /// Same semantics as repeated [unlockTxOutputs], but all (account, output)
  /// pairs cross FFI once: per-call packing/alloc overhead is paid once per
  /// batch instead of once per (transaction, account), and the native
  /// derivation cache reuses `D = 8·v·R` across a transaction's outputs.
  /// Amount decode, key images and all types stay exactly the existing Dart
  /// ones (see [_toLockedOutput]).
  ///
  /// Returns one list per input transaction, aligned with [txs].
  /// Transactions that fail validation (missing tx pubkey, additional-pubkey
  /// count mismatch, no outputs) yield an empty list, mirroring the
  /// single-tx `null`. Never returns null. Each hit carries its account
  /// (see [MoneroBatchLockedOutput]).
  static List<List<MoneroBatchLockedOutput<A>>> unlockTxsOutputs<
    A extends MoneroBaseAccountKeys
  >({required List<MoneroTransaction> txs, required List<A> accounts}) {
    final result = List<List<MoneroBatchLockedOutput<A>>>.generate(
      txs.length,
      (_) => [],
    );
    if (txs.isEmpty || accounts.isEmpty) return result;
    // Flattened outputs; [outPos] maps batch position -> (tx, vout).
    // Explicit outIndex is passed per output, so skipped (unparseable)
    // vouts stay correct — unlike position-implied indices.
    final scanOutputs = <BuMoneroScanOutput>[];
    final outPos = <({int tx, int vout})>[];
    // Per-account scan keys, hoisted out of the per-tx loop.
    final scanAccounts = <BuMoneroScanAccount>[
      for (final account in accounts)
        BuMoneroScanAccount(
          viewSecret: account.account.privVkey.takeSecretKey(),
          spendPubs:
              account.indexes
                  .map((e) => account.getSpendPublicKey(e).toBytes())
                  .toList(),
        ),
    ];
    for (var t = 0; t < txs.length; t++) {
      final tx = txs[t];
      if (tx.vout.isEmpty) continue;
      final txPubKey = tx.txPubkeyBytes();
      final additionalPubKeys = tx.additionalPubKeys?.pubKeys;
      if (txPubKey == null ||
          (additionalPubKeys != null &&
              additionalPubKeys.length != tx.vout.length)) {
        continue;
      }
      for (var v = 0; v < tx.vout.length; v++) {
        final outPublicKey = tx.vout[v].target.getPublicKeyBytes();
        if (outPublicKey == null) continue;
        outPos.add((tx: t, vout: v));
        scanOutputs.add(
          BuMoneroScanOutput(
            outKey: outPublicKey,
            txPub: txPubKey,
            additionalPub:
                additionalPubKeys == null ? null : additionalPubKeys[v],
            viewTag: tx.vout[v].target.getViewTag(),
            outIndex: v,
          ),
        );
      }
    }
    if (scanOutputs.isEmpty) return result;
    final List<BuMoneroUnlockMatch> matches;
    try {
      matches = blockchainUtils.api.monero.unlockBatch(
        accounts: scanAccounts,
        outputs: scanOutputs,
      );
    } catch (e) {
      throw BuError(
        MoneroErrorType.plugin,
        "Native unlock failed: ${e is BuError ? e.message : e}",
      );
    }
    // One output can (degenerately) match twice when additional == tx pubkey;
    // keep the first, like the Dart loop's early return.
    final seen = <int>{};
    for (final m in matches) {
      if (m.outIndex >= outPos.length || m.accountIndex >= accounts.length) {
        continue;
      }
      if (!seen.add(m.outIndex)) continue;
      final pos = outPos[m.outIndex];
      final account = accounts[m.accountIndex];
      if (m.addressPos >= account.indexes.length) continue;
      final locked = _toLockedOutput(
        tx: txs[pos.tx],
        account: account,
        realIndex: pos.vout,
        outPublicKey: txs[pos.tx].vout[pos.vout].target.getPublicKeyBytes()!,
        derivation: m.derivation,
        subIndex: account.indexes[m.addressPos],
      );
      if (locked != null) {
        result[pos.tx].add((account: account, output: locked));
      }
    }
    return result;
  }

  /// Shared tail of `getLockedOutputs`: amount decode → [MoneroLockedOutput].
  /// Mirrors `MoneroTransactionHelper.getLockedOutputs` exactly.
  static MoneroLockedOutput? _toLockedOutput({
    required MoneroTransaction tx,
    required MoneroBaseAccountKeys account,
    required int realIndex,
    required List<int> outPublicKey,
    required List<int> derivation,
    required MoneroSubIndex subIndex,
  }) {
    final sharedSec = MoneroCrypto.derivationToScalar(
      derivation: derivation,
      outIndex: realIndex,
    );
    BigInt? amount;
    RctKey? mask;
    final bool coinbase = tx.isCoinbase();
    if (coinbase) {
      amount = tx.vout[realIndex].amount;
      mask = RCT.identity();
    } else {
      final decode = RCTGeneratorUtils.decodeRctVar(
        sig: tx.signature.cast(),
        secretKey: sharedSec,
        outputIndex: realIndex,
      );
      amount = decode?.$1;
      mask = decode?.$2;
    }
    if (amount == null || mask == null) return null;
    return MoneroLockedOutput(
      amount: amount,
      mask: mask,
      coinbase: coinbase,
      derivation: derivation,
      outputPublicKey: outPublicKey,
      accountIndex: subIndex,
      unlockTime: tx.unlockTime,
      realIndex: realIndex,
    );
  }
}
