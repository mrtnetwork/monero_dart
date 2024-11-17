import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

class MoneroServiceResponse {
  /// the http status code of response
  final int status;

  /// response body as bytes in all staus situation.
  final List<int> responseBytes;
  MoneroServiceResponse(
      {required this.status, required List<int> responseBytes})
      : responseBytes = responseBytes.asImmutableBytes;
  bool get isSuccess => status >= 200 && status < 300;
}

mixin MoneroServiceProvider {
  Future<MoneroServiceResponse> post(MoneroRequestDetails params,
      [Duration? timeout]);
}
