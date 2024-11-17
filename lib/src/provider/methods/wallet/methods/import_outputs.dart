import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Import outputs in hex format.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#import_outputs
class WalletRequestImportOutputs
    extends MoneroWalletRequestParam<int, Map<String, dynamic>> {
  const WalletRequestImportOutputs(this.outputDataHex);

  /// wallet outputs in hex format.
  final String outputDataHex;

  @override
  String get method => "import_outputs";
  @override
  Map<String, dynamic> get params => {"outputs_data_hex": outputDataHex};

  /// number of outputs imported.
  @override
  int onResonse(Map<String, dynamic> result) {
    return IntUtils.parse(result["num_imported"]);
  }
}
