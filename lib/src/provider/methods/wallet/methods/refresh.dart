import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Refresh a wallet after openning.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#refresh
class WalletRequestRefresh extends MoneroWalletRequestParam<
    WalletRPCRefreshResponse, Map<String, dynamic>> {
  WalletRequestRefresh({this.startHeight});

  /// The block height from which to start refreshing.
  /// Passing no value or a value less than the last block
  /// scanned by the wallet refreshes from the last block scanned.
  final BigInt? startHeight;
  @override
  String get method => "refresh";
  @override
  Map<String, dynamic> get params => {"start_height": startHeight?.toString()};

  @override
  WalletRPCRefreshResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCRefreshResponse.fromJson(result);
  }
}
