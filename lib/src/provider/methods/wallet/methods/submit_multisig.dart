import 'package:monero_dart/src/provider/core/core.dart';

/// Submit a signed multisig transaction.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#submit_multisig
class WalletRequestSubmitMultisig
    extends MoneroWalletRequestParam<List<String>, Map<String, dynamic>> {
  const WalletRequestSubmitMultisig(this.txDataHex);

  /// Multisig transaction in hex format, as returned by sign_multisig under tx_data_hex.
  final String txDataHex;
  @override
  String get method => "submit_multisig";
  @override
  Map<String, dynamic> get params => {"tx_data_hex": txDataHex};

  @override
  List<String> onResonse(Map<String, dynamic> result) {
    return (result["tx_hash_list"] as List).cast();
  }
}
