// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:monero_dart/src/provider/core/core.dart';
// import 'package:monero_dart/src/provider/service/service.dart';

// class MoneroHTTPProvider implements MoneroServiceProvider {
//   MoneroHTTPProvider(this.url,
//       {http.Client? client,
//       this.walletUrl,
//       this.defaultRequestTimeout = const Duration(minutes: 1)})
//       : client = client ?? http.Client();

//   final String url;
//   final String? walletUrl;
//   final http.Client client;
//   final Duration defaultRequestTimeout;
//   @override
//   Future<MoneroServiceResponse> post(MoneroRequestDetails params,
//       [Duration? timeout]) async {
//     final url = params.toUrl(
//         params.api == MoneroRequestApiType.wallet ? walletUrl! : this.url);
//     final response = await client
//         .post(url,
//             headers: {'Content-Type': 'application/json', ...params.header},
//             body: params.body)
//         .timeout(timeout ?? defaultRequestTimeout);

//     return MoneroServiceResponse(
//         status: response.statusCode, responseBytes: response.bodyBytes);
//   }
// }
