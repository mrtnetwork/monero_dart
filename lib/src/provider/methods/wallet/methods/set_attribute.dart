import 'package:monero_dart/src/provider/core/core.dart';

/// Set arbitrary attribute.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#set_attribute
class WalletRequestSetAttribute
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestSetAttribute({required this.key, required this.value});

  /// attribute name
  final String key;

  /// attribute value
  final String value;
  @override
  String get method => "set_attribute";
  @override
  Map<String, dynamic> get params => {"key": key, "value": value};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
