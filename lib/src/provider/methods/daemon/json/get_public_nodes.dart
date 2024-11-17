import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get public peer information.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_public_nodes
class DaemonRequestGetPublicNodes extends MoneroDaemonRequestParam<
    DaemonGetPublicNodeResponse, Map<String, dynamic>> {
  const DaemonRequestGetPublicNodes(
      {this.gray = false, this.white = true, this.includeBlocked = false});

  /// Include gray peers.
  final bool gray;

  /// Include white peers.
  final bool white;

  /// Include blocked peers.
  final bool includeBlocked;
  @override
  String get method => "get_public_nodes";
  @override
  Map<String, dynamic> get params =>
      {"gray": gray, "white": white, "include_blocked": includeBlocked};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetPublicNodeResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetPublicNodeResponse.fromJson(result);
  }
}
