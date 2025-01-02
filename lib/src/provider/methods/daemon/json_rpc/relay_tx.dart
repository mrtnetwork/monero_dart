import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Relay a list of transaction IDs.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#relay_tx
class DaemonRequestRelayTx
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  DaemonRequestRelayTx(List<String> txids) : txids = txids.toImutableList;
  final List<String> txids;
  @override
  String get method => "relay_tx";
  @override
  Map<String, dynamic> get params => {"txids": txids};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
