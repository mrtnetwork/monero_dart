import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Create a payment URI using the official URI spec.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#make_uri
class WalletRequestMakeUri
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  const WalletRequestMakeUri({
    required this.address,
    this.amount,
    this.paymentId,
    this.recipientName,
    this.txDescription,
  });

  /// Wallet address
  final MoneroAddress address;

  /// the integer amount to receive, in atomic-units.
  final BigInt? amount;

  /// 16 characters hex encoded.
  final String? paymentId;

  /// name of the payment recipient
  final String? recipientName;

  /// Description of the reason for the tx
  final String? txDescription;
  @override
  String get method => "make_uri";
  @override
  Map<String, dynamic> get params => {
    "address": address.address,
    "amount ": amount?.toString(),
    "payment_id": paymentId,
    "recipient_name": recipientName,
    "tx_description": txDescription,
  };
  @override
  String onResonse(Map<String, dynamic> result) {
    return result["uri"];
  }
}
