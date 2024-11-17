import 'package:monero_dart/src/provider/core/core.dart';

/// Get string notes for transactions.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_tx_notes
class WalletRequestGetTxNotes
    extends MoneroWalletRequestParam<List<String>, Map<String, dynamic>> {
  WalletRequestGetTxNotes(this.txIds);

  /// transaction ids.
  final List<String> txIds;
  @override
  String get method => "get_tx_notes";
  @override
  Map<String, dynamic> get params => {"txids": txIds};

  @override
  List<String> onResonse(Map<String, dynamic> result) {
    return (result["notes"] as List).cast();
  }
}
