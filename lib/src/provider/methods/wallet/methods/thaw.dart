import 'package:monero_dart/src/provider/core/core.dart';

/// Thaw a single output by key image so it may be used again
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#thaw
class WalletRequestTagThaw
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  const WalletRequestTagThaw(this.keyImage);

  final String keyImage;

  @override
  String get method => "thaw";
  @override
  Map<String, dynamic> get params => {"key_image": keyImage};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
