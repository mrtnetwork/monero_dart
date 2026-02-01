import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/network/config.dart';

class Gamma {
  final GammaDistribution gammaDistribution;
  List<BigInt> _rctOffsets;
  final int end;
  final double avarageOutsTime;
  final BigInt numRctOuts;
  int lowerBound(BigInt value) {
    int left = 0;
    int right = end;

    while (left < right) {
      final int mid = (left + right) ~/ 2;
      if (_rctOffsets[mid] < value) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }
    return left;
  }

  Gamma._({
    required this.gammaDistribution,
    required List<BigInt> rctOffsets,
    required this.end,
    required this.avarageOutsTime,
    required this.numRctOuts,
  }) : _rctOffsets = rctOffsets;
  factory Gamma({
    required List<BigInt> rctOffsets,
    double shape = MoneroNetworkConst.gammaShape,
    double scale = MoneroNetworkConst.gammaScale,
  }) {
    if (rctOffsets.length <
        MoneroNetworkConst.cryptonoteDefaultTxSpendableAge) {
      throw const MoneroCryptoException("Bad offset calculation");
    }
    const int blocksInYear =
        86400 * 365 ~/ MoneroNetworkConst.difficultyTargetV2;
    final int blocksConsider = IntUtils.min(rctOffsets.length, blocksInYear);
    final BigInt outputsConsider =
        rctOffsets.last -
        (blocksConsider < rctOffsets.length
            ? rctOffsets[rctOffsets.length - blocksConsider - 1]
            : BigInt.zero);
    final int end =
        rctOffsets.length -
        (IntUtils.max(1, MoneroNetworkConst.cryptonoteDefaultTxSpendableAge) -
            1);
    final numRctOuts = rctOffsets[end - 1];
    final avgOutputTime =
        MoneroNetworkConst.difficultyTargetV2 *
        (BigInt.from(blocksConsider) / outputsConsider);

    return Gamma._(
      gammaDistribution: GammaDistribution(shape, scale),
      rctOffsets: rctOffsets,
      end: end,
      avarageOutsTime: avgOutputTime,
      numRctOuts: numRctOuts,
    );
  }

  BigInt pick() {
    double x = gammaDistribution.nextDouble();
    x = IntUtils.exp(x);
    if (x > MoneroNetworkConst.defaultUnlockTime) {
      x -= MoneroNetworkConst.defaultUnlockTime;
    } else {
      x =
          gammaDistribution
              .randomIndex(MoneroNetworkConst.recentSpendWindow)
              .toDouble();
    }
    BigInt outIndex = BigInt.from(x ~/ avarageOutsTime);
    if (outIndex >= numRctOuts) {
      return BinaryOps.maxU64;
    }
    outIndex = numRctOuts - BigInt.one - outIndex;
    final index = lowerBound(outIndex);
    if (index == end) {
      throw const MoneroCryptoException("output index not found");
    }
    final BigInt firstRct = index == 0 ? BigInt.zero : _rctOffsets[index - 1];
    final int nrct = (_rctOffsets[index] - firstRct).toInt();
    if (nrct == 0) {
      throw const MoneroCryptoException("No RCT values found in the range");
    }
    return firstRct + BigInt.from(gammaDistribution.randomIndex(nrct));
  }

  void clean() {
    _rctOffsets = [];
  }
}
