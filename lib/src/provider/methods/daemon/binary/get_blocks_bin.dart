import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/block.dart';
import 'package:monero_dart/src/serialization/storage_format/types/binary_container.dart';

/// Get all blocks info. Binary request.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_blocksbin
class DaemonRequestGetBlocksBin extends MoneroDaemonRequestParam<
    DaemonGetBlockBinResponse, Map<String, dynamic>> {
  DaemonRequestGetBlocksBin({
    List<String> blockIds = const [],
    this.startHeight = 0,
    this.prune = true,
    this.requestedInfo = DaemonRequestBlocksInfo.blocksOnly,
    this.noMinerTx = false,
    this.highHeightOk = false,
    this.poolInfoSince,
  }) : blockIds = blockIds.immutable;

  /// first 10 blocks id goes sequential, next goes in pow(2,n) offset,
  /// like 2, 4, 8, 16, 32, 64 and so on, and the last one is always genesis block
  final List<String> blockIds;
  final int startHeight;
  final DaemonRequestBlocksInfo requestedInfo;
  final bool prune;
  final bool noMinerTx;
  final bool highHeightOk;
  final BigInt? poolInfoSince;
  @override
  String get method => "getblocks.bin";
  @override
  Map<String, dynamic> get params => {
        "block_ids": MoneroStorageBinary.fromListOfHex(blockIds),
        "start_height": startHeight,
        "requested_info": requestedInfo.index,
        "no_miner_tx": noMinerTx,
        "prune": prune,
        "high_height_ok": highHeightOk,
        "pool_info_since": poolInfoSince ?? BigInt.zero
      };
  @override
  DemonRequestType get requestType => DemonRequestType.binary;
  @override
  DaemonGetBlockBinResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetBlockBinResponse.fromJson(result);
  }
}
