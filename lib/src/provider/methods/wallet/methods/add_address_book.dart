import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Add an entry to the address book.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#add_address_book
class WalletRequestAddAddressBook
    extends MoneroWalletRequestParam<int, Map<String, dynamic>> {
  WalletRequestAddAddressBook(
      {required this.address, this.paymentId, this.description});

  final MoneroAddress address;

  /// 16 characters hex encoded.
  final String? paymentId;
  final String? description;

  @override
  String get method => "add_address_book";
  @override
  Map<String, dynamic> get params => {
        "address": address.address,
        "payment_id": paymentId,
        "description": description
      };

  /// The index of the address book entry.
  @override
  int onResonse(Map<String, dynamic> result) {
    return IntUtils.parse(result["index"]);
  }
}
