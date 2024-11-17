import 'package:monero_dart/src/provider/core/core.dart';

/// Apply a filtering tag to a list of accounts.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#tag_accounts
class WalletRequestTagAccounts
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestTagAccounts({required this.tag, required this.accounts});

  /// Tag for the accounts.
  final String tag;

  /// Tag this list of accounts.
  final List<int> accounts;

  @override
  String get method => "tag_accounts";
  @override
  Map<String, dynamic> get params => {"tag": tag, "accounts": accounts};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
