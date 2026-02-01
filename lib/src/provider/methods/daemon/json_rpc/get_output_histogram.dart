import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get a histogram of output amounts. For all amounts (possibly filtered by parameters),
/// gives the number of outputs on the chain for that amount. RingCT outputs counts as 0 amount.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_output_histogram
class DaemonRequestGetOutputHistogram
    extends
        MoneroDaemonRequestParam<
          DaemonGetOutputHistogramResponse,
          Map<String, dynamic>
        > {
  DaemonRequestGetOutputHistogram({
    required this.amounts,
    required this.minCount,
    required this.maxCount,
    required this.unlocked,
    required this.recentCutoff,
  });

  final List<BigInt> amounts;
  final BigInt minCount;
  final BigInt maxCount;
  final bool unlocked;
  final BigInt recentCutoff;
  @override
  String get method => "get_output_histogram";
  @override
  Map<String, dynamic> get params => {
    "amounts": amounts.map((e) => e.toString()).toList(),
    "min_count": minCount.toString(),
    "max_count": maxCount.toString(),
    "unlocked": unlocked,
    "recent_cutoff": recentCutoff.toString(),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetOutputHistogramResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetOutputHistogramResponse.fromJson(result);
  }
}
