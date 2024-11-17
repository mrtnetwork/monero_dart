import 'package:monero_dart/src/provider/core/core.dart';

/// Prove a spend using a signature. Unlike proving a transaction, it does not requires the destination public address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#check_spend_proof
class WalletRequestCheckSpendProof
    extends MoneroWalletRequestParam<bool, Map<String, dynamic>> {
  WalletRequestCheckSpendProof(
      {required this.txId, this.message, required this.signature});

  ///  transaction id.
  final String txId;

  /// Should be the same message used in get_spend_proof.
  final String? message;

  /// spend signature to confirm.
  final String signature;

  @override
  String get method => "check_spend_proof";
  @override
  Map<String, dynamic> get params =>
      {"txid": txId, "message": message, "signature": signature};

  /// States if the inputs proves the spend.
  @override
  bool onResonse(Map<String, dynamic> result) {
    return result["good"];
  }
}
