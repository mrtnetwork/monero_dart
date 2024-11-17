import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Set the log hash rate display mode.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_log_hash_rate
class DaemonRequestSetLogHashRate
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestSetLogHashRate(this.visible);
  final bool visible;

  @override
  String get method => "set_log_hash_rate";
  @override
  Map<String, dynamic> get params => {"visible": visible};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
