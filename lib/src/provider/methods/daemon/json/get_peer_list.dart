import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the known peers list.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_peer_list
class DaemonRequestGetPeerList extends MoneroDaemonRequestParam<
    DaemonGetPeerListResponse, Map<String, dynamic>> {
  const DaemonRequestGetPeerList(
      {this.includeBlock = false, this.publicOnly = true});
  final bool publicOnly;
  final bool includeBlock;

  @override
  String get method => "get_peer_list";
  @override
  Map<String, dynamic> get params =>
      {"public_only": publicOnly, "include_blocked": includeBlock};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetPeerListResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetPeerListResponse.fromJson(result);
  }
}
