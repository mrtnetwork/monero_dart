import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Give the node current version.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_version
class DaemonRequestGetVersion extends MoneroDaemonRequestParam<
    DaemonGetVersionResponse, Map<String, dynamic>> {
  DaemonRequestGetVersion();

  @override
  String get method => "get_version";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;

  @override
  DaemonGetVersionResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetVersionResponse.fromJson(result);
  }
}
