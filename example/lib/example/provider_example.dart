import 'package:blockchain_utils/service/models/params.dart';
import 'package:http/http.dart' as http;
import 'package:monero_dart/monero_dart.dart';

MoneroProvider createProvider({String? url, String? walletUrl}) {
  final provider = MoneroProvider(MoneroHTTPProvider(
      daemoUrl: url ?? "https://xmr.surveillance.monster",
      walletUrl: walletUrl ?? "http://127.0.0.1:1880"));
  return provider;
}

class MoneroHTTPProvider with MoneroServiceProvider {
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
  Future<BaseServiceResponse> doRequest(MoneroRequestDetails params,
      {Duration? timeout}) async {
    final url = params.encodeUrl(
        params.api == MoneroProviderApi.wallet ? walletUrl! : daemoUrl!);
    final response = await client
        .post(url, headers: params.headers, body: params.encodeBody())
        .timeout(timeout ?? defaultRequestTimeout);
    return params.toResponse(response.bodyBytes,
        statusCode: response.statusCode);
  }
}
