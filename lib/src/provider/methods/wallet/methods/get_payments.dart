import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Get a list of incoming payments using a given payment id.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_payments
class WalletRequestGetPayments
    extends
        MoneroWalletRequestParam<
          List<WalletRPCPaymentResponse>,
          Map<String, dynamic>
        > {
  WalletRequestGetPayments(this.paymentId);

  /// Payment ID used to find the payments (16 characters hex).
  final String paymentId;
  @override
  String get method => "get_payments";
  @override
  Map<String, dynamic> get params => {"payment_id": paymentId};

  @override
  List<WalletRPCPaymentResponse> onResonse(Map<String, dynamic> result) {
    return (result["payments"] as List)
        .map((e) => WalletRPCPaymentResponse.fromJson(e))
        .toList();
  }
}
