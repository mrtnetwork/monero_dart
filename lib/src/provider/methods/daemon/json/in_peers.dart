import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Limit number of Incoming peers.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#in_peers
class DaemonRequestInPeers extends MoneroDaemonRequestParam<
    DaemonInPeersResponse, Map<String, dynamic>> {
  const DaemonRequestInPeers({this.set = true, required this.inPeers});
  final bool set;

  /// Max number of incoming peers
  final int inPeers;
  @override
  String get method => "in_peers";
  @override
  Map<String, dynamic> get params => {"in_peers": inPeers, "set": set};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonInPeersResponse onResonse(Map<String, dynamic> result) {
    return DaemonInPeersResponse.fromJson(result);
  }
}
