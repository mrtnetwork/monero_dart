import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/methods/wallet/methods/get_out_response.dart';

/// Get outputs.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_outs
class DaemonRequestGetTransactionPoolHashesBin
    extends MoneroDaemonRequestParam<GetOutResponse, Map<String, dynamic>> {
  DaemonRequestGetTransactionPoolHashesBin();

  @override
  String get method => "get_transaction_pool_hashes.bin";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  GetOutResponse onResonse(Map<String, dynamic> result) {
    return GetOutResponse.fromJson(result);
  }
}
