import 'package:monero_dart/src/provider/core/core.dart';

/// Checks whether a given output is currently frozen by key image
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#frozen
class WalletRequestFrozen
    extends MoneroWalletRequestParam<bool, Map<String, dynamic>> {
  WalletRequestFrozen(this.keyImage);

  final String keyImage;
  @override
  String get method => "frozen";
  @override
  Map<String, dynamic> get params => {"key_image": keyImage};

  @override
  bool onResonse(Map<String, dynamic> result) {
    return result["frozen"];
  }
}
