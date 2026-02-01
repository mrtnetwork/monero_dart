import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Retrieves entries from the address book.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_address_book
class WalletRequestGetAddressBook
    extends
        MoneroWalletRequestParam<
          List<WalletRPCAddressBookResponse>,
          Map<String, dynamic>
        > {
  WalletRequestGetAddressBook(this.entries);

  /// indices of the requested address book entries.
  final List<int> entries;

  @override
  String get method => "get_address_book";
  @override
  Map<String, dynamic> get params => {"entries": entries};

  @override
  List<WalletRPCAddressBookResponse> onResonse(Map<String, dynamic> result) {
    return (result["entries"] as List)
        .map((e) => WalletRPCAddressBookResponse.fromJson(e))
        .toList();
  }
}
