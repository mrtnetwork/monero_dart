import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#prune_blockchain
class DaemonRequestPruneBlockchain extends MoneroDaemonRequestParam<
    DaemonPruneBlockchainResponse, Map<String, dynamic>> {
  DaemonRequestPruneBlockchain({this.check = false});

  /// If set to true then pruning
  /// status is checked instead of initiating pruning.
  final bool check;
  @override
  String get method => "prune_blockchain";

  @override
  Map<String, dynamic> get params => {"check": check};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonPruneBlockchainResponse onResonse(Map<String, dynamic> result) {
    return DaemonPruneBlockchainResponse.fromJson(result);
  }
}
