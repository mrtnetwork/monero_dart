import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Retrieve the standard address and payment id corresponding to an integrated address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#split_integrated_address
class WalletRequestSplitIntegratedAddress extends MoneroWalletRequestParam<
    WalletRPCSplitIntegratedAddressResponse, Map<String, dynamic>> {
  WalletRequestSplitIntegratedAddress(this.integratedAddress);

  /// Set of unsigned tx returned by "transfer" or "transfer_split" methods.
  final String integratedAddress;

  @override
  String get method => "split_integrated_address";
  @override
  Map<String, dynamic> get params => {"integrated_address": integratedAddress};

  @override
  WalletRPCSplitIntegratedAddressResponse onResonse(
      Map<String, dynamic> result) {
    return WalletRPCSplitIntegratedAddressResponse.fromJson(result);
  }
}
