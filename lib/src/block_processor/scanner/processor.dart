import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/block_processor/exception/exception.dart';
import 'package:monero_dart/src/block_processor/types/types.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/provider/provider.dart';
import 'package:monero_dart/src/serialization/serialization.dart';

abstract class MoneroBlockProcessor {
  MoneroProvider get provider;
  Future<String> getGenesisBlockHash();
  Future<List<int>> getBlocksByRangeBinary(int start);
  Future<DaemonGetBlockBinResponse> getBlocks(int start);
  Future<MoneroScannedBlock> scanBlockInner(MoneroBlockStateInfo state);
  Stream<MoneroScannedBlock> scanBlock(int startHeight, int endHeight);
}

class DefaultMoneroBlockProcessor extends MoneroBlockProcessor {
  @override
  final MoneroProvider provider;
  final BlockProcessorConfig config;
  DefaultMoneroBlockProcessor({required this.provider, required this.config})
    : _genesisHash = config.genesisHash;
  String? _genesisHash;

  Future<List<int>> requestBinary<RESULT, SERVICERESPONSE>(
    MoneroDaemonRequestParam<RESULT, SERVICERESPONSE> request, {
    Duration? timeout,
  }) async {
    return provider.requestBinary<RESULT, SERVICERESPONSE>(
      request,
      timeout: timeout,
    );
  }

  @override
  Future<String> getGenesisBlockHash() async {
    final genesis = _genesisHash;
    if (genesis != null) return genesis;
    final String hash = await provider.request(DaemonRequestOnGetBlockHash(0));
    _genesisHash = hash;
    return hash;
  }

  @override
  Future<List<int>> getBlocksByRangeBinary(int start) async {
    final genesis = await getGenesisBlockHash();
    final blocks = await provider.requestBinary(
      DaemonRequestGetBlocksBin(
        startHeight: start,
        requestedInfo: DaemonRequestBlocksInfo.blocksOnly,
        blockIds: [genesis],
        prune: false,
      ),
      timeout: config.getBlocksTimeout,
    );
    return blocks;
  }

  @override
  Future<DaemonGetBlockBinResponse> getBlocks(int start) async {
    final binary = await getBlocksByRangeBinary(start);
    final toJson = MoneroStorageSerializer.deserialize(binary);
    final response = DaemonBaseResponse.fromJson(toJson);
    if (!response.isOk) {
      throw MoneroBlockScannerException.failed(
        "getBlocks",
        reason: "getBlocks failed at $start: ${response.status}",
      );
    }
    return DaemonGetBlockBinResponse.fromJson(toJson);
  }

  @override
  Stream<DefaultMoneroScannedBlock> scanBlock(
    int startHeight,
    int endHeight, {
    bool Function(Object? error, int retry)? retryOnErr,
    int maxRetries = 1,
  }) async* {
    if (endHeight < startHeight) {
      throw MoneroBlockScannerException.failed(
        "scanBlock",
        reason: "Invalid block range.",
      );
    }
    int currentHeight = startHeight;
    MoneroBlockStateInfo? latestState;
    int retry = 0;
    while (currentHeight <= endHeight) {
      DaemonGetBlockBinResponse blocks;
      try {
        blocks = await getBlocks(currentHeight);
        retry = 0;
      } catch (e) {
        if (retry >= maxRetries) rethrow;
        if (retryOnErr != null && !retryOnErr(e, retry)) rethrow;
        retry++;
        continue;
      }
      VerifyBlockStrategy? staregy = VerifyBlockStrategy.always;

      for (final block in blocks.blocks.indexed) {
        if (currentHeight > endHeight) break;

        final state = buildBlockState(
          blocks: blocks,
          index: block.$1,
          previousState: latestState,
          staregy: staregy,
        );
        staregy = null;

        final scan = await scanBlockInner(state);

        if (scan.txes.isNotEmpty &&
            config.strategy == VerifyBlockStrategy.onReceiveFunds) {
          state.verifyBlock(
            strategy: config.strategy,
            previousState: latestState,
            receiveFunds: true,
          );
        }

        latestState = state;

        yield scan;

        currentHeight++;
      }
    }
  }

