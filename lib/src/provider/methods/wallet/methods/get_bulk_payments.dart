import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Get a list of incoming payments using a given payment id, or a list of payments ids,
/// from a given height. This method is the preferred method over get_payments
/// because it has the same functionality but is more extendable.
/// Either is fine for looking up transactions by a single payment ID.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_bulk_payments
class WalletRequestGetBulkPayments
    extends
        MoneroWalletRequestParam<
          List<WalletRPCPaymentResponse>,
          Map<String, dynamic>
        > {
  WalletRequestGetBulkPayments({
    required this.paymentIds,
    required this.minBlockHeight,
  });

  /// Payment IDs used to find the payments (16 characters hex)
  final List<String> paymentIds;

  /// The block height at which to start looking for payments.
  final BigInt minBlockHeight;
  @override
  String get method => "get_bulk_payments";
  @override
  Map<String, dynamic> get params => {
    "payment_ids": paymentIds,
    "min_block_height": minBlockHeight.toString(),
  };

  @override
  List<WalletRPCPaymentResponse> onResonse(Map<String, dynamic> result) {
    return (result["payments"] as List)
        .map((e) => WalletRPCPaymentResponse.fromJson(e))
        .toList();
  }
}
