import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Get transaction signature to prove it.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_tx_proof
class WalletRequestGetTxProof
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestGetTxProof({
    required this.txId,
    required this.address,
    this.message,
  });

  /// transaction ids.
  final String txId;

  /// destination public address of the transaction.
  final MoneroAddress address;

  /// add a message to the signature to further authenticate the prooving process.
  final String? message;
  @override
  String get method => "get_tx_proof";
  @override
  Map<String, dynamic> get params => {
    "txid": txId,
    "address": address.address,
    "message": message,
  };

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["signature"];
  }
}
