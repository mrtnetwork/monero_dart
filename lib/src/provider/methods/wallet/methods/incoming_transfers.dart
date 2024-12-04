import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Return a list of incoming transfers to the wallet.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#incoming_transfers
class WalletRequestIncommingTransfers extends MoneroWalletRequestParam<
    List<WalletRPCIncommingTransferResponse>, Map<String, dynamic>> {
  const WalletRequestIncommingTransfers(
      {this.transferType = IncommingTransferType.available,
      this.accountIndex,
      this.subaddrIndices});

  /// "all": all the transfers, "available": only transfers which are not yet spent,
  /// OR "unavailable": only transfers which are already spent.
  final IncommingTransferType transferType;

  /// Return transfers for this account. (defaults to 0)
  final int? accountIndex;

  /// Return transfers sent to these subaddresses.
  final List<int>? subaddrIndices;

  @override
  String get method => "incoming_transfers";
  @override
  Map<String, dynamic> get params => {
        "transfer_type": transferType.name,
        "subaddr_indices": subaddrIndices,
        "account_index": accountIndex
      };

  @override
  List<WalletRPCIncommingTransferResponse> onResonse(
      Map<String, dynamic> result) {
    if (result.isEmpty) return [];
    return (result["transfers"] as List)
        .map((e) => WalletRPCIncommingTransferResponse.fromJson(e))
        .toList();
  }
}
