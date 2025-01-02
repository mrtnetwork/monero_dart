import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Update daemon.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#update
class DaemonRequestUpdate extends MoneroDaemonRequestParam<DaemonUpdateResponse,
    Map<String, dynamic>> {
  const DaemonRequestUpdate({required this.command, required this.path});
  final String command;
  final String path;
  @override
  String get method => "update";
  @override
  Map<String, dynamic> get params => {"command": command, "path": path};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonUpdateResponse onResonse(Map<String, dynamic> result) {
    return DaemonUpdateResponse.fromJson(result);
  }
}
