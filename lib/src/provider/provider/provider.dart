import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/service/service.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';

/// Facilitates communication with the monero deamon or wallet api by making requests using a provided [MoneroProvider].
class MoneroProvider extends BaseProvider<MoneroRequestDetails> {
  /// The underlying deamon service provider used for network communication.
  final MoneroServiceProvider rpc;

  /// Constructs a new [MoneroProvider] instance with the specified [rpc] service provider.
  MoneroProvider(this.rpc);

  int _id = 0;

  static SERVICERESPONSE _findError<SERVICERESPONSE>(
      {required MoneroServiceResponse response,
      required MoneroRequestDetails params}) {
    switch (params.requestType) {
      case DemonRequestType.json:
      case DemonRequestType.jsonRPC:
        final data = response
            .cast<BaseServiceResponse<Map<String, dynamic>>>()
            .getResult(params);
        if (params.requestType == DemonRequestType.json) {
          return ServiceProviderUtils.parseResponse(
              object: data, params: params);
        }
        final error =
            StringUtils.tryToJson<Map<String, dynamic>>(data["error"]);
        if (error != null) {
          throw RPCError(
              message: error["message"]?.toString() ?? '',
              errorCode: IntUtils.tryParse(error["code"]),
              details: error);
        }
        return ServiceProviderUtils.parseResponse(
            object: data["result"], params: params);
      case DemonRequestType.binary:
        final data =
            response.cast<BaseServiceResponse<List<int>>>().getResult(params);
        final jsonData = MoneroStorageSerializer.deserialize(data);
        return ServiceProviderUtils.parseResponse(
            object: jsonData, params: params);
    }
  }

  /// Sends a request to the monero using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, MoneroRequestDetails> request,
      {Duration? timeout}) async {
    final r = await requestDynamic(request, timeout: timeout);
    return request.onResonse(r);
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  /// Whatever is received will be returned
  @override
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, MoneroRequestDetails> request,
      {Duration? timeout}) async {
    final params = request.buildRequest(_id++);
    final response = switch (params.requestType) {
      DemonRequestType.json ||
      DemonRequestType.jsonRPC =>
        await rpc.doRequest<Map<String, dynamic>>(params, timeout: timeout),
      DemonRequestType.binary =>
        await rpc.doRequest<List<int>>(params, timeout: timeout)
    };
    return _findError(response: response, params: params);
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  /// response binary data will be returned
  Future<List<int>> requestBinary<RESULT, SERVICERESPONSE>(
      BaseServiceRequest<RESULT, SERVICERESPONSE, MoneroRequestDetails> request,
      {Duration? timeout}) async {
    final params = request.buildRequest(_id++);
    final response = await rpc.doRequest<List<int>>(params, timeout: timeout);
    return response.getResult(params);
  }
}
