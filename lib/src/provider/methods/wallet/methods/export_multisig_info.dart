import 'package:monero_dart/src/provider/core/core.dart';

/// Export multisig info for other participants.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#export_multisig_info
class WalletRequestExportMultisigInfo
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestExportMultisigInfo();

  @override
  String get method => "export_multisig_info";
  @override
  Map<String, dynamic> get params => {};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["info"];
  }
}
