import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Analyzes a string to determine whether it is a valid monero wallet
/// address and returns the result and the address specifications.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#validate_address
class WalletRequestValidateAddress
    extends
        MoneroWalletRequestParam<
          WalletRPCValidateAddressResponse,
          Map<String, dynamic>
        > {
  const WalletRequestValidateAddress({
    required this.address,
    this.anyNetType,
    this.allowOpenAlias,
  });

  /// The address to validate.
  final String address;

  /// If true, consider addresses belonging to any of the three Monero networks (mainnet, stagenet, and testnet) valid.
  /// Otherwise, only consider an address valid if it belongs to the network on which the rpc-wallet's
  /// current daemon is running (Defaults to false).
  final bool? anyNetType;

  /// If true, consider OpenAlias-formatted addresses valid (Defaults to false)
  final bool? allowOpenAlias;

  @override
  String get method => "validate_address";
  @override
  Map<String, dynamic> get params => {
    "address": address,
    "any_net_type": anyNetType,
    "allow_openalias": allowOpenAlias,
  };
  @override
  WalletRPCValidateAddressResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCValidateAddressResponse.fromJson(result);
  }
}
