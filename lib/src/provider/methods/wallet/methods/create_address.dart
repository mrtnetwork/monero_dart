import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Create a new address for an account. Optionally, label the new address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#create_address
class WalletRequestCreateAddress extends MoneroWalletRequestParam<
    WalletRPCCreateAddressResponse, Map<String, dynamic>> {
  WalletRequestCreateAddress(
      {required this.accountIndex, this.label, this.count});

  /// Label for the new address.
  final String? label;

  /// Create a new address for this account.
  final int accountIndex;

  /// Number of addresses to create (Defaults to 1).
  final int? count;

  @override
  String get method => "create_address";
  @override
  Map<String, dynamic> get params =>
      {"label": label, "account_index": accountIndex, "count": count};

  @override
  WalletRPCCreateAddressResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCCreateAddressResponse.fromJson(result);
  }
}
