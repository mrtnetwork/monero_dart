import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Send a command to the daemon to safely disconnect and shut down.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#stop_daemon
class DaemonRequestStopDaemon
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStopDaemon();

  @override
  String get method => "stop_daemon";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
