import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:monero_dart/monero_dart.dart';

enum VerifyBlockStrategy { never, always, onReceiveFunds }

class BlockProcessorConfig {
  final String? genesisHash;
  final Duration? getBlocksTimeout;
  final MoneroNetwork network;
  final MoneroOutputUnlocker unlocker;
  final VerifyBlockStrategy strategy;
  BlockProcessorConfig({
    required this.network,
    this.strategy = VerifyBlockStrategy.always,
    this.genesisHash,
    this.getBlocksTimeout,
    this.unlocker = const DefaultMoneroOutputUnlocker(),
  });
}

class MoneroBlockStateInfo {
  final int blockId;
  final int timestamp;
  final MoneroBlock block;
  final List<MoneroTransaction> transactions;
  final DaemonBlockOutputIndicesResponse outputIndices;
  MoneroBlockStateInfo({
    required this.timestamp,
    required this.blockId,
    required this.block,
    required this.outputIndices,
    List<MoneroTransaction> transactions = const [],
  }) : transactions = transactions.immutable;

  MoneroBlockStateInfo? verifyBlock({
    required VerifyBlockStrategy strategy,
    MoneroBlockStateInfo? previousState,
    bool receiveFunds = false,
  }) {
    if (previousState == null) return this;
    switch (strategy) {
      case VerifyBlockStrategy.never:
        return this;
      case VerifyBlockStrategy.onReceiveFunds when receiveFunds:
      case VerifyBlockStrategy.always:
        final previousHash = previousState.block.getBlockHashBytes();
        if (previousState.blockId == 202612) {
          return this;
        }

        if (!BytesUtils.bytesEqual(previousHash, block.hash)) {
          return null;
        }
        return this;
      case VerifyBlockStrategy.onReceiveFunds:
        return this;
    }
  }
}

class MoneroUnlockedOutputWithAccountKey {
  final MoneroAccountKeys account;
  final MoneroLockedOutput output;
  final BigInt globalIndex;
  MoneroUnlockedOutputWithAccountKey({
    required this.account,
    required this.output,
    required this.globalIndex,
  });
}

abstract class MoneroScannedTx {
  List<MoneroUnlockedOutputWithAccountKey> get unlockedOutputs;
}

class DefaultMoneroScannedTx implements MoneroScannedTx {
  final String txHash;
  @override
  final List<MoneroUnlockedOutputWithAccountKey> unlockedOutputs;
  final List<TxKeyImage> keyImages;
  DefaultMoneroScannedTx({
    required this.txHash,
    List<MoneroUnlockedOutputWithAccountKey> unlockedOutputs = const [],
    List<TxKeyImage> keyImages = const [],
  }) : unlockedOutputs = unlockedOutputs.immutable,
       keyImages = keyImages.immutable;
}

abstract class MoneroScannedBlock {
  List<MoneroScannedTx> get txes;
}

class DefaultMoneroScannedBlock extends MoneroScannedBlock {
  final int blockHeight;
  final String blockHash;
  final int blocktime;
  final MoneroBlock block;
  @override
  final List<DefaultMoneroScannedTx> txes;

  DefaultMoneroScannedBlock({
    required this.blockHash,
    required this.blockHeight,
    required this.blocktime,
    required this.block,
    List<DefaultMoneroScannedTx> txes = const [],
  }) : txes = txes.immutable;

  List<TxKeyImage> keyImages() => txes.expand((e) => e.keyImages).toList();
  List<MoneroUnlockedOutputWithAccountKey> unlockedOutputs() =>
      txes.expand((e) => e.unlockedOutputs).toList();
}
