import 'package:monero_dart/src/provider/core/core.dart';

/// Export outputs in hex format.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#export_outputs
class WalletRequestExportOutputs
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestExportOutputs({this.all});

  /// If true, export all outputs. Otherwise, export outputs since the last export.
  final bool? all;

  @override
  String get method => "export_outputs";
  @override
  Map<String, dynamic> get params => {"all": all};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["outputs_data_hex"];
  }
}
