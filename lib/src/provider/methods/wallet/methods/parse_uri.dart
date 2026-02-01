import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Parse a payment URI to get payment information.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#parse_uri
class WalletRequestParseUri
    extends
        MoneroWalletRequestParam<
          WalletRPCParseUriResponse,
          Map<String, dynamic>
        > {
  const WalletRequestParseUri(this.uri);

  /// This contains all the payment input information as a properly formatted payment URI
  final String uri;

  @override
  String get method => "parse_uri";
  @override
  Map<String, dynamic> get params => {"uri": uri};
  @override
  WalletRPCParseUriResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCParseUriResponse.fromJson(result["uri"]);
  }
}
