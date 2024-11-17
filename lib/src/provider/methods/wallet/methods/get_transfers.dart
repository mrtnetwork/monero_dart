import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Returns a list of transfers.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_transfers
class WalletRequestGetTransfers extends MoneroWalletRequestParam<
    WalletRPCGetTransfersResponse, Map<String, dynamic>> {
  WalletRequestGetTransfers(
      {this.inTransfers = true,
      this.outTransfers = false,
      this.pendingTransfers = true,
      this.poolTransfers = true,
      this.failedTransfers = false,
      this.filterByHeight,
      this.mintHeight,
      this.maxHeight,
      this.accountIndex,
      this.subaddrIndices,
      this.allAccount});

  final bool inTransfers;
  final bool outTransfers;
  final bool pendingTransfers;
  final bool poolTransfers;
  final bool failedTransfers;
  final bool? filterByHeight;
  final BigInt? mintHeight;
  final BigInt? maxHeight;
  final int? accountIndex;
  final List<int>? subaddrIndices;
  final bool? allAccount;
  @override
  String get method => "get_transfers";
  @override
  Map<String, dynamic> get params => {
        "in": inTransfers,
        "out": outTransfers,
        "pending": pendingTransfers,
        "failed": failedTransfers,
        "pool": poolTransfers,
        "filter_by_height": filterByHeight?.toString(),
        "min_height": mintHeight?.toString(),
        "max_height": maxHeight?.toString(),
        "account_index": accountIndex,
        "subaddr_indices": subaddrIndices,
        "all_accounts": allAccount
      };

  @override
  WalletRPCGetTransfersResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGetTransfersResponse.fromJson(result);
  }
}
