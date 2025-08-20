import 'package:blockchain_utils/service/models/params.dart';
import 'package:http/http.dart' as http;
import 'package:monero_dart/monero_dart.dart';

MoneroProvider createProvider({String? url}) {
  final provider = MoneroProvider(MoneroHTTPProvider(
      daemoUrl: "https://xmr.surveillance.monster",
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
  // @override
  // Future<dynamic> doRequest<T>(MoneroRequestDetails params,
  //     {Duration? timeout}) async {
  // final url = params.toUri(
  //     params.api == MoneroRequestApiType.wallet ? walletUrl! : daemoUrl!);
  // final response = await client
  //     .post(url, headers: params.headers, body: params.body())
  //     .timeout(timeout ?? defaultRequestTimeout);
  //   return params.
  //   // return MoneroServiceResponse(
  //   //     status: response.statusCode, responseBytes: response.bodyBytes);
  // }
  @override
  Future<BaseServiceResponse<T>> doRequest<T>(MoneroRequestDetails params,
      {Duration? timeout}) async {
    final url = params.toUri(
        params.api == MoneroRequestApiType.wallet ? walletUrl! : daemoUrl!);
    final response = await client
        .post(url, headers: params.headers, body: params.body())
        .timeout(timeout ?? defaultRequestTimeout);
    return params.parseResponse(response.bodyBytes, response.statusCode);
  }
}
