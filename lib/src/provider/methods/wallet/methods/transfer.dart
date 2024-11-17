import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Send monero to a number of recipients.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#transfer
class WalletRequestTransfer
    extends MoneroWalletRequestParam<WalletRPCTransferMoneroResponse, Map<String, dynamic>> {
  WalletRequestTransfer(
      {required this.destinations,
      required this.accountIndex,
      this.subaddrIndices,
      this.subtractFeeFromOutputs,
      this.priority,
      required this.mixin,
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

  /// Choose which destinations to fund the tx fee from instead of the change output.
  /// The fee will be subtracted evenly from each destination (regardless of amount).
  /// Do not use this if recipient requires an exact amount.
  final List<int>? subtractFeeFromOutputs;

  /// Priority for sending the sweep transfer, partially determines fee.
  final int? priority;

  /// Number of outputs from the blockchain to mix with (0 means no mixing).
  final int mixin;

  /// Number of outputs to mix in the transaction (this output + N decoys from the blockchain).
  /// (Unless dealing with pre rct outputs, this field is ignored on mainnet).
  final int ringSize;

  /// Number of blocks before the monero can be spent (0 to not add a lock).
  final int unlockTime;

  /// Return the transaction keys after sending.
  final bool? getTxKeys;

  /// If true, the newly created transaction will not be relayed to the monero network. (Defaults to false)
  final bool? doNotRelay;

  /// Return the transaction as hex string after sending (Defaults to false)
  final bool? getTxHex;

  /// Return the metadata needed to relay the transaction. (Defaults to false)
  final bool? getTxMetadata;
  @override
  String get method => "transfer";
  @override
  Map<String, dynamic> get params => {
        "destinations": destinations.map((e) => e.toJson()).toList(),
        "account_index": accountIndex,
        "subaddr_indices": subaddrIndices,
        "subtract_fee_from_outputs": subtractFeeFromOutputs,
        "priority": priority,
        "mixin": mixin,
        "ring_size": ringSize,
        "unlock_time": unlockTime,
        "get_tx_keys": getTxKeys,
        "do_not_relay": doNotRelay,
        "get_tx_hex": getTxHex,
        "get_tx_metadata": getTxMetadata,
      };

  @override
  WalletRPCTransferMoneroResponse onResonse(Map<String, dynamic> result) {
    print("result $result");
    return WalletRPCTransferMoneroResponse.fromJson(result);
  }
}
