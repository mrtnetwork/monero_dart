import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/distribution.dart';

/// Get a histogram of output amounts. For all amounts (possibly filtered by parameters),
/// gives the number of outputs on the chain for that amount. RingCT outputs counts as 0 amount.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_output_distribution
class DaemonRequestGetOutputDistribution extends MoneroDaemonRequestParam<
    OutputDistributionResponse, Map<String, dynamic>> {
  const DaemonRequestGetOutputDistribution({
    required this.amounts,
    this.cumulative = false,
    this.fromHeight,
    this.toHeight,
    this.binary = false,
  });

  /// amounts to look for.
  final List<BigInt> amounts;

  /// States if the result should be cumulative
  final bool cumulative;

  /// (optional, default is 0) starting height to check from
  final int? fromHeight;

  /// (optional, default is 0) ending height to check up to
  final int? toHeight;
  final bool binary;
  @override
  String get method => "get_output_distribution";
  @override
  Map<String, dynamic> get params {
    return {
      "amounts": amounts.map((e) => e.toString()).toList(),
      "cumulative": cumulative,
      "from_height": fromHeight?.toString() ?? BigInt.zero.toString(),
      "to_height": toHeight?.toString() ?? BigInt.zero.toString(),
      "binary": binary,
    };
  }

  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  OutputDistributionResponse onResonse(Map<String, dynamic> result) {
    return OutputDistributionResponse.fromJson(result);
  }
}
