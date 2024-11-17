import 'package:monero_dart/src/provider/core/core.dart';

/// Get transaction secret key from transaction id.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_tx_key
class WalletRequestGetTxKey
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestGetTxKey(this.txId);

  ///  transaction id.
  final String txId;
  @override
  String get method => "get_tx_key";
  @override
  Map<String, dynamic> get params => {"txid": txId};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["tx_key"];
  }
}
