import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Check a transaction in the blockchain with its secret key.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#check_tx_key
class WalletRequestCheckTxKey
    extends
        MoneroWalletRequestParam<
          WalletRPCCheckTxKeyResponse,
          Map<String, dynamic>
        > {
  WalletRequestCheckTxKey({
    required this.txId,
    required this.txKey,
    required this.address,
  });

  ///  transaction id.
  final String txId;

  /// transaction secret key.
  final String txKey;

  /// destination public address of the transaction.
  final MoneroAddress address;

  @override
  String get method => "check_tx_key";
  @override
  Map<String, dynamic> get params => {
    "txid": txId,
    "tx_key": txKey,
    "address": address.address,
  };

  @override
  WalletRPCCheckTxKeyResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCCheckTxKeyResponse.fromJson(result);
  }
}
