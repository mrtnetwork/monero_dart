import 'package:monero_dart/src/provider/core/core.dart';

/// Submit a previously signed transaction on a read-only wallet (in cold-signing process).
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#submit_transfer
class WalletRequestSubmitTransfer
    extends MoneroWalletRequestParam<List<String>, Map<String, dynamic>> {
  const WalletRequestSubmitTransfer(this.txDataHex);

  /// Set of signed tx returned by "sign_transfer".
  final String txDataHex;
  @override
  String get method => "submit_transfer";
  @override
  Map<String, dynamic> get params => {"tx_data_hex": txDataHex};

  @override
  List<String> onResonse(Map<String, dynamic> result) {
    return (result["tx_hash_list"] as List).cast();
  }
}
