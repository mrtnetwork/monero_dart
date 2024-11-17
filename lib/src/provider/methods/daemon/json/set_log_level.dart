import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Set the daemon log level. By default, log level is set to 0.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_log_level
class DaemonRequestSetLogLevel
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestSetLogLevel(this.level);
  final int level;

  @override
  String get method => "set_log_level";
  @override
  Map<String, dynamic> get params => {"level": level};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
