import 'package:monero_dart/src/provider/core/core.dart';

/// Stop mining in the Monero daemon.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#stop_mining
class WalletRequestStopMining
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestStopMining();
  @override
  String get method => "stop_mining";
  @override
  Map<String, dynamic> get params => {};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
