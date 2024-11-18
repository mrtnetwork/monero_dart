import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Remove filtering tag from a list of accounts.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#untag_accounts
class WalletRequestUntagAccounts extends MoneroWalletRequestParam<
    WalletRPCSweepResponse, Map<String, dynamic>> {
  WalletRequestUntagAccounts({required this.accounts});

  /// Remove tag from this list of accounts.
  final List<int> accounts;

  @override
  String get method => "untag_accounts";
  @override
  Map<String, dynamic> get params => {"accounts": accounts};

  @override
  WalletRPCSweepResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSweepResponse.fromJson(result);
  }
}
