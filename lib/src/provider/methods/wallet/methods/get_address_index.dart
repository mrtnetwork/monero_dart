import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Get account and address indexes from a specific (sub)address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_address_index
class WalletRequestGetAddressIndex
    extends MoneroWalletRequestParam<WalletRPCSubAddressIndexResponse, Map<String, dynamic>> {
  WalletRequestGetAddressIndex(this.address);

  /// (sub)address to look for.
  final MoneroAddress address;

  @override
  String get method => "get_address_index";
  @override
  Map<String, dynamic> get params => {"address": address.address};

  @override
  WalletRPCSubAddressIndexResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSubAddressIndexResponse.fromJson(result["index"]);
  }
}
