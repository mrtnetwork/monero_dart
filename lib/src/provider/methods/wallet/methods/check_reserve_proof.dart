import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Proves a wallet has a disposable reserve using a signature.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#check_reserve_proof
class WalletRequestCheckReserveProof
    extends
        MoneroWalletRequestParam<
          WalletRPCCheckReserveProofResponse,
          Map<String, dynamic>
        > {
  WalletRequestCheckReserveProof({
    required this.address,
    this.message,
    required this.signature,
  });

  /// Public address of the wallet.
  final MoneroAddress address;

  /// If a message was added to get_reserve_proof (optional),
  /// this message will be required when using check_reserve_proof
  final String? message;

  /// reserve signature to confirm.
  final String signature;

  @override
  String get method => "check_reserve_proof";
  @override
  Map<String, dynamic> get params => {
    "address": address.address,
    "message": message,
    "signature": signature,
  };

  @override
  WalletRPCCheckReserveProofResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCCheckReserveProofResponse.fromJson(result);
  }
}
