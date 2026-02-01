import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the transaction pool statistics.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_transaction_pool_stats
class DaemonRequestGetTransactionPoolStats
    extends
        MoneroDaemonRequestParam<
          DaemonGetTransactionPoolStatsResponse,
          Map<String, dynamic>
        > {
  const DaemonRequestGetTransactionPoolStats();

  @override
  String get method => "get_transaction_pool_stats";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonGetTransactionPoolStatsResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetTransactionPoolStatsResponse.fromJson(result);
  }
}
