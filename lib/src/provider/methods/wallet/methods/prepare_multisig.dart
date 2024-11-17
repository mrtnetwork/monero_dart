import 'package:monero_dart/src/provider/core/core.dart';

/// Prepare a wallet for multisig by generating a multisig string to share with peers.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#prepare_multisig
class WalletRequestPrepareMultisig
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestPrepareMultisig();

  @override
  String get method => "prepare_multisig";
  @override
  Map<String, dynamic> get params => {};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["multisig_info"];
  }
}
