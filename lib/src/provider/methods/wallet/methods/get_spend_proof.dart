import 'package:monero_dart/src/provider/core/core.dart';

/// Generate a signature to prove a spend. Unlike proving a transaction,
/// it does not requires the destination public address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_spend_proof
class WalletRequestGetSpendProof
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestGetSpendProof({required this.txId, this.message});

  /// transaction id.
  final String txId;

  /// add a message to the signature to further authenticate the prooving process.
  final String? message;
  @override
  String get method => "get_spend_proof";
  @override
  Map<String, dynamic> get params => {"txid": txId, "message": message};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["signature"];
  }
}
