import 'package:monero_dart/src/provider/core/core.dart';

/// Open a wallet. You need to have set the argument "--wallet-dir" when launching monero-wallet-rpc to make this work.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#open_wallet
class WalletRequestOpenWallet
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestOpenWallet({required this.fileName, this.password});

  /// wallet name stored in --wallet-dir.
  final String fileName;

  /// only needed if the wallet has a password defined.
  final String? password;
  @override
  String get method => "open_wallet";
  @override
  Map<String, dynamic> get params => {
    "filename": fileName,
    "password ": password,
  };
  @override
  void onResonse(Map<String, dynamic> result) {}
}
