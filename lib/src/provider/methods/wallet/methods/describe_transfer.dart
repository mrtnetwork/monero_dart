import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Returns details for each transaction in an unsigned or multisig transaction set.
/// Transaction sets are obtained as return values from one of the following RPC methods:
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#describe_transfer
class WalletRequestDescribeTransfer extends MoneroWalletRequestParam<
    WalletRPCDescribeTransferResponse, Map<String, dynamic>> {
  WalletRequestDescribeTransfer({this.unsignedTxSet, this.multisigTxSet});

  /// A hexadecimal string representing a set of unsigned transactions
  /// (empty for multisig transactions; non-multisig signed transactions are not supported).
  final String? unsignedTxSet;

  /// A hexadecimal string representing the set of signing keys used in
  /// a multisig transaction (empty for unsigned transactions; non-multisig signed transactions are not supported).
  final String? multisigTxSet;

  @override
  String get method => "describe_transfer";
  @override
  Map<String, dynamic> get params =>
      {"unsigned_txset": unsignedTxSet, "multisig_txset": multisigTxSet};

  @override
  WalletRPCDescribeTransferResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCDescribeTransferResponse.fromJson(result);
  }
}
