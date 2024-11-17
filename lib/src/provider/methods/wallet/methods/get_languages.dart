import 'package:monero_dart/src/provider/core/core.dart';

/// Get a list of available languages for your wallet's seed.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_languages
class WalletRequestGetLanguages
    extends MoneroWalletRequestParam<List<String>, Map<String, dynamic>> {
  WalletRequestGetLanguages();

  @override
  String get method => "get_languages";
  @override
  Map<String, dynamic> get params => {};

  /// List of available languages
  @override
  List<String> onResonse(Map<String, dynamic> result) {
    return (result["languages"] as List).cast();
  }
}
