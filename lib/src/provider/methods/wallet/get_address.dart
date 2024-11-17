import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Return the wallet's addresses for an account. 
/// Optionally filter for specific set of subaddresses.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_address
class WalletRequestGetAddress extends MoneroWalletRequestParam<
    WalletRPCGetAddressResponse, Map<String, dynamic>> {
  WalletRequestGetAddress({required this.accountIndex, this.addressIndex});

  /// Return the addresses for this account.
  final int accountIndex;

  /// List of address indices to return for the account. Index 0 of account 0 is the primary address, all others are subaddresses.
  final List<int>? addressIndex;

  @override
  String get method => "get_address";
  @override
  Map<String, dynamic> get params =>
      {"account_index": accountIndex, "address_index": addressIndex};

  @override
  WalletRPCGetAddressResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGetAddressResponse.fromJson(result);
  }
}
