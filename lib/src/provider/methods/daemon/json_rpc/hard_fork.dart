import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Look up information regarding hard fork voting and readiness.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#hard_fork_info
class DaemonRequestHardForkInfo extends MoneroDaemonRequestParam<
    DaemonHardForkResponse, Map<String, dynamic>> {
  const DaemonRequestHardForkInfo();

  @override
  String get method => "hard_fork_info";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonHardForkResponse onResonse(Map<String, dynamic> result) {
    return DaemonHardForkResponse.fromJson(result);
  }
}
