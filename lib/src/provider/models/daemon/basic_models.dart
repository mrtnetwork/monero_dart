import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/src/provider/utils/utils.dart';

class DaemonBaseResponse {
  final BigInt? credits;
  final String status;
  final String? topHash;
  final bool? untrusted;
  const DaemonBaseResponse({
    required this.credits,
    required this.status,
    required this.topHash,
    required this.untrusted,
  });
  DaemonBaseResponse.fromJson(Map<String, dynamic> json)
    : credits = BigintUtils.tryParse(json["credits"]),
      status = json["status"],
      topHash = json["top_hash"],
      untrusted = json["untrusted"];

  bool get isOk => status == "OK";
}

abstract class DaemonBaseParams {
  Map<String, dynamic> toJson();
  const DaemonBaseParams();
}

class DaemonBannedResponse extends DaemonBaseResponse {
  final bool banned;
  final int seconds;
  DaemonBannedResponse.fromJson(super.json)
    : banned = json["banned"],
      seconds = json["seconds"] ?? 0,
      super.fromJson();
}

class DaemonChainInfo {
  final String blockHash;
  final BigInt height;
  final BigInt length;
  final BigInt difficulty;
  final String wideDifficulty;
  final BigInt difficultyTop64;
  final List<String> blockHashes;
  final String mainChainParentBlock;

  // fromJson constructor
  DaemonChainInfo.fromJson(Map<String, dynamic> json)
    : blockHash = json['block_hash'],
      height = BigintUtils.parse(json['height']),
      length = BigintUtils.parse(json['length']),
      difficulty = BigintUtils.parse(json['difficulty']),
      wideDifficulty = json['wide_difficulty'],
      difficultyTop64 = BigintUtils.parse(json['difficulty_top64']),
      blockHashes = List<String>.from(json['block_hashes']),
      mainChainParentBlock = json['main_chain_parent_block'];
}

class DaemonGetAlternateChainsResponse extends DaemonBaseResponse {
  /// unsigned int; Number of blocks in longest chain seen by the node.
  final List<DaemonChainInfo> chains;

