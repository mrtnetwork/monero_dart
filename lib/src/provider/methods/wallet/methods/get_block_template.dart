import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

class DaemonOnGetBlockTemplateResponse extends DaemonBaseResponse {
  final String blockhashingBlob;
  final String blocktemplateBlob;
  final BigInt difficulty;
  final int difficultyTop64;
  final BigInt expectedReward;
  final BigInt height;
  final String nextSeedHash;
  final String prevHash;
  final int rewardOffset;
  final String seedHash;
  final BigInt seedHeight;
  final String wideDifficulty;
  DaemonOnGetBlockTemplateResponse({
    required this.blockhashingBlob,
    required this.blocktemplateBlob,
    required this.difficulty,
    required this.difficultyTop64,
    required this.expectedReward,
    required this.height,
    required this.nextSeedHash,
    required this.prevHash,
    required this.rewardOffset,
    required this.seedHash,
    required this.seedHeight,
    required this.wideDifficulty,
    required super.credits,
    required super.status,
    required super.topHash,
    required bool super.untrusted,
  });

  DaemonOnGetBlockTemplateResponse.fromJson(super.json)
      : blockhashingBlob = json["blockhashing_blob"],
        blocktemplateBlob = json["blocktemplate_blob"],
        difficulty = BigintUtils.parse(json["difficulty"]),
        difficultyTop64 = json["difficulty_top64"],
        expectedReward = BigintUtils.parse(json["expected_reward"]),
        height = BigintUtils.parse(json["height"]),
        nextSeedHash = json["next_seed_hash"],
        prevHash = json["prev_hash"],
        rewardOffset = json["reserved_offset"],
        seedHash = json["seed_hash"],
        wideDifficulty = json["wide_difficulty"],
        seedHeight = BigintUtils.parse(json["seed_height"]),
        super.fromJson();
}
