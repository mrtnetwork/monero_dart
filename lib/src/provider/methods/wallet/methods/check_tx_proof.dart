import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Prove a transaction by checking its signature.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#check_tx_proof
class WalletRequestCheckTxProof extends MoneroWalletRequestParam<
    WalletRPCCheckTxProofResponse, Map<String, dynamic>> {
  WalletRequestCheckTxProof(
      {required this.txId,
      required this.message,
      required this.address,
      required this.signature});

  ///  transaction id.
  final String txId;

  /// Should be the same message used in get_tx_proof.
  final String? message;

  /// destination public address of the transaction.
  final MoneroAddress address;

  /// transaction signature to confirm.
  final String signature;

  @override
  String get method => "check_tx_proof";
  @override
  Map<String, dynamic> get params => {
        "txid": txId,
        "message": message,
        "address": address.address,
        "signature": signature
      };

  @override
  WalletRPCCheckTxProofResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCCheckTxProofResponse.fromJson(result);
  }
}
