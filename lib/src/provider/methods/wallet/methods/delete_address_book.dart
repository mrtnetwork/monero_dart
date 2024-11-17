import 'package:monero_dart/src/provider/core/core.dart';

/// Delete an entry from the address book.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#delete_address_book
class WalletRequestDeleteAddressBook
    extends MoneroWalletRequestParam<Null, Map<String, dynamic>> {
  WalletRequestDeleteAddressBook({required this.index});

  /// The index of the address book entry.
  final int index;

  @override
  String get method => "delete_address_book";
  @override
  Map<String, dynamic> get params => {"index": index};

  @override
  Null onResonse(Map<String, dynamic> result) {
    return null;
  }
}
