import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/distribution.dart';

/// Get a histogram of output amounts. For all amounts (possibly filtered by parameters),
/// gives the number of outputs on the chain for that amount. RingCT outputs counts as 0 amount.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_output_distribution
class DaemonRequestGetOutputDistributionBin extends MoneroDaemonRequestParam<
    OutputDistributionResponse, Map<String, dynamic>> {
  const DaemonRequestGetOutputDistributionBin({
    required this.amounts,
    this.cumulative,
    this.fromHeight,
    this.toHeight,
    this.compress = true,
  });

  /// array of unsigned int; list of block heights
  final List<BigInt> amounts;
  final bool? cumulative;
  final int? fromHeight;
  final int? toHeight;
  final bool compress;
  @override
  String get method => "get_output_distribution.bin";
  @override
  Map<String, dynamic> get params => {
        "amounts": amounts,
        "cumulative": cumulative ?? false,
        "from_height": fromHeight ?? 0,
        "to_height": toHeight,
        "binary": true,
        "compress": compress,
      };
  @override
  DemonRequestType get requestType => DemonRequestType.binary;
  @override
  OutputDistributionResponse onResonse(Map<String, dynamic> result) {
    return OutputDistributionResponse.fromJson(result);
  }
}
