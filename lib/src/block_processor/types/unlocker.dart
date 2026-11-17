import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/error/monero_error.dart';
import 'package:monero_dart/src/block_processor/types/types.dart';
import 'package:monero_dart/src/helper/native_unlock.dart';
import 'package:monero_dart/src/helper/transaction.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';

abstract class MoneroOutputUnlocker {
  List<MoneroUnlockedOutputWithAccountKey> moneroUnlockOutput({
    required MoneroTransaction transaction,
    required String txHash,
    required List<BigInt> outputIndices,
  });

  /// Scan [transactions] for owned outputs in one pass. Returns one list
  /// per transaction, aligned with [transactions]. Default implementation
  /// loops [moneroUnlockOutput]; batch-capable unlockers override it.
  /// [txHashes] and [outputIndices] align with [transactions].
  List<List<MoneroUnlockedOutputWithAccountKey>> moneroUnlockOutputs({
    required List<MoneroTransaction> transactions,
    required List<String> txHashes,
    required List<List<BigInt>> outputIndices,
  }) {
    if (transactions.length != txHashes.length ||
        transactions.length != outputIndices.length) {
      throw MoneroErrors.scannerFailed(
        "moneroUnlockOutputs",
        reason: "Mismatched transactions, hashes and output indices.",
        details: {
          "transactions": transactions.length.toString(),
          "hashes": txHashes.length.toString(),
          "indices": outputIndices.length.toString(),
        },
      );
    }
    return [
      for (var i = 0; i < transactions.length; i++)
        moneroUnlockOutput(
          transaction: transactions[i],
          txHash: txHashes[i],
          outputIndices: outputIndices[i],
        ),
    ];
  }
}

class DefaultMoneroOutputUnlocker implements MoneroOutputUnlocker {
  final List<MoneroAccountKeys> accounts;
  const DefaultMoneroOutputUnlocker({this.accounts = const []});
  @override
  List<List<MoneroUnlockedOutputWithAccountKey>> moneroUnlockOutputs({
    required List<MoneroTransaction> transactions,
    required List<String> txHashes,
    required List<List<BigInt>> outputIndices,
  }) {
    if (transactions.length != txHashes.length ||
        transactions.length != outputIndices.length) {
      throw MoneroErrors.scannerFailed(
        "moneroUnlockOutputs",
        reason: "Mismatched transactions, hashes and output indices.",
        details: {
          "transactions": transactions.length.toString(),
          "hashes": txHashes.length.toString(),
          "indices": outputIndices.length.toString(),
        },
      );
    }
    return [
      for (var i = 0; i < transactions.length; i++)
        moneroUnlockOutput(
          transaction: transactions[i],
          txHash: txHashes[i],
          outputIndices: outputIndices[i],
        ),
    ];
  }

  @override
  List<MoneroUnlockedOutputWithAccountKey> moneroUnlockOutput({
    required MoneroTransaction transaction,
    required String txHash,
    required List<BigInt> outputIndices,
  }) {
    List<MoneroUnlockedOutputWithAccountKey> outputs = [];
    for (int realIndex = 0; realIndex < transaction.vout.length; realIndex++) {
      for (int a = 0; a < accounts.length; a++) {
        final account = accounts[a];
        final unlock = MoneroTransactionHelper.getLockedOutputs(
          realIndex: realIndex,
          tx: transaction,
          account: account,
        );
        if (unlock != null) {
          final globalIndex = outputIndices.elementAtOrNull(realIndex);
          if (globalIndex == null) {
            throw MoneroErrors.scannerFailed(
              "buildBlockState",
              reason: "Missing output global index.",
              details: {"txhash": txHash, "output": realIndex.toString()},
            );
          }
          outputs.add(
            MoneroUnlockedOutputWithAccountKey(
              account: account,
              output: unlock,
              globalIndex: globalIndex,
            ),
          );
        }
      }
    }
    return outputs;
  }
}

class NativeMoneroOutputUnlocker implements MoneroOutputUnlocker {
  final List<MoneroAccountKeys> accounts;
  const NativeMoneroOutputUnlocker({this.accounts = const []});
  @override
  List<MoneroUnlockedOutputWithAccountKey> moneroUnlockOutput({
    required MoneroTransaction transaction,
    required String txHash,
    required List<BigInt> outputIndices,
  }) {
    final List<MoneroUnlockedOutputWithAccountKey> outputs = [];
    for (final account in accounts) {
      final unlocked = MoneroNativeUnlock.unlockTxOutputs(
        tx: transaction,
        account: account,
      );
      if (unlocked == null) {
        continue;
      }
      for (final output in unlocked) {
        final globalIndex = outputIndices.elementAtOrNull(output.realIndex);
        if (globalIndex == null) {
          throw MoneroErrors.scannerFailed(
            "moneroUnlockOutput",
            reason: "Missing output global index.",
            details: {"txhash": txHash, "output": "${output.realIndex}"},
          );
        }
        outputs.add(
          MoneroUnlockedOutputWithAccountKey(
            account: account,
            output: output,
            globalIndex: globalIndex,
          ),
        );
      }
    }
    return outputs;
  }

  @override
  List<List<MoneroUnlockedOutputWithAccountKey>> moneroUnlockOutputs({
    required List<MoneroTransaction> transactions,
    required List<String> txHashes,
    required List<List<BigInt>> outputIndices,
  }) {
    final unlocked = MoneroNativeUnlock.unlockTxsOutputs(
      txs: transactions,
      accounts: accounts,
    );
    return [
      for (var t = 0; t < transactions.length; t++)
        [
          for (final hit in unlocked[t])
            MoneroUnlockedOutputWithAccountKey(
              account: hit.account,
              output: hit.output,
              globalIndex:
                  outputIndices[t].elementAtOrNull(hit.output.realIndex) ??
                  (throw MoneroErrors.scannerFailed(
                    "moneroUnlockOutputs",
                    reason: "Missing output global index.",
                    details: {
                      "txhash": txHashes[t],
                      "output": "${hit.output.realIndex}",
                    },
                  )),
            ),
        ],
    ];
  }
}
