import 'package:monero_dart/src/provider/core/core.dart';

/// Return the spend or view private key.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#query_key
class WalletRequestQueryKey
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestQueryKey(this.keyType);

  /// Which key to retrieve: "mnemonic" - the mnemonic seed (older wallets do not have one) OR "view_key" - the view key OR "spend_key".
  final String keyType;
  @override
  String get method => "query_key";
  @override
  Map<String, dynamic> get params => {"key_type": keyType};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["key"];
  }
}
