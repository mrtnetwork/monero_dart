import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get list of banned IPs.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_bans
class DaemonRequestGetBans
    extends
        MoneroDaemonRequestParam<DaemonGetBanResponse, Map<String, dynamic>> {
  DaemonRequestGetBans();
  @override
  String get method => "get_bans";
  @override
  Map<String, dynamic> get params => {};
  @override
  DaemonRequestType get encodingType => DaemonRequestType.jsonRPC;

  @override
  DaemonGetBanResponse onResponse(Map<String, dynamic> result) {
    return DaemonGetBanResponse.fromJson(result);
  }
}
