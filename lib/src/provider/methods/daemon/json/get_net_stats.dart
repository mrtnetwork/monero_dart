import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_net_stats
class DaemonRequestGetNetStats extends MoneroDaemonRequestParam<
    DaemonGetNetStatsResponse, Map<String, dynamic>> {
  const DaemonRequestGetNetStats();

  @override
  String get method => "get_net_stats";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetNetStatsResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetNetStatsResponse.fromJson(result);
  }
}
