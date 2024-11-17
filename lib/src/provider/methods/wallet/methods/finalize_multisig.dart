import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Turn this wallet into a multisig wallet, extra step for N-1/N wallets.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#finalize_multisig
class WalletRequestFinalizeMultisig
    extends MoneroWalletRequestParam<MoneroAddress, Map<String, dynamic>> {
  WalletRequestFinalizeMultisig(
      {required this.multisigInfo, required this.password});

  /// If true, export all outputs. Otherwise, export outputs since the last export.
  final List<String> multisigInfo;

  /// Wallet password
  final String password;
  @override
  String get method => "finalize_multisig";
  @override
  Map<String, dynamic> get params =>
      {"multisig_info": multisigInfo, "password": password};

  /// multisig wallet address.
  @override
  MoneroAddress onResonse(Map<String, dynamic> result) {
    return MoneroAddress(result["address"]);
  }
}
