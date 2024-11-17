import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Get RPC version Major & Minor integer-format, where Major is the first 16 bits and Minor the last 16 bits.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_version
class WalletRequestGetVersion
    extends MoneroWalletRequestParam<int, Map<String, dynamic>> {
  WalletRequestGetVersion();

  @override
  String get method => "get_version";
  @override
  Map<String, dynamic> get params => {};

  @override
  int onResonse(Map<String, dynamic> result) {
    return IntUtils.parse(result["version"]);
  }
}
