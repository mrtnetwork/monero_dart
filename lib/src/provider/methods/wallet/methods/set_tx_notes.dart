import 'package:monero_dart/src/provider/core/core.dart';

/// Set arbitrary string notes for transactions.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#set_tx_notes
class WalletRequestSetTxNotes
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestSetTxNotes({required this.txIds, required this.notes});

  /// transaction ids
  final List<String> txIds;

  /// notes for the transactions
  final List<String> notes;

  @override
  String get method => "set_tx_notes";
  @override
  Map<String, dynamic> get params => {"txids": txIds, "notes": notes};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
