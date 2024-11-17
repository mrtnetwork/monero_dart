import 'package:monero_dart/src/provider/core/core.dart';

/// Store the current state of any open wallet and exit the monero-wallet-rpc process.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#stop_wallet
class WalletRequestStopWallet
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestStopWallet();
  @override
  String get method => "stop_wallet";
  @override
  Map<String, dynamic> get params => {};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
