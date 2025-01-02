import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Flush tx ids from transaction pool.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#flush_txpool
class DaemonRequestFlushTxPool
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  DaemonRequestFlushTxPool({List<String> txids = const []})
      : txids = txids.immutable;

  /// list of transactions IDs to flush from pool (all tx ids flushed if empty).
  final List<String> txids;
  @override
  String get method => "flush_txpool";
  @override
  Map<String, dynamic> get params => {"txids": txids};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
