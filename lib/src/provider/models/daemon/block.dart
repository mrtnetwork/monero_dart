import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/models/block/block.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

class TxWithTxHashResponse {
  final MoneroTransaction transaction;
  final String txHash;
  const TxWithTxHashResponse({required this.transaction, required this.txHash});
}

class DaemonTxBlobEntryResponse {
  final String blob;
  final String? prunableHash;
  const DaemonTxBlobEntryResponse(
      {required this.blob, required this.prunableHash});
  factory DaemonTxBlobEntryResponse.fromJson(Map<String, dynamic> json) {
    return DaemonTxBlobEntryResponse(
        blob: json["blob"], prunableHash: json["prunable_hash"]);
  }
  MoneroTransaction toTx() {
    return MoneroTransaction.deserialize(BytesUtils.fromHexString(blob));
  }
}

class DaemonBlockCompleteEntryResponse {
  final bool pruned;
  final String block;
  final BigInt blockWeight;
  final List<DaemonTxBlobEntryResponse> txs;
  DaemonBlockCompleteEntryResponse(
      {required this.pruned,
      required this.block,
      required this.blockWeight,
      required List<DaemonTxBlobEntryResponse> txs})
      : txs = txs.immutable;
  factory DaemonBlockCompleteEntryResponse.fromJson(Map<String, dynamic> json) {
    return DaemonBlockCompleteEntryResponse(
        pruned: json["pruned"] ?? false,
        block: json["block"],
        blockWeight: BigintUtils.tryParse(json["block_weight"]) ?? BigInt.zero,
        txs: (json["txs"] as List?)?.map((e) {
              if (e is String) {
                return DaemonTxBlobEntryResponse(blob: e, prunableHash: null);
              }
              return DaemonTxBlobEntryResponse.fromJson(e);
            }).toList() ??
            []);
  }

  List<MoneroTransaction> getTxes() {
    return txs.map((e) => e.toTx()).toList();
  }

  MoneroBlock toBlock() {
    return MoneroBlock.deserialize(BytesUtils.fromHexString(block));
  }
}

class DaemonTxOutputIndicesResponse {
  final List<BigInt> indices;
  DaemonTxOutputIndicesResponse(List<BigInt> indices)
      : indices = indices.immutable;
  factory DaemonTxOutputIndicesResponse.fromJson(Map<String, dynamic> json) {
    return DaemonTxOutputIndicesResponse((json["indices"] as List)
        .map<BigInt>((e) => BigintUtils.parse(e))
        .toList());
  }
}

class DaemonPoolTxInfoResponse {
  final String txHash;
  final String txBlob;
  final bool doubleSpendSeen;
  DaemonPoolTxInfoResponse(
      {required this.txBlob,
      required this.txHash,
      required this.doubleSpendSeen});
  factory DaemonPoolTxInfoResponse.fromJson(Map<String, dynamic> json) {
    return DaemonPoolTxInfoResponse(
        doubleSpendSeen: json["double_spend_seen"],
        txBlob: json["tx_blob"],
        txHash: json["tx_hash"]);
  }
}

class DaemonBlockOutputIndicesResponse {
  final List<DaemonTxOutputIndicesResponse> indices;
  DaemonBlockOutputIndicesResponse(List<DaemonTxOutputIndicesResponse> indices)
      : indices = indices.immutable;
  factory DaemonBlockOutputIndicesResponse.fromJson(Map<String, dynamic> json) {
    return DaemonBlockOutputIndicesResponse((json["indices"] as List)
        .map<DaemonTxOutputIndicesResponse>(
            (e) => DaemonTxOutputIndicesResponse.fromJson(e))
        .toList());
  }
}

enum PoolInfoExtent { none, incremental, full }

enum DaemonRequestBlocksInfo { blocksOnly, blocksAndPool, poolOnly }

class DaemonGetBlockBinResponse extends DaemonBaseResponse {
  final PoolInfoExtent poolInfoExtent;
  final List<DaemonBlockCompleteEntryResponse> blocks;
  final BigInt startHeight;
  final BigInt currentHeight;
  final String? topBlockHash;
  final List<DaemonBlockOutputIndicesResponse> outputIndices;
  final BigInt daemonTime;
  final List<DaemonPoolTxInfoResponse>? addedPoolTxes;
  final List<String>? remainingAddedPoolTxids;
  final List<String>? removedPoolTxids;

  DaemonGetBlockBinResponse.fromJson(super.json)
      : poolInfoExtent = PoolInfoExtent.values
            .elementAt(IntUtils.parse(json["pool_info_extent"] ?? 0)),
        blocks = (json["blocks"] as List)
            .map((e) => DaemonBlockCompleteEntryResponse.fromJson(e))
            .toImutableList,
        startHeight = BigintUtils.parse(json["start_height"]),
        currentHeight = BigintUtils.parse(json["current_height"]),
        topBlockHash = json["top_block_hash"],
        outputIndices = (json["output_indices"] as List)
            .map((e) => DaemonBlockOutputIndicesResponse.fromJson(e))
            .toImutableList,
        daemonTime = BigintUtils.tryParse(json["daemon_time"]) ?? BigInt.zero,
        addedPoolTxes = (json["added_pool_txs"] as List?)
            ?.map((e) => DaemonPoolTxInfoResponse.fromJson(e))
            .toImutableList,
        remainingAddedPoolTxids =
            (json["remaining_added_pool_txids"] as List?)?.cast(),
        removedPoolTxids = (json["removed_pool_txids"] as List?)?.cast(),
        super.fromJson();

  List<TxWithTxHashResponse> toTxes() {
    if (blocks.length != outputIndices.length) {
      throw const DartMoneroPluginException(
          "Invalid response. miss match blocks and output indices");
    }
    final txWithIndices = List.generate(blocks.length, (i) {
      final block = blocks[i];
      final mBlock = block.toBlock();
      final txes = block.getTxes();
      final txIds = mBlock.txIds();
      if (txes.length != txIds.length) {
        throw const DartMoneroPluginException(
            "Invalid response. miss match txes and block tx hashes.");
      }
      final withIndices = List.generate(txes.length, (e) {
        return TxWithTxHashResponse(transaction: txes[e], txHash: txIds[e]);
      });
      return withIndices;
    });
    return txWithIndices.expand((e) => e).toList();
  }


  

}

class DaemonGetBlocksByHeightResponse extends DaemonBaseResponse {
  final List<DaemonBlockCompleteEntryResponse> blocks;

  DaemonGetBlocksByHeightResponse.fromJson(super.json)
      : blocks = (json["blocks"] as List)
            .map((e) => DaemonBlockCompleteEntryResponse.fromJson(e))
            .toImutableList,
        super.fromJson();
}