  DaemonGetAlternateChainsResponse.fromJson(super.json)
    : chains =
          (json["chains"] as List?)
              ?.map((e) => DaemonChainInfo.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonSyncInfoResponse extends DaemonBaseResponse {
  final DaemonConnectionInfoResponse info;

  DaemonSyncInfoResponse.fromJson(super.json)
    : info = DaemonConnectionInfoResponse.fromJson(json["info"]),
      super.fromJson();
}

class DaemonCoinbaseTxSumResponse extends DaemonBaseResponse {
  final BigInt emissionAmount;
  final String wideEmissionAmount;
  final BigInt emissionAmountTop64;
  final BigInt feeAmount;
  final String wideFeeAmount;
  final BigInt feeAmountTop64;

  // fromJson constructor
  DaemonCoinbaseTxSumResponse.fromJson(super.json)
    : emissionAmount = BigintUtils.parse(json['emission_amount']),
      wideEmissionAmount = json['wide_emission_amount'],
      emissionAmountTop64 = BigintUtils.parse(json['emission_amount_top64']),
      feeAmount = BigintUtils.parse(json['fee_amount']),
      wideFeeAmount = json['wide_fee_amount'],
      feeAmountTop64 = BigintUtils.parse(json['fee_amount_top64']),
      super.fromJson();
}

class DaemonGetBlockCountResponse extends DaemonBaseResponse {
  /// unsigned int; Number of blocks in longest chain seen by the node.
  final int count;

  DaemonGetBlockCountResponse.fromJson(super.json)
    : count = IntUtils.parse(json["count"]),
      super.fromJson();
}

class DaemonGenerateBlockResponse extends DaemonBaseResponse {
  /// unsigned int; Number of blocks in longest chain seen by the node.
  final List<String> blocks;
  final BigInt height;
  DaemonGenerateBlockResponse({
    required List<String> blocks,
    required this.height,
    required super.credits,
    required super.status,
    required super.topHash,
    required bool super.untrusted,
  }) : blocks = blocks.immutable;
  DaemonGenerateBlockResponse.fromJson(super.json)
    : blocks = (json["count"] as List).cast<String>().immutable,
      height = BigintUtils.parse(json["height"]),
      super.fromJson();
}

class DaemonTxBacklogEntry {
  final String id;
  final BigInt weight;
  final BigInt fee;

  DaemonTxBacklogEntry.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      weight = BigintUtils.parse(json['weight']),
      fee = BigintUtils.parse(json['fee']);
}

class DaemonGetTxPoolBackLogResponse extends DaemonBaseResponse {
  final List<DaemonTxBacklogEntry> backlog;

  DaemonGetTxPoolBackLogResponse.fromJson(super.json)
    : backlog =
          (json["backlog"] as List)
              .map((e) => DaemonTxBacklogEntry.fromJson(e))
              .toImutableList,
      super.fromJson();
}

class DaemonGetMinerDataResponse extends DaemonBaseResponse {
  final int majorVersion;
  final BigInt height;
  final String prevId;
  final String seedHash;
  final String difficulty;
  final BigInt medianWeight;
  final BigInt alreadyGeneratedCoins;
  final List<DaemonTxBacklogEntry> txBacklog;
  // fromJson constructor
  DaemonGetMinerDataResponse.fromJson(super.json)
    : majorVersion = json['major_version'],
      height = BigintUtils.parse(json['height']),
      prevId = json['prev_id'],
      seedHash = json['seed_hash'],
      difficulty = json['difficulty'],
      medianWeight = BigintUtils.parse(json['median_weight']),
      alreadyGeneratedCoins =
          BigRational.parseDecimal(
            json['already_generated_coins'].toString(),
          ).toBigInt(),
      txBacklog =
          (json["tx_backlog"] as List?)
              ?.map((e) => DaemonTxBacklogEntry.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonPruneBlockchainResponse extends DaemonBaseResponse {
  final bool pruned;
  final BigInt pruningSeed;
  DaemonPruneBlockchainResponse.fromJson(super.json)
    : pruned = json['pruned'],
      pruningSeed = BigintUtils.parse(json['pruning_seed']),
      super.fromJson();
}

class DaemonAddAuxPowResponse extends DaemonBaseResponse {
  final String blocktemplateBlob;
  final String blockhashingBlob;
  final String merkleRoot;
  final BigInt merkleTreeDepth;
  final List<DaemonAuxPowParams> auxPow;
  DaemonAddAuxPowResponse.fromJson(super.json)
    : blocktemplateBlob = json['blocktemplate_blob'],
      blockhashingBlob = json["blockhashing_blob"],
      merkleRoot = json["merkle_root"],
      merkleTreeDepth = BigintUtils.parse(json['merkle_tree_depth']),
      auxPow =
          (json["aux_pow"] as List?)
              ?.map((e) => DaemonAuxPowParams.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonGetHashesBinResponse extends DaemonBaseResponse {
  final BigInt startHeight;
  final BigInt currentHeight;
  final List<String> mBlockIds;
  const DaemonGetHashesBinResponse({
    required super.credits,
    required super.status,
    required super.topHash,
    required super.untrusted,
    required this.startHeight,
    required this.currentHeight,
    required this.mBlockIds,
  });

  DaemonGetHashesBinResponse.fromBinaryResponse(super.json)
    : mBlockIds = ProviderUtils.parseBlockBinaryResponse(
        json["m_block_ids"] ?? [],
      ),
      currentHeight = BigintUtils.parse(json["current_height"]),
      startHeight = BigintUtils.parse(json["start_height"]),
      super.fromJson();
}

class DaemonPublicNodeResponse {
  final String host;
  final BigInt lastSeen;
  final int port;
  final int rpcCreditsPerHash;

  DaemonPublicNodeResponse.fromJson(Map<String, dynamic> json)
    : host = json["host"],
      lastSeen = BigintUtils.parse(json["last_seen"]),
      port = json["rpc_port"],
      rpcCreditsPerHash = json["rpc_credits_per_hash"];
}

class DaemonGetPublicNodeResponse extends DaemonBaseResponse {
  final List<DaemonPublicNodeResponse> white;
  final List<DaemonPublicNodeResponse> gray;

  DaemonGetPublicNodeResponse.fromJson(super.json)
    : white =
          (json["white"] as List?)
              ?.map((e) => DaemonPublicNodeResponse.fromJson(e))
              .toImutableList ??
          [],
      gray =
          (json["gray"] as List?)
              ?.map((e) => DaemonPublicNodeResponse.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonGetTransactionPoolHashesResponse extends DaemonBaseResponse {
  final List<String> txHashes;

  DaemonGetTransactionPoolHashesResponse.fromJson(super.json)
    : txHashes = (json["tx_hashes"] as List).cast(),
      super.fromJson();
}

class DaemonPopBlocksResponse extends DaemonBaseResponse {
  final BigInt height;

  DaemonPopBlocksResponse.fromJson(super.json)
    : height = BigintUtils.parse(json["height"]),
      super.fromJson();
}

class DaemonUpdateResponse extends DaemonBaseResponse {
  final bool update;
  final String version;
  final String userUri;
  final String autoUri;
  final String hash;
  final String path;

  DaemonUpdateResponse.fromJson(super.json)
    : update = json["update"],
      version = json["version"],
      userUri = json["user_uri"],
      autoUri = json["auto_uri"],
      path = json["path"],
      hash = json["hash"],
      super.fromJson();
}

class DaemonGetNetStatsResponse extends DaemonBaseResponse {
  final BigInt startTime;
  final BigInt totalPacketsIn;
  final BigInt totalBytesIn;
  final BigInt totalPacketsOut;
  final BigInt totalBytesOut;

  DaemonGetNetStatsResponse.fromJson(super.json)
    : startTime = BigintUtils.parse(json["start_time"]),
      totalPacketsIn = BigintUtils.parse(json["total_packets_in"]),
      totalBytesIn = BigintUtils.parse(json["total_bytes_in"]),
      totalPacketsOut = BigintUtils.parse(json["total_packets_out"]),
      totalBytesOut = BigintUtils.parse(json["total_bytes_out"]),
      super.fromJson();
}

class DaemonInPeersResponse extends DaemonBaseResponse {
  final int inPeers;

  DaemonInPeersResponse.fromJson(super.json)
    : inPeers = json["in_peers"],
      super.fromJson();
}

class DaemonOutPeersResponse extends DaemonBaseResponse {
  final int outPeers;

  DaemonOutPeersResponse.fromJson(super.json)
    : outPeers = json["out_peers"],
      super.fromJson();
}

class DaemonLimitResponse extends DaemonBaseResponse {
  final BigInt limitDown;
  final BigInt limitUp;

  DaemonLimitResponse.fromJson(super.json)
    : limitDown = BigintUtils.parse(json["limit_down"]),
      limitUp = BigintUtils.parse(json["limit_up"]),
      super.fromJson();
}

class DaemonTxPoolHistoResponse {
  final int txs;
  final BigInt bytes;

  DaemonTxPoolHistoResponse.fromJson(Map<String, dynamic> json)
    : txs = json["txs"],
      bytes = BigintUtils.parse(json["bytes"]);
}

class DaemonTxPoolStatsResponse {
  final BigInt bytesTotal;
  final int bytesMin;
  final int bytesMax;
  final int bytesMed;
  final BigInt feeTotal;
  final BigInt oldest;
  final int txsTotal;
  final int numFailing;
  final int num10m;
  final int numNotRelayed;
  final BigInt histo_98pc;
  final List<DaemonTxPoolHistoResponse> histo;
  final int numDoubleSpends;

  DaemonTxPoolStatsResponse.fromJson(Map<String, dynamic> json)
    : bytesTotal = BigintUtils.parse(json["bytes_total"]),
      bytesMin = json["bytes_min"],
      bytesMax = json["bytes_max"],
      bytesMed = json["bytes_med"],
      txsTotal = json["txs_total"],
      numFailing = json["num_failing"],
      num10m = json["num_10m"],
      numNotRelayed = json["num_not_relayed"],
      numDoubleSpends = json["num_double_spends"],
      feeTotal = BigintUtils.parse(json["fee_total"]),
      oldest = BigintUtils.parse(json["oldest"]),
      histo_98pc = BigintUtils.parse(json["histo_98pc"]),
      histo =
          (json["histo"] as List?)
              ?.map((e) => DaemonTxPoolHistoResponse.fromJson(e))
              .toImutableList ??
          [];
}

class DaemonGetTransactionPoolStatsResponse extends DaemonBaseResponse {
  final DaemonTxPoolStatsResponse poolStats;

  DaemonGetTransactionPoolStatsResponse.fromJson(super.json)
    : poolStats = DaemonTxPoolStatsResponse.fromJson(json["pool_stats"]),
      super.fromJson();
}

class DaemonSetLogCategoriesResponse extends DaemonBaseResponse {
  final String categories;

  DaemonSetLogCategoriesResponse.fromJson(super.json)
    : categories = json["categories"],
      super.fromJson();
}

class DaemonPeerResponse {
  final BigInt id;
  final String host;
  final int ip;
  final int port;
  final int rpcPort;
  final int rpcCreditsPerHash;
  final int pruningSeed;
  final BigInt lastSeen;

  DaemonPeerResponse.fromJson(Map<String, dynamic> json)
    : id = BigintUtils.parse(json["id"]),
      host = json["host"],
      ip = json["ip"],
      port = json["port"],
      rpcPort = json["rpc_port"],
      rpcCreditsPerHash = json["rpc_credits_per_hash"],
      pruningSeed = json["pruning_seed"],
      lastSeen = BigintUtils.parse(json["last_seen"]);
}

class DaemonGetPeerListResponse extends DaemonBaseResponse {
  final List<DaemonPeerResponse> whiteList;
  final List<DaemonPeerResponse> grayList;
  DaemonGetPeerListResponse.fromJson(super.json)
    : whiteList =
          (json["white_list"] as List?)
              ?.map((e) => DaemonPeerResponse.fromJson(e))
              .toImutableList ??
          [],
      grayList =
          (json["gray_list"] as List?)
              ?.map((e) => DaemonPeerResponse.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonMininStatusResponse extends DaemonBaseResponse {
  final bool active;
  final BigInt speed;
  final int threadsCount;
  final String address;
  final String powAlgorithm;
  bool isBackgroundMiningEnabled;
  final int bgIdleThreshold;
  final int bgMinIdleSeconds;
  bool bgIgnoreBattery;
  final int bgTarget;
  final int blockTarget;
  final BigInt blockReward;
  final BigInt difficulty;
  final String wideDifficulty;
  final BigInt difficultyTop64;

  DaemonMininStatusResponse.fromJson(super.json)
    : active = json['active'],
      speed = BigintUtils.parse(json['speed']),
      threadsCount = json['threads_count'],
      address = json['address'],
      powAlgorithm = json['pow_algorithm'],
      isBackgroundMiningEnabled = json['is_background_mining_enabled'],
      bgIdleThreshold = json['bg_idle_threshold'],
      bgMinIdleSeconds = json['bg_min_idle_seconds'],
      bgIgnoreBattery = json['bg_ignore_battery'],
      bgTarget = json['bg_target'],
      blockTarget = json['block_target'],
      blockReward = BigintUtils.parse(json['block_reward']),
      difficulty = BigintUtils.parse(json['difficulty']),
      wideDifficulty = json['wide_difficulty'],
      difficultyTop64 = BigintUtils.parse(json['difficulty_top64']),
      super.fromJson();
}

enum DaemonKeyImageSpentStatus {
  unspent,
  spentInBlockchain,
  spentInPool;

  bool get isSpent => this != unspent;
  bool get isUnspent => this == unspent;
}

class DaemonIsKeyImageSpentResponse extends DaemonBaseResponse {
  final List<DaemonKeyImageSpentStatus> spentStatus;
  DaemonIsKeyImageSpentResponse(List<DaemonKeyImageSpentStatus> spentStatus)
    : spentStatus = spentStatus.immutable,
      super(credits: BigInt.zero, status: 'OK', topHash: '', untrusted: false);

  DaemonIsKeyImageSpentResponse.fromJson(super.json)
    : spentStatus =
          (json["spent_status"] as List)
              .cast<int>()
              .map((e) => DaemonKeyImageSpentStatus.values.elementAt(e))
              .toImutableList,
      super.fromJson();
}

class DaemonGetAltBlockHashesResponse extends DaemonBaseResponse {
  final List<String> blksHashes;

  DaemonGetAltBlockHashesResponse.fromJson(super.json)
    : blksHashes = (json["blks_hashes"] as List).cast<String>().toImutableList,
      super.fromJson();
}

class DaemonSendRawTxResponse extends DaemonBaseResponse {
  final String reason;
  final bool notRelayed;
  final bool lowMixin;
  final bool doubleSpend;
  final bool invalidInput;
  final bool invalidOutput;
  final bool tooBig;
  final bool overspend;
  final bool feeTooLow;
  final bool tooFewOutputs;
  final bool sanityCheckFailed;
  final bool txExtraTooBig;
  final bool nonzeroUnlockTime;
  bool get isSuccess => status == "OK";

  DaemonSendRawTxResponse.fromJson(super.json)
    : reason = json['reason'] ?? '',
      notRelayed = json['not_relayed'] ?? false,
      lowMixin = json['low_mixin'] ?? false,
      doubleSpend = json['double_spend'] ?? false,
      invalidInput = json['invalid_input'] ?? false,
      invalidOutput = json['invalid_output'] ?? false,
      tooBig = json['too_big'] ?? false,
      overspend = json['overspend'] ?? false,
      feeTooLow = json['fee_too_low'] ?? false,
      tooFewOutputs = json['too_few_outputs'] ?? false,
      sanityCheckFailed = json['sanity_check_failed'] ?? false,
      txExtraTooBig = json['tx_extra_too_big'] ?? false,
      nonzeroUnlockTime = json['nonzero_unlock_time'] ?? false,
      super.fromJson();

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'not_relayed': notRelayed,
      'low_mixin': lowMixin,
      'double_spend': doubleSpend,
      'invalid_input': invalidInput,
      'invalid_output': invalidOutput,
      'too_big': tooBig,
      'overspend': overspend,
      'fee_too_low': feeTooLow,
      'too_few_outputs': tooFewOutputs,
      'sanity_check_failed': sanityCheckFailed,
      'tx_extra_too_big': txExtraTooBig,
      'nonzero_unlock_time': nonzeroUnlockTime,
    };
  }

  String? getErrorMessage() {
    if (isSuccess) return null;
    if (reason.isNotEmpty) return reason;

    final List<String> errors = [];

    if (doubleSpend) errors.add("Transaction is a double spend.");
    if (feeTooLow) errors.add("Fee is too low.");
    if (invalidInput) errors.add("Input is invalid.");
    if (invalidOutput) errors.add("Output is invalid.");
    if (lowMixin) errors.add("Mixin count is too low.");
    if (notRelayed) errors.add("Transaction was not relayed.");
    if (overspend) errors.add("Transaction uses more money than available.");
    if (tooBig) errors.add("Transaction size is too big.");
    if (tooFewOutputs) errors.add("Too few outputs.");
    if (sanityCheckFailed) errors.add("Sanity check failed.");
    if (txExtraTooBig) errors.add("Extra field in transaction is too big.");
    if (nonzeroUnlockTime) errors.add("Transaction has non-zero unlock time.");

    return errors.isEmpty ? "Unknown error occurred." : errors.join(' ');
  }
}

class DaemonGetTxGlobalOutputIndexesResponse extends DaemonBaseResponse {
  final List<BigInt> oIndexes;

  DaemonGetTxGlobalOutputIndexesResponse.fromJson(super.json)
    : oIndexes =
          (json["o_indexes"] as List)
              .map((e) => BigintUtils.parse(e))
              .toImutableList,
      super.fromJson();
}

class DaemonBanParams extends DaemonBaseParams {
  final String host;
  final int ip;
  final bool ban;
  final int seconds;
  const DaemonBanParams({
    required this.host,
    required this.ip,
    required this.ban,
    required this.seconds,
  });
  factory DaemonBanParams.fromJson(Map<String, dynamic> json) {
    return DaemonBanParams(
      host: json["host"],
      ip: json["ip"],
      ban: json["ban"] ?? true,
      seconds: json["seconds"],
    );
  }
  @override
  Map<String, dynamic> toJson() {
    return {"host": host, "ip": ip, "ban": ban, "seconds": seconds};
  }
}

class DaemonGetBanResponse extends DaemonBaseResponse {
  final List<DaemonBanParams> bans;

  DaemonGetBanResponse.fromJson(super.json)
    : bans =
          (json["bans"] as List?)
              ?.map((e) => DaemonBanParams.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonGetLastBlockHeaderResponse extends DaemonBaseResponse {
  final DaemonBlockHeaderResponse blockHeader;

  DaemonGetLastBlockHeaderResponse.fromJson(super.json)
    : blockHeader = DaemonBlockHeaderResponse.fromJson(json["block_header"]),
      super.fromJson();
}

class DaemonGetBlockResponse extends DaemonBaseResponse {
  final DaemonBlockHeaderResponse blockHeader;
  final List<String> txHashes;
  final String blob;
  final String json;
  DaemonGetBlockResponse.fromJson(super.json)
    : blockHeader = DaemonBlockHeaderResponse.fromJson(json["block_header"]),
      txHashes = (json["tx_hashes"] as List).cast<String>().toImutableList,
      blob = json["blob"],
      json = json["json"],
      super.fromJson();
}

class DaemonBlockHeadersResponse extends DaemonBaseResponse {
  final DaemonBlockHeaderResponse? blockHeader;
  final List<DaemonBlockHeaderResponse> blockHeaders;

  DaemonBlockHeadersResponse.fromJson(super.json)
    : blockHeader =
          json["block_header"] == null
              ? null
              : DaemonBlockHeaderResponse.fromJson(json["block_header"]),
      blockHeaders =
          (json["block_headers"] as List?)
              ?.map((e) => DaemonBlockHeaderResponse.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonBlockHeadersByRangeResponse extends DaemonBaseResponse {
  final List<DaemonBlockHeaderResponse> headers;

  DaemonBlockHeadersByRangeResponse.fromJson(super.json)
    : headers =
          (json["headers"] as List)
              .map((e) => DaemonBlockHeaderResponse.fromJson(e))
              .toImutableList,
      super.fromJson();
}

class DaemonBlockHeaderResponse {
  final int majorVersion;
  final int minorVersion;
  final BigInt timestamp;
  final String prevHash;
  final int nonce;
  final bool orphanStatus;
  final int height;
  final BigInt depth;
  final String hash;
  final BigInt difficulty;
  final String wideDifficulty;
  final BigInt difficultyTop64;
  final BigInt cumulativeDifficulty;
  final String wideCumulativeDifficulty;
  final BigInt cumulativeDifficultyTop64;
  final BigInt reward;
  final int blockSize;
  final int blockWeight;
  final BigInt numTxes;
  final String powHash;
  final BigInt longTermWeight;
  final String minerTxHash;

  // fromJson constructor
  DaemonBlockHeaderResponse.fromJson(Map<String, dynamic> json)
    : majorVersion = json['major_version'],
      minorVersion = json['minor_version'],
      timestamp = BigintUtils.parse(json['timestamp']),
      prevHash = json['prev_hash'],
      nonce = json['nonce'],
      orphanStatus = json['orphan_status'],
      height = IntUtils.parse(json['height']),
      depth = BigintUtils.parse(json['depth']),
      hash = json['hash'],
      difficulty = BigintUtils.parse(json['difficulty']),
      wideDifficulty = json['wide_difficulty'],
      difficultyTop64 = BigintUtils.parse(json['difficulty_top64']),
      cumulativeDifficulty = BigintUtils.parse(json['cumulative_difficulty']),
      wideCumulativeDifficulty = json['wide_cumulative_difficulty'],
      cumulativeDifficultyTop64 = BigintUtils.parse(
        json['cumulative_difficulty_top64'],
      ),
      reward = BigintUtils.parse(json['reward']),
      blockSize = IntUtils.tryParse(json['block_size']) ?? 0,
      blockWeight = IntUtils.tryParse(json['block_weight']) ?? 0,
      numTxes = BigintUtils.parse(json['num_txes']),
      powHash = json['pow_hash'],
      longTermWeight =
          BigintUtils.tryParse(json['long_term_weight']) ?? BigInt.zero,
      minerTxHash = json['miner_tx_hash'];
}

class DaemonHFEnteryResponse {
  final int hfVersion;
  final BigInt height;
  const DaemonHFEnteryResponse({required this.height, required this.hfVersion});
  factory DaemonHFEnteryResponse.fromJson(Map<String, dynamic> json) {
    return DaemonHFEnteryResponse(
      height: BigintUtils.parse(json["height"]),
      hfVersion: json["hf_version"],
    );
  }
}

class DaemonGetVersionResponse extends DaemonBaseResponse {
  final int version;
  final bool release;
  final BigInt currentHeight;
  final BigInt targetHeight;
  final List<DaemonHFEnteryResponse> hardForks;
  DaemonGetVersionResponse.fromJson(super.json)
    : version = json["version"],
      release = json["release"],
      currentHeight =
          BigintUtils.tryParse(json["current_height"]) ?? BigInt.zero,
      targetHeight = BigintUtils.tryParse(json["target_height"]) ?? BigInt.zero,
      hardForks =
          (json["hardForks"] as List?)
              ?.map((e) => DaemonHFEnteryResponse.fromJson(e))
              .toImutableList ??
          [],
      super.fromJson();
}

class DaemonGetOutputHistogramResponse extends DaemonBaseResponse {
  final List<DaemonHistogramResponse> histogram;
  DaemonGetOutputHistogramResponse.fromJson(super.json)
    : histogram =
          (json["histogram"] as List?)
              ?.map((e) => DaemonHistogramResponse.fromJson(e))
              .toList() ??
          [],
      super.fromJson();
}

class DaemonHistogramResponse {
  final BigInt amount;
  final BigInt recentInstances;
  final BigInt totalInstances;
  final BigInt unlockedInstances;
  const DaemonHistogramResponse({
    required this.amount,
    required this.recentInstances,
    required this.totalInstances,
    required this.unlockedInstances,
  });
  factory DaemonHistogramResponse.fromJson(Map<String, dynamic> json) {
    return DaemonHistogramResponse(
      amount: BigintUtils.parse(json["amount"]),
      recentInstances: BigintUtils.parse(json["recent_instances"]),
      totalInstances: BigintUtils.parse(json["total_instances"]),
      unlockedInstances: BigintUtils.parse(json["unlocked_instances"]),
    );
  }
}

class DaemonGetBlockHeightResponse extends DaemonBaseResponse {
  final String hash;
  final int height;
  DaemonGetBlockHeightResponse({
    required this.hash,
    required this.height,
    required BigInt super.credits,
    required super.status,
    required String super.topHash,
    required bool super.untrusted,
  });
  DaemonGetBlockHeightResponse.fromJson(super.json)
    : hash = json["hash"],
      height = IntUtils.parse(json["height"]),
      super.fromJson();
}

class DaemonHardForkResponse extends DaemonBaseResponse {
  int earliestHeight;
  bool enabled;
  int state;
  int threshold;
  int version;
  int votes;
  int voting;
  int window;

  DaemonHardForkResponse({
    required super.credits,
    required this.earliestHeight,
    required this.enabled,
    required this.state,
    required super.status,
    required this.threshold,
    required super.topHash,
    required bool super.untrusted,
    required this.version,
    required this.votes,
    required this.voting,
    required this.window,
  });

  DaemonHardForkResponse.fromJson(super.json)
    : earliestHeight = json['earliest_height'],
      enabled = json['enabled'],
      state = json['state'],
      threshold = json['threshold'],
      version = json['version'],
      votes = json['votes'],
      voting = json['voting'],
      window = json['window'],
      super.fromJson();
}

class DaemonAuxPowParams extends DaemonBaseParams {
  final String id;
  final String hash;
  const DaemonAuxPowParams({required this.id, required this.hash});
  factory DaemonAuxPowParams.fromJson(Map<String, dynamic> json) {
    return DaemonAuxPowParams(id: json["id"], hash: json["hash"]);
  }

  @override
  Map<String, dynamic> toJson() {
    return {"id": id, "hash": hash};
  }
}

class DaemonGetConnectionsResponse extends DaemonBaseResponse {
  final List<DaemonConnectionInfoResponse> connections;

  DaemonGetConnectionsResponse.fromJson(super.json)
    : connections =
          (json["connections"] as List)
              .map((e) => DaemonConnectionInfoResponse.fromJson(e))
              .toImutableList,
      super.fromJson();
}

class DaemonConnectionInfoResponse {
  final bool incoming;
  final bool localhost;
  final bool localIp;
  final bool ssl;

  final String address;
  final String host;
  final String ip;
  final String port;
  final int rpcPort;
  final int rpcCreditsPerHash;

  final String peerId;

  final BigInt recvCount;
  final BigInt recvIdleTime;

  final BigInt sendCount;
  final BigInt sendIdleTime;

  final String state;

  final BigInt liveTime;

  final BigInt avgDownload;
  final BigInt currentDownload;

  final BigInt avgUpload;
  final BigInt currentUpload;

  final int supportFlags;

  final String connectionId;

  final BigInt height;

  final int pruningSeed;

  final int addressType;

  // fromJson constructor
  DaemonConnectionInfoResponse.fromJson(Map<String, dynamic> json)
    : incoming = json['incoming'],
      localhost = json['localhost'],
      localIp = json['local_ip'],
      ssl = json['ssl'],
      address = json['address'],
      host = json['host'],
      ip = json['ip'],
      port = json['port'],
      rpcPort = json['rpc_port'],
      rpcCreditsPerHash = json['rpc_credits_per_hash'],
      peerId = json['peer_id'],
      recvCount = BigintUtils.parse(json['recv_count']),
      recvIdleTime = BigintUtils.parse(json['recv_idle_time']),
      sendCount = BigintUtils.parse(json['send_count']),
      sendIdleTime = BigintUtils.parse(json['send_idle_time']),
      state = json['state'],
      liveTime = BigintUtils.parse(json['live_time']),
      avgDownload = BigintUtils.parse(json['avg_download']),
      currentDownload = BigintUtils.parse(json['current_download']),
      avgUpload = BigintUtils.parse(json['avg_upload']),
      currentUpload = BigintUtils.parse(json['current_upload']),
      supportFlags = json['support_flags'],
      connectionId = json['connection_id'],
      height = BigintUtils.parse(json['height']),
      pruningSeed = json['pruning_seed'],
      addressType = json['address_type'];
}

class DaemonGetEstimateFeeResponse extends DaemonBaseResponse {
  final BigInt fee;
  final List<BigInt> fees;
  final BigInt quantizationMask;
  DaemonGetEstimateFeeResponse.fromJson(super.json)
    : fee = BigintUtils.parse(json["fee"]),
      fees =
          (json["fees"] as List)
              .map((e) => BigintUtils.parse(e))
              .toImutableList,
      quantizationMask = BigintUtils.parse(json["quantization_mask"]),
      super.fromJson();
  DaemonGetEstimateFeeResponse({
    required this.fee,
    required List<BigInt> fees,
    required this.quantizationMask,
    required super.credits,
    required super.status,
    required super.topHash,
    required bool super.untrusted,
  }) : fees = fees.immutable;
}

class DaemonGetOutRequestParams {
  final BigInt amount;
  final BigInt index;
  const DaemonGetOutRequestParams({required this.amount, required this.index});
  factory DaemonGetOutRequestParams.fromJson(Map<String, dynamic> json) {
    return DaemonGetOutRequestParams(
      amount: BigintUtils.parse(json["amount"]),
      index: BigintUtils.parse(json["index"]),
    );
  }
  Map<String, dynamic> toJson() {
    return {"amount": amount.toString(), "index": index.toString()};
  }
}
