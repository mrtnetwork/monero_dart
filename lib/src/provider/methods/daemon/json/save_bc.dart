import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Save the blockchain. The blockchain does not need saving and is always saved when modified,
/// however it does a sync to flush the filesystem cache onto the disk for safety purposes against
/// Operating System or Hardware crashes.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#save_bc
class DaemonRequestStartSaveBc
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStartSaveBc();

  @override
  String get method => "save_bc";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
