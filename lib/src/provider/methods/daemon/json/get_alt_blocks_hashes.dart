import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the known blocks hashes which are not on the main chain.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_alt_blocks_hashes
class DaemonRequestGetAltBlocksHashes extends MoneroDaemonRequestParam<
    DaemonGetAltBlockHashesResponse, Map<String, dynamic>> {
  const DaemonRequestGetAltBlocksHashes();

  @override
  String get method => "get_alt_blocks_hashes";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetAltBlockHashesResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetAltBlockHashesResponse.fromJson(result);
  }
}
