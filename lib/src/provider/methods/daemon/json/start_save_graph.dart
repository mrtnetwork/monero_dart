import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Obsolete. Conserved here for reference.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#start_save_graph
class DaemonRequestStartSaveGraph
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStartSaveGraph();

  @override
  String get method => "start_save_graph";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
