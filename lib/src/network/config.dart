/// the network config constants.
class MoneroNetworkConst {
  /// transaction default unlock time
  static BigInt get unlockTime => BigInt.zero;

  /// current monero tx version.
  static const int currentVersion = 2;

  /// chain parameters.
  static const int cryptonoteMinedMoneyUnlockWindow = 60;
  static const int cryptonoteDefaultTxSpendableAge = 10;
  static const int blockchainTimestampCheckWindow = 60;
  static const int difficultyTargetV2 = 120;
  static const int feeEstimateGraceBlocks = 10;
  static const int bulletproofMaxOutputs = 16;
  static const int bulletproofPlussMaxOutputs = 16;
  static const int defaultRingSize = 16;
  static const int hfVersionPerByteFee = 8;
  static const int paymentIdLength = 8;
  static const double recentOutputRatio = 0.5;
  static const double recentOutputDays = 1.8;
  static final int recentOutputZone = (recentOutputDays * 86400).toInt();
  static const int defaultUnlockTime =
      cryptonoteDefaultTxSpendableAge * difficultyTargetV2;
  static const int recentSpendWindow = 15 * difficultyTargetV2;
  static const double gammaShape = 19.28;
  static const double gammaScale = 1 / 1.61;

  /// transaction proof prefixes.
  static const String proofOutV2Prefix = "OutProofV2";
  static const String proofInV2Prefix = "InProofV2";
  static const String proofOutV1Prefix = "OutProofV1";
  static const String proofInV1Prefix = "InProofV1";
}
