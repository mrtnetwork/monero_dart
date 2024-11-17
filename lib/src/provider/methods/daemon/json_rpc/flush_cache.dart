import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Flush bad transactions / blocks from the cache.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#flush_cache
class DaemonRequestFlushCache
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  DaemonRequestFlushCache({this.badBlocks = false, this.badTxs = false});

  final bool badTxs;
  final bool badBlocks;

  @override
  String get method => "flush_cache";
  @override
  Map<String, dynamic> get params =>
      {"bad_txs": badTxs, "bad_blocks": badBlocks};
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;
  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
