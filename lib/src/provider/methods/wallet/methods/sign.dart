import 'package:monero_dart/src/provider/core/core.dart';

/// Sign a string.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#sign
class WalletRequestSign
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestSign(this.data);

  /// Anything you need to sign.
  final String data;

  @override
  String get method => "sign";
  @override
  Map<String, dynamic> get params => {"data": data};

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["signature"];
  }
}
