import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Gives an estimation on fees per byte.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_fee_estimate
class DaemonRequestGetFeeEstimate
    extends
        MoneroDaemonRequestParam<
          DaemonGetEstimateFeeResponse,
          Map<String, dynamic>
        > {
  const DaemonRequestGetFeeEstimate(this.graceBlocks);
  final int graceBlocks;
  @override
  String get method => "get_fee_estimate";
  @override
  Map<String, dynamic> get params => {"graceBlocks": graceBlocks.toString()};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetEstimateFeeResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetEstimateFeeResponse.fromJson(result);
  }
}
