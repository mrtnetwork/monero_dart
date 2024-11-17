import 'package:monero_dart/src/provider/core/core.dart';

/// Create a new wallet. You need to have set the argument "--wallet-dir" when launching monero-wallet-rpc to make this work.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#create_wallet
class WalletRequestCreateWallet
    extends MoneroWalletRequestParam<Null, Map<String, dynamic>> {
  WalletRequestCreateWallet(
      {required this.fileName, this.password, required this.language});

  /// Wallet file name.
  final String fileName;

  /// password to protect the wallet.
  final String? password;

  /// Language for your wallets' seed.
  final String language;

  @override
  String get method => "create_wallet";
  @override
  Map<String, dynamic> get params =>
      {"filename": fileName, "password": password, "language": language};

  @override
  Null onResonse(Map<String, dynamic> result) {
    return null;
  }
}
