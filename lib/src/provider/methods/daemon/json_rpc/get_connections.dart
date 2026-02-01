import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Retrieve information about incoming and outgoing connections to your node.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_connections
class DaemonRequestGetConnections
    extends
        MoneroDaemonRequestParam<
          DaemonGetConnectionsResponse,
          Map<String, dynamic>
        > {
  const DaemonRequestGetConnections();

  @override
  String get method => "get_connections";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetConnectionsResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetConnectionsResponse.fromJson(result);
  }
}
