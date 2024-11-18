import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get hashes from transaction pool.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_transaction_pool_hashes
class DaemonRequestGetTransactionPoolHashes extends MoneroDaemonRequestParam<
    DaemonGetTransactionPoolHashesResponse, Map<String, dynamic>> {
  const DaemonRequestGetTransactionPoolHashes();

  @override
  String get method => "get_transaction_pool_hashes";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonGetTransactionPoolHashesResponse onResonse(
      Map<String, dynamic> result) {
    return DaemonGetTransactionPoolHashesResponse.fromJson(result);
  }
}
