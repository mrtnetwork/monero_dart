import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Sign a transaction created on a read-only wallet (in cold-signing process)
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#sign_transfer
class WalletRequestSignTransfer
    extends
        MoneroWalletRequestParam<
          WalletRPCSignTransferResponse,
          Map<String, dynamic>
        > {
  WalletRequestSignTransfer({
    required this.unsignedTxSet,
    this.exportRaw,
    this.getTxKey,
  });

  /// Set of unsigned tx returned by "transfer" or "transfer_split" methods.
  final String unsignedTxSet;

  /// If true, return the raw transaction data. (Defaults to false)
  final bool? exportRaw;

  /// Return the transaction keys after signing.
  final bool? getTxKey;

  @override
  String get method => "sign_transfer";
  @override
  Map<String, dynamic> get params => {
    "unsigned_txset": unsignedTxSet,
    "export_raw": exportRaw,
    "get_tx_keys": getTxKey,
  };

  @override
  WalletRPCSignTransferResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSignTransferResponse.fromJson(result);
  }
}
