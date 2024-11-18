import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Send all dust outputs back to the wallet's, to make them easier to spend (and mix).
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#sweep_dust
class WalletRequestSweepDust extends MoneroWalletRequestParam<
    WalletRPCSweepResponse, Map<String, dynamic>> {
  WalletRequestSweepDust(
      {this.getTxKeys, this.doNotRelay, this.getTxHex, this.getTxMetadata});

  /// Return the transaction keys after sending.
  final bool? getTxKeys;

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
  String get method => "sweep_dust";
  @override
  Map<String, dynamic> get params => {
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
