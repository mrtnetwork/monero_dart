import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Import multisig info from other participants.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#import_multisig_info
class WalletRequestImportMultisigInfo
    extends MoneroWalletRequestParam<int, Map<String, dynamic>> {
  WalletRequestImportMultisigInfo(this.info);

  /// List of multisig info in hex format from other participants.
  final List<String> info;

  @override
  String get method => "import_multisig_info";
  @override
  Map<String, dynamic> get params => {"info": info};

  /// Number of outputs signed with those multisig info.
  @override
  int onResonse(Map<String, dynamic> result) {
    return IntUtils.parse(result["n_outputs"]);
  }
}
