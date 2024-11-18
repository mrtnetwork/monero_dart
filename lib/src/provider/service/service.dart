import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

class MoneroServiceResponse {
  /// the http status code of response
  final int status;

  /// response body as bytes in all status situation.
  final List<int> responseBytes;
  MoneroServiceResponse(
      {required this.status, required List<int> responseBytes})
      : responseBytes = responseBytes.asImmutableBytes;
  bool get isSuccess => status >= 200 && status < 300;
}

mixin MoneroServiceProvider {
  /// convert [MoneroRequestDetails] to http or wss request and return the result
  /// this should be overwrite by service provider.

  /// example using dart [http](https://pub.dev/packages/http) package.

  /// import 'package:http/http.dart' as http;
  /// class MyHttpProvider implements MoneroServiceProvider {
  ///   MyHttpProvider(
  ///       {http.Client? client,
  ///       this.daemonUrl,
  ///       this.walletUrl,
  ///       this.defaultRequestTimeout = const Duration(minutes: 1)})
  ///       : client = client ?? http.Client();

  ///   final String? daemonUrl;
  ///   final String? walletUrl;
  ///   final http.Client client;
  ///   final Duration defaultRequestTimeout;
  ///   @override
  ///   Future<MoneroServiceResponse> post(MoneroRequestDetails params,
  ///       {Duration? timeout}) async {
  ///     final url = params.toUrl(
  ///         params.api == MoneroRequestApiType.wallet ? walletUrl! : daemonUrl!);
  ///     final response = await client
  ///         .post(url,
  ///             headers: {'Content-Type': 'application/json', ...params.header},
  ///             body: params.body)
  ///         .timeout(timeout ?? defaultRequestTimeout);
  ///     return MoneroServiceResponse(
  ///         status: response.statusCode, responseBytes: response.bodyBytes);
  ///   }
  /// }
  Future<MoneroServiceResponse> post(MoneroRequestDetails params,
      {Duration? timeout});
}
