import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// https://docs.getmonero.org/rpc-library/wallet-rpc/#estimate_tx_size_and_weight
class WalletRequestEstimateTxSizeAndWeight extends MoneroWalletRequestParam<
    WalletRPCEstimateTxSizeAndWeightResponse, Map<String, dynamic>> {
  WalletRequestEstimateTxSizeAndWeight(
      {required this.nInputs,
      required this.nOutputs,
      required this.rignSize,
      required this.rct});

  final int nInputs;
  final int nOutputs;

  /// Sets ringsize to n (mixin + 1). (Unless dealing with pre rct outputs, this field is ignored on mainnet).
  final int rignSize;

  /// Is this a Ring Confidential Transaction (post blockheight 1220516)
  final bool rct;

  @override
  String get method => "estimate_tx_size_and_weight";
  @override
  Map<String, dynamic> get params => {
        "n_inputs": nInputs,
        "n_outputs": nOutputs,
        "ring_size": rignSize,
        "rct": rct
      };

  @override
  WalletRPCEstimateTxSizeAndWeightResponse onResonse(
      Map<String, dynamic> result) {
    return WalletRPCEstimateTxSizeAndWeightResponse.fromJson(result);
  }
}
