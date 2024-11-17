import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Check if a wallet is a multisig one.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#is_multisig
class WalletRequestIsMultisig
    extends MoneroWalletRequestParam<WalletRPCIsMultisigResponse, Map<String, dynamic>> {
  const WalletRequestIsMultisig();

  @override
  String get method => "is_multisig";
  @override
  Map<String, dynamic> get params => {};

  @override
  WalletRPCIsMultisigResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCIsMultisigResponse.fromJson(result);
  }
}
