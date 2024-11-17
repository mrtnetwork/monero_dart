import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Look up how many blocks are in the longest chain known to the node.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_block_count
class DaemonRequestGetBlockCount extends MoneroDaemonRequestParam<
    DaemonGetBlockCountResponse, Map<String, dynamic>> {
  DaemonRequestGetBlockCount();

  @override
  String get method => "get_block_count";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;
  @override
  DaemonGetBlockCountResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetBlockCountResponse.fromJson(result);
  }
}
