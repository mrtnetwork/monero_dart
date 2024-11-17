import 'package:monero_dart/src/provider/core/core.dart';

/// Given list of txids, scan each for outputs belonging to your wallet. 
/// Note that the node will see these specific requests and may be a privacy concern.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#scan_tx
class WalletRequestScanTx
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestScanTx(this.txids);
  final List<String> txids;
  @override
  String get method => "scan_tx";
  @override
  Map<String, dynamic> get params => {"txids": txids};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
