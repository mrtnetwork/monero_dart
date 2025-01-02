import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the mining status of the daemon.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#mining_status
class DaemonRequestMiningStatus extends MoneroDaemonRequestParam<
    DaemonMininStatusResponse, Map<String, dynamic>> {
  const DaemonRequestMiningStatus();

  @override
  String get method => "mining_status";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonMininStatusResponse onResonse(Map<String, dynamic> result) {
    return DaemonMininStatusResponse.fromJson(result);
  }
}
