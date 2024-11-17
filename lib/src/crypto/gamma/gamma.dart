import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/network/config.dart';

class Gamma {
  final GammaDistribution gammaDistribution;
  final List<BigInt> rctOffsets;
  final int end;
  final double avarageOutsTime;
  final BigInt numRctOuts;
  int lowerBound(List<BigInt> sortedList, BigInt value) {
    int left = 0;
    int right = sortedList.length;

    while (left < right) {
      final int mid = (left + right) ~/ 2;
      if (sortedList[mid] < value) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }
    return left;
  }

  Gamma._(
      {required this.gammaDistribution,
      required this.rctOffsets,
      // required this.begin,
      required this.end,
      required this.avarageOutsTime,
      required this.numRctOuts});
  factory Gamma(
      {required List<BigInt> rctOffsets,
      double shape = MoneroConst.gammaShape,
      double scale = MoneroConst.gammaScale}) {
    if (rctOffsets.length < MoneroConst.cryptonoteDefaultTxSpendableAge) {
      throw const MoneroCryptoException("Bad offset calculation");
    }
    const int blocksInYear = 86400 * 365 ~/ MoneroConst.difficultyTargetV2;
    final int blocksConsider = IntUtils.min(rctOffsets.length, blocksInYear);
    final BigInt outputsConsider = rctOffsets.last -
        (blocksConsider < rctOffsets.length
            ? rctOffsets[rctOffsets.length - blocksConsider - 1]
            : BigInt.zero);
    final int end = rctOffsets.length -
        (IntUtils.max(1, MoneroConst.cryptonoteDefaultTxSpendableAge) - 1);
    final numRctOuts = rctOffsets[end - 1];
    final avgOutputTime = MoneroConst.difficultyTargetV2 *
        (BigInt.from(blocksConsider) / outputsConsider);
    return Gamma._(
        gammaDistribution: GammaDistribution(shape, scale),
        rctOffsets: rctOffsets,
        end: end,
        avarageOutsTime: avgOutputTime,
        numRctOuts: numRctOuts);
  }

  BigInt pick() {
    double x = gammaDistribution.nextDouble();
    x = IntUtils.exp(x);
    if (x > MoneroConst.defaultUnlockTime) {
      x -= MoneroConst.defaultUnlockTime;
    } else {
      x = gammaDistribution
          .randomIndex(MoneroConst.recentSpendWindow)
          .toDouble();
    }
    BigInt outIndex = BigInt.from(x ~/ avarageOutsTime);
    if (outIndex >= numRctOuts) {
      return maxU64;
    }
    outIndex = numRctOuts - BigInt.one - outIndex;
    final index = lowerBound(rctOffsets.sublist(0, end), outIndex);
    if (index == end) {
      throw const MoneroCryptoException("output index not found");
    }
    final BigInt firstRct = index == 0 ? BigInt.zero : rctOffsets[index - 1];
    final int nrct = (rctOffsets[index] - firstRct).toInt();
    if (nrct == 0) {
      throw const MoneroCryptoException("No RCT values found in the range");
    }
    return firstRct + BigInt.from(gammaDistribution.randomIndex(nrct));
  }
}
