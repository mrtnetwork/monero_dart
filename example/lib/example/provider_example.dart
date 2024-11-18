import 'package:http/http.dart' as http;
import 'package:monero_dart/monero_dart.dart';

MoneroProvider createProvider({String? url}) {
  final provider = MoneroProvider(MoneroHTTPProvider(
      daemoUrl: "http://stagenet.community.rino.io:38081",
      walletUrl: "http://127.0.0.1:1880"));
  return provider;
}

class MoneroHTTPProvider implements MoneroServiceProvider {
  MoneroHTTPProvider(
      {http.Client? client,
      this.daemoUrl,
      this.walletUrl,
      this.defaultRequestTimeout = const Duration(minutes: 1)})
      : client = client ?? http.Client();

  /// you should use base api url.

  final String? daemoUrl;
  final String? walletUrl;
  final http.Client client;
  final Duration defaultRequestTimeout;
  @override
  Future<MoneroServiceResponse> post(MoneroRequestDetails params,
      {Duration? timeout}) async {
    final url = params.toUrl(
        params.api == MoneroRequestApiType.wallet ? walletUrl! : daemoUrl!);
    final response = await client
        .post(url,
            headers: {
              ...params.headers,

              /// autorization or other service headers
            },
            body: params.body)
        .timeout(timeout ?? defaultRequestTimeout);

    return MoneroServiceResponse(
        status: response.statusCode, responseBytes: response.bodyBytes);
  }
}
