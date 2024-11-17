import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Show information about a transfer to/from this address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_transfer_by_txid
class WalletRequestGetTransferByTxID
    extends MoneroWalletRequestParam<WalletRPCTransferByTxIdResponse, Map<String, dynamic>> {
  WalletRequestGetTransferByTxID({required this.txId, this.accountIndex});

  /// transaction id.
  final String txId;

  /// Index of the account to query for the transfer.
  final int? accountIndex;
  @override
  String get method => "get_transfer_by_txid";
  @override
  Map<String, dynamic> get params =>
      {"txid": txId, "account_index": accountIndex};

  @override
  WalletRPCTransferByTxIdResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCTransferByTxIdResponse.fromJson(result);
  }
}
