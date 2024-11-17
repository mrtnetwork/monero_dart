import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Get a list of user-defined account tags.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_account_tags
class WalletRequestGetAccountTags extends MoneroWalletRequestParam<
    WalletRPCGetAccountTagsResponse, Map<String, dynamic>> {
  WalletRequestGetAccountTags();

  @override
  String get method => "get_account_tags";
  @override
  Map<String, dynamic> get params => {};

  @override
  WalletRPCGetAccountTagsResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGetAccountTagsResponse.fromJson(result);
  }
}
