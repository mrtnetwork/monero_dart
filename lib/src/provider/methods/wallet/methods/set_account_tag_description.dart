import 'package:monero_dart/src/provider/core/core.dart';

/// Set description for an account tag.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#set_account_tag_description
class WalletRequestSetAccountTagDescription
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestSetAccountTagDescription(
      {required this.tag, required this.description});
  final String tag;
  final String description;
  @override
  String get method => "set_account_tag_description";
  @override
  Map<String, dynamic> get params => {"tag": tag, "description": description};

  @override
  void onResonse(Map<String, dynamic> result) {}
}
