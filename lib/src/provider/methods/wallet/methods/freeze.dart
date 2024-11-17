import 'package:monero_dart/src/provider/core/core.dart';

/// Freeze a single output by key image so it will not be used
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#freeze
class WalletRequestFreez
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestFreez(this.keyImage);

  final String keyImage;
  @override
  String get method => "freeze";
  @override
  Map<String, dynamic> get params => {"key_image": keyImage};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
