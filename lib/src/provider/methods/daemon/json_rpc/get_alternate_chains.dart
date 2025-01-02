import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Display alternative chains seen by the node.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_alternate_chains
class DaemonRequestGetAlternateChains extends MoneroDaemonRequestParam<
    DaemonGetAlternateChainsResponse, Map<String, dynamic>> {
  const DaemonRequestGetAlternateChains();
  @override
  String get method => "get_alternate_chains";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetAlternateChainsResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetAlternateChainsResponse.fromJson(result);
  }
}
