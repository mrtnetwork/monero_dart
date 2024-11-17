import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Check if an IP address is banned and for how long.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#banned
class DaemonRequestBanned extends MoneroDaemonRequestParam<DaemonBannedResponse,
    Map<String, dynamic>> {
  DaemonRequestBanned(this.address);
  final String address;
  @override
  String get method => "banned";
  @override
  Map<String, dynamic> get params => {"address": address};
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;

  @override
  DaemonBannedResponse onResonse(Map<String, dynamic> result) {
    return DaemonBannedResponse.fromJson(result);
  }
}
