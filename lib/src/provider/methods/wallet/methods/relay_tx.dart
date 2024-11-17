import 'package:monero_dart/src/provider/core/core.dart';

/// Relay a transaction previously created with "do_not_relay":true.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#relay_tx
class WalletRequestRelayTx
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestRelayTx(this.hex);

  /// transaction metadata returned from a transfer method with get_tx_metadata set to true.
  final String hex;
  @override
  String get method => "relay_tx";
  @override
  Map<String, dynamic> get params => {"hex": hex};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["tx_hash"];
  }
}
