import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Same as transfer, but can split into more than one tx if necessary.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#transfer_split
class WalletRequestTransferSplit extends MoneroWalletRequestParam<
    WalletRPCSweepResponse, Map<String, dynamic>> {
  WalletRequestTransferSplit(
      {required this.destinations,
      this.accountIndex,
      this.subaddrIndices,
      this.priority,
       this.paymentId,
      required this.ringSize,
      required this.unlockTime,
      this.getTxKeys,
      this.doNotRelay,
      this.getTxHex,
      this.getTxMetadata});

  /// Destination public address.
  final List<WalletRPCTransferDestinationParam> destinations;

  /// Transfer from this account index. (Defaults to 0)
  final int? accountIndex;

  /// Transfer from this set of subaddresses. (Defaults to empty - all indices)
  final List<int>? subaddrIndices;

  /// Priority for sending the sweep transfer, partially determines fee.
  final int? priority;

  /// Number of outputs to mix in the transaction (this output + N decoys from the blockchain).
  /// (Unless dealing with pre rct outputs, this field is ignored on mainnet).
  final int ringSize;

  /// Number of blocks before the monero can be spent (0 to not add a lock).
  final int unlockTime;

  /// 16 characters hex encoded.
  final String? paymentId;

  /// Return the transaction keys after sending.
  final bool? getTxKeys;

  /// If true, the newly created transaction will not be relayed to the monero network. (Defaults to false)
  final bool? doNotRelay;

  /// Return the transaction as hex string after sending (Defaults to false)
  final bool? getTxHex;

  /// Return the metadata needed to relay the transaction. (Defaults to false)
  final bool? getTxMetadata;
  @override
  String get method => "transfer_split";
  @override
  Map<String, dynamic> get params => {
        "destinations": destinations.map((e) => e.toJson()).toList(),
        "account_index": accountIndex,
        "subaddr_indices": subaddrIndices,
        "payment_id": paymentId,
        "priority": priority,
        "ring_size": ringSize,
        "unlock_time": unlockTime,
        "get_tx_keys": getTxKeys,
        "do_not_relay": doNotRelay,
        "get_tx_hex": getTxHex,
        "get_tx_metadata": getTxMetadata,
      };

  @override
  WalletRPCSweepResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSweepResponse.fromJson(result);
  }
}
