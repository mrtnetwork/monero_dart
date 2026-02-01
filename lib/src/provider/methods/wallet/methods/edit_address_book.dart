import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Edit an existing address book entry.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#edit_address_book
class WalletRequestEditAddressBook
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestEditAddressBook({
    required this.index,
    required this.setAddress,
    this.address,
    required this.setDescription,
    this.description,
    this.setPaymentId,
    this.paymentId,
  });

  /// Index of the address book entry to edit.
  final int index;

  /// If true, set the address for this entry to the value of "address".
  final bool setAddress;

  /// The 95-character public address to set.
  final MoneroAddress? address;

  /// If true, set the description for this entry to the value of "description".
  final bool setDescription;

  /// Human-readable description for this entry.
  final String? description;

  /// If true, set the payment ID for this entry to the value of "payment_id".
  final bool? setPaymentId;

  /// 16 characters hex encoded.
  final String? paymentId;
  @override
  String get method => "edit_address_book";
  @override
  Map<String, dynamic> get params => {
    "index": index,
    "set_address": setAddress,
    "address": address?.address,
    "set_description": setDescription,
    "description": description,
    "set_payment_id": setPaymentId,
    "payment_id": paymentId,
  };

  @override
  void onResonse(Map<String, dynamic> result) {}
}
