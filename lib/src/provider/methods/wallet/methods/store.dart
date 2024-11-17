import 'package:monero_dart/src/provider/core/core.dart';

/// Save the wallet file.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#store
class WalletRequestStore
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestStore();
  @override
  String get method => "store";
  @override
  Map<String, dynamic> get params => {};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
