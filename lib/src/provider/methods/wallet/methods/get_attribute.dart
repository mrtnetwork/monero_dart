import 'package:monero_dart/src/provider/core/core.dart';

/// Get attribute value by name.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_attribute
class WalletRequestGetAttribute
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestGetAttribute(this.key);

  /// attribute name
  final String key;

  @override
  String get method => "get_attribute";
  @override
  Map<String, dynamic> get params => {"key": key};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["value"];
  }
}
