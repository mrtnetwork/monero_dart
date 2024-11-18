import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Obsolete. Conserved here for reference.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#stop_save_graph
class DaemonRequestStopSaveGraph
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStopSaveGraph();

  @override
  String get method => "stop_save_graph";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
