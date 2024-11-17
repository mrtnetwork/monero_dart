import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Sign a transaction in multisig.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#sign_multisig
class WalletRequestSignMultisig extends MoneroWalletRequestParam<
    WalletRPCSignMultisigResponse, Map<String, dynamic>> {
  WalletRequestSignMultisig(this.txDataHex);

  /// Multisig transaction in hex format, as returned by transfer under multisig_txset.
  final String txDataHex;

  @override
  String get method => "sign_multisig";
  @override
  Map<String, dynamic> get params => {"tx_data_hex": txDataHex};

  @override
  WalletRPCSignMultisigResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSignMultisigResponse.fromJson(result);
  }
}
