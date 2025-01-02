import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Stop mining on the daemon.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#stop_mining
class DaemonRequestStopMining
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStopMining();

  @override
  String get method => "stop_mining";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
