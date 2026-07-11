import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

class DaemonGetInfoResponse extends DaemonBaseResponse {
  final int adjustedTime;
  final int altBlocksCount;
  final int blockSizeLimit;
  final int blockSizeMedian;
  final int blockWeightLimit;
  final int blockWeightMedian;
  final String bootstrapDaemonAddress;
  final bool busySyncing;
  final int cumulativeDifficulty;
  final int cumulativeDifficultyTop64;
  final int databaseSize;
  final int difficulty;
  final int difficultyTop64;
  final double freeSpace;
  final int greyPeerlistSize;
  final int height;
  final int heightWithoutBootstrap;
  final int incomingConnectionsCount;
  final bool mainnet;
  final String nettype;
  final bool offline;
  final int outgoingConnectionsCount;
  final int rpcConnectionsCount;
  final bool stagenet;
  final int startTime;
  final bool synchronized;
  final int target;
  final int targetHeight;
  final bool testnet;
  final String topBlockHash;
  final int txCount;
  final int txPoolSize;
  final bool updateAvailable;
  final String version;
  final bool wasBootstrapEverUsed;
  final int whitePeerlistSize;
  final String wideCumulativeDifficulty;
  final String wideDifficulty;

  DaemonGetInfoResponse({
    required this.adjustedTime,
    required this.altBlocksCount,
    required this.blockSizeLimit,
    required this.blockSizeMedian,
    required this.blockWeightLimit,
    required this.blockWeightMedian,
    required this.bootstrapDaemonAddress,
    required this.busySyncing,
    required this.cumulativeDifficulty,
    required this.cumulativeDifficultyTop64,
    required this.databaseSize,
    required this.difficulty,
    required this.difficultyTop64,
    required this.freeSpace,
    required this.greyPeerlistSize,
    required this.height,
    required this.heightWithoutBootstrap,
    required this.incomingConnectionsCount,
    required this.mainnet,
    required this.nettype,
    required this.offline,
    required this.outgoingConnectionsCount,
    required this.rpcConnectionsCount,
    required this.stagenet,
    required this.startTime,
    required super.status,
    required this.synchronized,
    required this.target,
    required this.targetHeight,
    required this.testnet,
    required this.topBlockHash,
    required super.topHash,
    required this.txCount,
    required this.txPoolSize,
    required bool super.untrusted,
    required this.updateAvailable,
    required this.version,
    required this.wasBootstrapEverUsed,
    required this.whitePeerlistSize,
    required this.wideCumulativeDifficulty,
    required this.wideDifficulty,
    super.credits,
  });

  DaemonGetInfoResponse.fromJson(super.json)
    : adjustedTime = json.valueAs("adjusted_time"),
      altBlocksCount = json.valueAs("alt_blocks_count"),
      blockSizeLimit = json.valueAs("block_size_limit"),
      blockSizeMedian = json.valueAs("block_size_median"),
      blockWeightLimit = json.valueAs("block_weight_limit"),
      blockWeightMedian = json.valueAs("block_weight_median"),
      bootstrapDaemonAddress = json.valueAs("bootstrap_daemon_address"),
      busySyncing = json.valueAs("busy_syncing"),
      cumulativeDifficulty = json.valueAs("cumulative_difficulty"),
      cumulativeDifficultyTop64 = json.valueAs("cumulative_difficulty_top64"),
      databaseSize = json.valueAs("database_size"),
      difficulty = json.valueAs("difficulty"),
      difficultyTop64 = json.valueAs("difficulty_top64"),
      freeSpace = json.valueAs("free_space"),
      greyPeerlistSize = json.valueAs("grey_peerlist_size"),
      height = json.valueAs("height"),
      heightWithoutBootstrap = json.valueAs("height_without_bootstrap"),
      incomingConnectionsCount = json.valueAs("incoming_connections_count"),
      mainnet = json.valueAs("mainnet"),
      nettype = json.valueAs("nettype"),
      offline = json.valueAs("offline"),
      outgoingConnectionsCount = json.valueAs("outgoing_connections_count"),
      rpcConnectionsCount = json.valueAs("rpc_connections_count"),
      stagenet = json.valueAs("stagenet"),
      startTime = json.valueAs("start_time"),
      synchronized = json.valueAs("synchronized"),
      target = json.valueAs("target"),
      targetHeight = json.valueAs("target_height"),
      testnet = json.valueAs("testnet"),
      topBlockHash = json.valueAs("top_block_hash"),
      txCount = json.valueAs("tx_count"),
      txPoolSize = json.valueAs("tx_pool_size"),
      updateAvailable = json.valueAs("update_available"),
      version = json.valueAs("version"),
      wasBootstrapEverUsed = json.valueAs("was_bootstrap_ever_used"),
      whitePeerlistSize = json.valueAs("white_peerlist_size"),
      wideCumulativeDifficulty = json.valueAs("wide_cumulative_difficulty"),
      wideDifficulty = json.valueAs("wide_difficulty"),
      super.fromJson();
}
