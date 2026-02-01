import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';

/// Verify a signature on a string.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#verify
class WalletRequestVerify
    extends MoneroWalletRequestParam<bool, Map<String, dynamic>> {
  WalletRequestVerify({
    required this.data,
    required this.address,
    required this.signature,
  });
  final String data;
  final MoneroAddress address;
  final String signature;

  @override
  String get method => "verify";
  @override
  Map<String, dynamic> get params => {
    "data": data,
    "address": address.address,
    "signature": signature,
  };

  @override
  bool onResonse(Map<String, dynamic> result) {
    return result["good"];
  }
}
