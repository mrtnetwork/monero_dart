import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get synchronization information.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#sync_info
class DaemonRequestSyncInfo
    extends
        MoneroDaemonRequestParam<DaemonSyncInfoResponse, Map<String, dynamic>> {
  DaemonRequestSyncInfo();

  @override
  String get method => "sync_info";

  @override
  DaemonRequestType get encodingType => DaemonRequestType.jsonRPC;

  @override
  DaemonSyncInfoResponse onResponse(Map<String, dynamic> result) {
    return DaemonSyncInfoResponse.fromJson(result);
  }
}
