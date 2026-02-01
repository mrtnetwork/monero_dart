import 'package:monero_dart/src/provider/core/core.dart';

/// Set whether and how often to automatically refresh the current wallet.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#auto_refresh
class WalletRequestAutoRefresh
    extends MoneroWalletRequestParam<Null, Map<String, dynamic>> {
  WalletRequestAutoRefresh({this.enable, this.period});

  /// Enable or disable automatic refreshing (default = true)
  final bool? enable;

  /// The period of the wallet refresh cycle (i.e. time between refreshes) in seconds
  final int? period;

  @override
  String get method => "auto_refresh";
  @override
  Map<String, dynamic> get params => {
    "enable": enable ?? true,
    "period": period,
  };

  @override
  Null onResonse(Map<String, dynamic> result) {
    return null;
  }
}
