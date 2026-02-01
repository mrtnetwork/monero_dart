import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Make a wallet multisig by importing peers multisig string.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#make_multisig
class WalletRequestMakeMultisig
    extends
        MoneroWalletRequestParam<
          WalletRPCMakeMultisigResponse,
          Map<String, dynamic>
        > {
  const WalletRequestMakeMultisig({
    required this.multisigInfo,
    required this.threshold,
    required this.password,
  });

  final List<String> multisigInfo;

  final int threshold;
  final String password;

  @override
  String get method => "make_multisig";
  @override
  Map<String, dynamic> get params => {
    "multisig_info": multisigInfo,
    "threshold": threshold,
    "password": password,
  };
  @override
  WalletRPCMakeMultisigResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCMakeMultisigResponse.fromJson(result);
  }
}
