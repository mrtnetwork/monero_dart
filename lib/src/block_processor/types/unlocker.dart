import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/block_processor/exception/exception.dart';
import 'package:monero_dart/src/block_processor/types/types.dart';
import 'package:monero_dart/src/helper/transaction.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';

abstract class MoneroOutputUnlocker {
  List<MoneroUnlockedOutputWithAccountKey> moneroUnlockOutput({
    required MoneroTransaction transaction,
    required String txHash,
    required List<BigInt> outputIndices,
  });
}

class DefaultMoneroOutputUnlocker implements MoneroOutputUnlocker {
  final List<MoneroAccountKeys> accounts;
  const DefaultMoneroOutputUnlocker({this.accounts = const []});
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
            throw MoneroBlockScannerException.failed(
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
