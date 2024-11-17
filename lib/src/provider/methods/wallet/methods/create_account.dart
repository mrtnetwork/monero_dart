import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Create a new account with an optional label.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#create_account
class WalletRequestCreateAccount extends MoneroWalletRequestParam<
    WalletRPCCreateAccountResponse, Map<String, dynamic>> {
  WalletRequestCreateAccount({this.label});

  final String? label;

  @override
  String get method => "create_account";
  @override
  Map<String, dynamic> get params => {"label": label};

  @override
  WalletRPCCreateAccountResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCCreateAccountResponse.fromJson(result);
  }
}
