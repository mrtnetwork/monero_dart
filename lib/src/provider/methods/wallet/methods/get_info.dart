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
      : adjustedTime = json['adjusted_time'],
        altBlocksCount = json['alt_blocks_count'],
        blockSizeLimit = json['block_size_limit'],
        blockSizeMedian = json['block_size_median'],
        blockWeightLimit = json['block_weight_limit'],
        blockWeightMedian = json['block_weight_median'],
        bootstrapDaemonAddress = json['bootstrap_daemon_address'] as String,
        busySyncing = json['busy_syncing'] as bool,
        cumulativeDifficulty = json['cumulative_difficulty'],
        cumulativeDifficultyTop64 = json['cumulative_difficulty_top64'],
        databaseSize = json['database_size'],
        difficulty = json['difficulty'],
        difficultyTop64 = json['difficulty_top64'],
        freeSpace = json['free_space'],
        greyPeerlistSize = json['grey_peerlist_size'],
        height = json['height'],
        heightWithoutBootstrap = json['height_without_bootstrap'],
        incomingConnectionsCount = json['incoming_connections_count'],
        mainnet = json['mainnet'] as bool,
        nettype = json['nettype'] as String,
        offline = json['offline'] as bool,
        outgoingConnectionsCount = json['outgoing_connections_count'],
        rpcConnectionsCount = json['rpc_connections_count'],
        stagenet = json['stagenet'] as bool,
        startTime = json['start_time'],
        synchronized = json['synchronized'] as bool,
        target = json['target'],
        targetHeight = json['target_height'],
        testnet = json['testnet'] as bool,
        topBlockHash = json['top_block_hash'] as String,
        txCount = json['tx_count'],
        txPoolSize = json['tx_pool_size'],
        updateAvailable = json['update_available'] as bool,
        version = json['version'] as String,
        wasBootstrapEverUsed = json['was_bootstrap_ever_used'] as bool,
        whitePeerlistSize = json['white_peerlist_size'],
        wideCumulativeDifficulty = json['wide_cumulative_difficulty'] as String,
        wideDifficulty = json['wide_difficulty'] as String,
        super.fromJson();
}
