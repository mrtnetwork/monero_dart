import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Get all accounts for a wallet. Optionally filter accounts by tag.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_accounts
class WalletRequestGetAccounts extends MoneroWalletRequestParam<
    WalletRPCGetAccountsResponse, Map<String, dynamic>> {
  WalletRequestGetAccounts({this.tag, this.regex, this.strictBalances});

  /// Tag for filtering accounts.
  final String? tag;

  /// allow regular expression filters if set to true (Defaults to false).
  final bool? regex;

  /// when true, balance only considers the blockchain,
  /// when false it considers both the blockchain and some recent actions,
  /// such as a recently created transaction which
  final bool? strictBalances;

  @override
  String get method => "get_accounts";
  @override
  Map<String, dynamic> get params =>
      {"tag": tag, "regex": regex, "strict_balances": strictBalances};

  @override
  WalletRPCGetAccountsResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGetAccountsResponse.fromJson(result);
  }
}
