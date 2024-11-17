import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Label an address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#label_address
class WalletRequestLabelAddress
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestLabelAddress({required this.index, required this.label});

  final WalletRPCSubAddressIndexResponse index;

  /// Label for the address.
  final String label;
  @override
  String get method => "label_address";
  @override
  Map<String, dynamic> get params => {"index": index.toJson(), "label": label};
  @override
  void onResonse(Map<String, dynamic> result) {}
}
