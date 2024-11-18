import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Make an integrated address from the wallet address and a payment id.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#make_integrated_address
class WalletRequestMakeIntegratedAddress extends MoneroWalletRequestParam<
    WalletRPCMakeIntegratedAddressResponse, Map<String, dynamic>> {
  const WalletRequestMakeIntegratedAddress(
      {this.standardAddress, this.paymentId});

  /// Destination public address.
  final MoneroAddress? standardAddress;

  /// 16 characters hex encoded.
  final String? paymentId;

  @override
  String get method => "make_integrated_address";
  @override
  Map<String, dynamic> get params =>
      {"standard_address": standardAddress?.address, "payment_id": paymentId};
  @override
  WalletRPCMakeIntegratedAddressResponse onResonse(
      Map<String, dynamic> result) {
    return WalletRPCMakeIntegratedAddressResponse.fromJson(result);
  }
}
