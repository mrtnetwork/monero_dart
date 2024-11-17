import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the node's current height.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_height
class DaemonRequestGetHeight extends MoneroDaemonRequestParam<
    DaemonGetBlockHeightResponse, Map<String, dynamic>> {
  const DaemonRequestGetHeight();

  @override
  String get method => "get_height";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetBlockHeightResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetBlockHeightResponse.fromJson(result);
  }
}
