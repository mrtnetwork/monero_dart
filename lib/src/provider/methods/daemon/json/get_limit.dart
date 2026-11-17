import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get daemon bandwidth limits.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_limit
class DaemonRequestGetLimit
    extends
        MoneroDaemonRequestParam<DaemonLimitResponse, Map<String, dynamic>> {
  const DaemonRequestGetLimit();

  @override
  String get method => "get_limit";
  @override
  Map<String, dynamic> get params => {};
  @override
  DaemonRequestType get encodingType => DaemonRequestType.json;

  @override
  DaemonLimitResponse onResponse(Map<String, dynamic> result) {
    return DaemonLimitResponse.fromJson(result);
  }
}
