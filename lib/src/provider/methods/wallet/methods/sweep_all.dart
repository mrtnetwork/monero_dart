import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Send all unlocked balance to an address.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#sweep_all
class WalletRequestSweepAll
    extends
        MoneroWalletRequestParam<WalletRPCSweepResponse, Map<String, dynamic>> {
  WalletRequestSweepAll({
    required this.address,
    required this.accountIndex,
    this.subaddrIndices,
    this.subaddrIndicesAll,
    this.priority,
    required this.outputs,
    required this.ringSize,
    required this.unlockTime,
    this.paymentId,
    this.getTxKeys,
    this.belowAmount,
    this.doNotRelay,
    this.getTxHex,
    this.getTxMetadata,
  });

  /// Destination public address.
  final MoneroAddress address;

  /// Sweep transactions from this account.
  final int accountIndex;

  /// Sweep from this set of subaddresses in the account.
  final List<int>? subaddrIndices;

  /// Use outputs in all subaddresses within an account.
  /// Defaults to `false`.
  final bool? subaddrIndicesAll;

  /// Priority for sending the sweep transfer, partially determines fee.
  final int? priority;

  /// Specify the number of separate outputs of smaller denomination
  /// that will be created by the sweep operation.
  final int outputs;

  /// Sets ringsize to n (mixin + 1).
  /// (Unless dealing with pre-RCT outputs, this field is ignored on mainnet).
  final int ringSize;

  /// Number of blocks before the Monero can be spent. (0 to not add a lock).
  final int unlockTime;

  /// 16 characters hex-encoded payment ID.
  final String? paymentId;

  /// Return the transaction keys after sending.
  final bool? getTxKeys;

  /// Include outputs below this amount.
  final int? belowAmount;

  /// If `true`, do not relay this sweep transfer.
  /// Defaults to `false`.
  final bool? doNotRelay;

  /// Return the transactions as a hex-encoded string.
  /// Defaults to `false`.
  final bool? getTxHex;

  /// Return the transaction metadata as a string.
  /// Defaults to `false`.
  final bool? getTxMetadata;
  @override
  String get method => "sweep_all";
  @override
  Map<String, dynamic> get params => {
    "address": address.address,
    "account_index": accountIndex,
    "subaddr_indices": subaddrIndices,
    "subaddr_indices_all": subaddrIndicesAll,
    "priority": priority,
    "outputs": outputs,
    "ring_size": ringSize,
    "unlock_time": unlockTime,
    "payment_id": paymentId,
    "get_tx_keys": getTxKeys,
    "below_amount": belowAmount,
    "do_not_relay": doNotRelay,
    "get_tx_hex": getTxHex,
    "get_tx_metadata": getTxMetadata,
  };

  @override
  WalletRPCSweepResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCSweepResponse.fromJson(result);
  }
}
