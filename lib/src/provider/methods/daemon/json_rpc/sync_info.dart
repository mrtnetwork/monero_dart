import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get synchronization information.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#sync_info
class DaemonRequestSyncInfo extends MoneroDaemonRequestParam<
    DaemonSyncInfoResponse, Map<String, dynamic>> {
  DaemonRequestSyncInfo();

  @override
  String get method => "sync_info";

  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonSyncInfoResponse onResonse(Map<String, dynamic> result) {
    return DaemonSyncInfoResponse.fromJson(result);
  }
}
