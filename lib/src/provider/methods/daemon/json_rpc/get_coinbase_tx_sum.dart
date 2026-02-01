import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Get the coinbase amount and the fees amount for n last blocks starting at particular height
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_coinbase_tx_sum
class DaemonRequestGetCoinbaseTxSum
    extends
        MoneroDaemonRequestParam<
          DaemonCoinbaseTxSumResponse,
          Map<String, dynamic>
        > {
  DaemonRequestGetCoinbaseTxSum({required this.height, required this.count});

  /// Block height from which getting the amounts
  final BigInt height;

  /// number of blocks to include in the sum
  final BigInt count;
  @override
  String get method => "get_coinbase_tx_sum";
  @override
  Map<String, dynamic> get params => {
    "height": height.toString(),
    "count": count.toString(),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonCoinbaseTxSumResponse onResonse(Map<String, dynamic> result) {
    return DaemonCoinbaseTxSumResponse.fromJson(result);
  }
}
