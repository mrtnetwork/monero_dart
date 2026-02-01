import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Performs extra multisig keys exchange rounds. Needed for arbitrary M/N multisig wallets
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#exchange_multisig_keys
class WalletRequestExchangeMultisigKeys
    extends
        MoneroWalletRequestParam<
          WalletRPCExchangeMultisigKeysResponse,
          Map<String, dynamic>
        > {
  WalletRequestExchangeMultisigKeys({
    required this.password,
    required this.multisigInfo,
    this.forceUpdateUseWithCaution,
  });

  final String password;
  final String multisigInfo;

  /// only require the minimum number of signers to complete this round (including local signer)
  /// ( minimum = num_signers - (round num - 1).
  final bool? forceUpdateUseWithCaution;

  @override
  String get method => "exchange_multisig_keys";
  @override
  Map<String, dynamic> get params => {
    "password": password,
    "multisig_info": multisigInfo,
    "force_update_use_with_caution": forceUpdateUseWithCaution,
  };

  @override
  WalletRPCExchangeMultisigKeysResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCExchangeMultisigKeysResponse.fromJson(result);
  }
}
