import 'package:monero_dart/src/provider/core/core.dart';

/// Rescan the blockchain from scratch, losing any information which can not be recovered from the blockchain itself.
/// This includes destination addresses, tx secret keys, tx notes, etc.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#rescan_blockchain
class WalletRequestRescanBlockchain
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  @override
  String get method => "rescan_blockchain";
  @override
  Map<String, dynamic> get params => {};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
