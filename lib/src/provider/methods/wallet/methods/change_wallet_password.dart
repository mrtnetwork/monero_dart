import 'package:monero_dart/src/provider/core/core.dart';

/// Change a wallet password.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#change_wallet_password
class WalletRequestChangeWalletPassword
    extends MoneroWalletRequestParam<Null, Map<String, dynamic>> {
  WalletRequestChangeWalletPassword({this.oldPassword, this.newPassword});

  /// Current wallet password, if defined.
  final String? oldPassword;

  /// New wallet password, if not blank.
  final String? newPassword;

  @override
  String get method => "change_wallet_password";
  @override
  Map<String, dynamic> get params => {
    "old_password": oldPassword,
    "new_password": newPassword,
  };

  @override
  Null onResonse(Map<String, dynamic> result) {
    return null;
  }
}
