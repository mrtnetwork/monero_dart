import 'package:monero_dart/src/provider/core/core.dart';

/// Close the currently opened wallet, after trying to save it
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#close_wallet
class WalletRequestCloseWallet
    extends MoneroWalletRequestParam<Null, Map<String, dynamic>> {
  WalletRequestCloseWallet();

  @override
  String get method => "close_wallet";
  @override
  Map<String, dynamic> get params => {};

  @override
  Null onResonse(Map<String, dynamic> result) {
    return null;
  }
}
