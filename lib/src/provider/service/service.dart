import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';

typedef MoneroServiceResponse<T> = BaseServiceResponse<T>;

/// A mixin defining the service provider contract for interacting with the Ton network.
mixin MoneroServiceProvider
    implements BaseServiceProvider<MoneroRequestDetails> {
  /// Example
  /// @override
  /// Future<`MoneroServiceResponse<T>`> doRequest<`T`>(MoneroRequestDetails params,
  ///     {Duration? timeout}) async {
  ///   final url = params.toUri(
  ///       params.api == MoneroRequestApiType.wallet ? walletUrl! : daemoUrl!);
  ///   final response = await client
  ///       .post(url, headers: params.headers, body: params.body())
  ///       .timeout(timeout ?? defaultRequestTimeout);
  ///   return params.toResponse(response.body, response.statusCode);
  /// }

  @override
  Future<BaseServiceResponse<T>> doRequest<T>(MoneroRequestDetails params,
      {Duration? timeout});
}
