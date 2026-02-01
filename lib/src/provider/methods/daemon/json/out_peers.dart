import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Limit number of Outgoing peers.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#out_peers
class DaemonRequestOutPeers
    extends
        MoneroDaemonRequestParam<DaemonOutPeersResponse, Map<String, dynamic>> {
  const DaemonRequestOutPeers({this.set = true, required this.outPeers});
  final bool set;

  /// Max number of outgoing peers
  final int outPeers;
  @override
  String get method => "out_peers";
  @override
  Map<String, dynamic> get params => {"out_peers": outPeers, "set": set};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonOutPeersResponse onResonse(Map<String, dynamic> result) {
    return DaemonOutPeersResponse.fromJson(result);
  }
}