  MoneroBlockStateInfo buildBlockState({
    required DaemonGetBlockBinResponse blocks,
    required int index,
    MoneroBlockStateInfo? previousState,
    VerifyBlockStrategy? staregy,
  }) {
    final blockEntry = blocks.blocks.elementAtOrNull(index);
    if (blockEntry == null) {
      throw MoneroBlockScannerException.failed(
        "buildBlockState",
        reason: "Block not found at response index.",
        details: {
          "index": index.toString(),
          "startHeight": blocks.startHeight.toString(),
          "availableBlocks": blocks.blocks.length.toString(),
        },
      );
    }

    final block =
        (() {
          try {
            return blockEntry.toBlock();
          } catch (e) {
            throw MoneroBlockScannerException.failed(
              "buildBlockState",
              reason: "Failed to deserialize block from daemon response.",
              details: {"index": index.toString(), "error": e.toString()},
            );
          }
        })();

    final txs =
        (() {
          try {
            return blockEntry.txs.map((e) => e.toTx()).toList();
          } catch (e) {
            throw MoneroBlockScannerException.failed(
              "buildBlockState",
              reason: "Failed to parse transactions inside block.",
              details: {"index": index.toString(), "error": e.toString()},
            );
          }
        })();

    final outputIndexEntry = blocks.outputIndices.elementAtOrNull(index);
    if (outputIndexEntry == null) {
      throw MoneroBlockScannerException.failed(
        "buildBlockState",
        reason: "Missing output indices for block.",
        details: {
          "index": index.toString(),
          "blockHeightHint": blocks.startHeight.toString(),
        },
      );
    }

    // -------------------------------
    // Validate output consistency
    // -------------------------------

    final minerOuts = block.minerTx.vout.length;
    final txOuts = txs.fold<int>(0, (p, t) => p + t.vout.length);
    final totalOutputs = minerOuts + txOuts;

    final totalIndexedOutputs = outputIndexEntry.indices.fold<int>(
      0,
      (p, tx) => p + tx.indices.length,
    );

    final expectedTxGroups = (block.txHashes.length + 1);

    if (totalOutputs != totalIndexedOutputs) {
      throw MoneroBlockScannerException.failed(
        "buildBlockState",
        reason:
            "Output count mismatch between parsed block and daemon indices.",
        details: {
          "minerOutputs": minerOuts.toString(),
          "txOutputs": txOuts.toString(),
          "totalOutputs": totalOutputs.toString(),
          "indexedOutputs": totalIndexedOutputs.toString(),
          "index": index.toString(),
        },
      );
    }

    if (outputIndexEntry.indices.length != expectedTxGroups) {
      throw MoneroBlockScannerException.failed(
        "buildBlockState",
        reason: "Transaction group count mismatch in output indices.",
        details: {
          "expectedGroups": expectedTxGroups.toString(),
          "actualGroups": outputIndexEntry.indices.length.toString(),
          "index": index.toString(),
        },
      );
    }
    final blockHeight = blocks.startHeight + index;
    if (previousState != null && blockHeight != previousState.blockId + 1) {
      throw MoneroBlockScannerException.failed(
        "buildBlockState.invalid_block_height",
        reason: "Block height sequence mismatch detected.",
        details: {
          "expectedHeight": (previousState.blockId + 1).toString(),
          "actualHeight": blockHeight.toString(),
          "previousBlockHeight": previousState.blockId.toString(),
          "responseStartHeight": blocks.startHeight.toString(),
          "responseIndex": index.toString(),
        },
      );
    }

    final state = MoneroBlockStateInfo(
      blockId: blockHeight,
      timestamp: block.timestamp.toIntOrThrow,
      block: block,
      outputIndices: outputIndexEntry,
      transactions: txs,
    );
    return state.verifyBlock(
          previousState: previousState,
          strategy: staregy ?? config.strategy,
        ) ??
        (throw MoneroBlockScannerException.failed(
          "buildBlockState.chain_verification_failed",
          reason: "Block failed chain continuity verification.",
          details: {
            "blockHeight": blockHeight.toString(),
            "strategy": config.strategy.toString(),
          },
        ));
  }

  @override
  Future<DefaultMoneroScannedBlock> scanBlockInner(
    MoneroBlockStateInfo state,
  ) async {
    List<DefaultMoneroScannedTx> txes = [];
    MoneroBlock moneroBlock = state.block;
    final blockTxes = [state.block.minerTx, ...state.transactions];
    for (final txIndex in blockTxes.indexed) {
      final txHash = switch (txIndex.$1) {
        0 => moneroBlock.minerTx.getTxHash(),
        _ => BytesUtils.toHexString(moneroBlock.txHashes[txIndex.$1 - 1]),
      };
      await Future.delayed(Duration.zero);

      final indice = state.outputIndices.indices.elementAtOrNull(txIndex.$1);
      if (indice == null) {
        throw MoneroBlockScannerException.failed(
          "buildBlockState",
          reason: "Missing transaction output indices.",
          details: {
            "block": state.blockId.toString(),
            "index": txIndex.$1.toString(),
          },
        );
      }
      final transaction = txIndex.$2;
      final unlock = config.unlocker.moneroUnlockOutput(
        transaction: transaction,
        outputIndices: indice.indices,
        txHash: txHash,
      );
      final keyImages = transaction.getInputsKeyImages();
      txes.add(
        DefaultMoneroScannedTx(
          txHash: txHash,
          unlockedOutputs: unlock,
          keyImages: keyImages,
        ),
      );
    }
    return DefaultMoneroScannedBlock(
      blockHash: moneroBlock.previousBlockHash(),
      blockHeight: state.blockId,
      blocktime: moneroBlock.timestamp.toIntOrThrow,
      block: moneroBlock,
      txes: txes,
    );
  }
}
