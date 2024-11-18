import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Return the wallet's balance.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_balance
class WalletRequestGetBalance extends MoneroWalletRequestParam<
    WalletRPCGetBalanceResponse, Map<String, dynamic>> {
  WalletRequestGetBalance(
      {required this.accountIndex,
      this.addressIndices,
      this.allAccounts = false,
      this.strict = false});

  /// Return balance for this account.
  final int accountIndex;

  /// Return balance detail for those subaddresses.
  final List<int>? addressIndices;
  final bool allAccounts;

  /// all changes go to 0-th subaddress (in the current subaddress account)
  final bool strict;
  @override
  String get method => "get_balance";
  @override
  Map<String, dynamic> get params => {
        "account_index": accountIndex,
        "address_indices": addressIndices,
        "all_accounts": allAccounts,
        "strict": strict
      };

  @override
  WalletRPCGetBalanceResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGetBalanceResponse.fromJson(result);
  }
}
