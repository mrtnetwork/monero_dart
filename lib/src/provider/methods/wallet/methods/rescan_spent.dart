import 'package:monero_dart/src/provider/core/core.dart';

/// Rescan the blockchain for spent outputs.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#rescan_spent
class WalletRequestRescanSpent
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  @override
  String get method => "rescan_spent";
  @override
  Map<String, dynamic> get params => {};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
