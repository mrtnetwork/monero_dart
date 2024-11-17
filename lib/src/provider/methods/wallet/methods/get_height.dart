import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Returns the wallet's current block height.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_height
class WalletRequestGetHeight
    extends MoneroWalletRequestParam<BigInt, Map<String, dynamic>> {
  WalletRequestGetHeight();

  @override
  String get method => "get_height";
  @override
  Map<String, dynamic> get params => {};

  @override
  BigInt onResonse(Map<String, dynamic> result) {
    return BigintUtils.parse(result["height"]);
  }
}
