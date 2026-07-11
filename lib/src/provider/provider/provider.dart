import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/service/service.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';

/// Facilitates communication with the monero deamon or wallet api by making requests using a provided [MoneroProvider].
class MoneroProvider<SERVICE extends IServiceProvider>
    extends IProvider<SERVICE, MoneroRequestDetails> {
  /// The underlying deamon service provider used for network communication.
  @override
  final SERVICE service;

  /// Constructs a new [MoneroProvider] instance with the specified [service] service provider.
  MoneroProvider(this.service);

  int _id = 0;

  static SERVICERESPONSE _findError<SERVICERESPONSE>({
    required MoneroServiceResponse response,
    required MoneroRequestDetails params,
    required bool catchStatus,
  }) {
    switch (params.requestType) {
      case DemonRequestType.json:
      case DemonRequestType.jsonRPC:
        final data = params.toEncodingResponse<Map<String, dynamic>>(response);
        if (params.requestType == DemonRequestType.json) {
          if (catchStatus) {
            final result =
                ServiceProviderUtils.toResponse<Map<String, dynamic>>(
                  object: data,
                  params: params,
                );
            final status = result["status"]?.toString().toLowerCase();
            if (status != null && status != "ok") {
              throw RPCError(
                message: "Daemon responded with failure status: $status",
                jsonRpcErrpr: result,
                relatedNetwork: BlockchainNetwork.monero,
                statusCode: response.statusCode,
              );
            }
          }

          return ServiceProviderUtils.toResponse<SERVICERESPONSE>(
            object: data,
            params: params,
          );
        }
        final error = StringUtils.tryToJson<Map<String, dynamic>>(
          data["error"],
        );
        if (error != null) {
          final message = error["message"];
          throw RPCError(
            message: message is String ? message : ServiceConst.defaultError,
            errorCode: IntUtils.tryParse(error["code"]),
            jsonRpcErrpr: data,
            relatedNetwork: BlockchainNetwork.monero,
          );
        }
        return ServiceProviderUtils.toResponse<SERVICERESPONSE>(
          object: data["result"],
          params: params,
        );
      case DemonRequestType.binary:
        final data = params.toEncodingResponse<List<int>>(response);
        final jsonData = MoneroStorageSerializer.deserialize(data);
        if (catchStatus) {
          final status = jsonData["status"]?.toString().toLowerCase();
          if (status != null && status != "ok") {
            throw RPCError(
              message: "Daemon responded with failure status: $status",
              jsonRpcErrpr: jsonData,
              relatedNetwork: BlockchainNetwork.monero,
            );
          }
        }
        return ServiceProviderUtils.toResponse<SERVICERESPONSE>(
          object: jsonData,
          params: params,
        );
    }
  }

  /// Sends a request to the monero using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  @override
  Future<RESULT> request<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, MoneroRequestDetails> request, {
    Duration? timeout,
  }) async {
    final r = await requestDynamic<RESULT, SERVICERESPONSE>(
      request,
      timeout: timeout,
    );
    return request.onResonse(r);
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  /// Whatever is received will be returned
  @override
  Future<SERVICERESPONSE> requestDynamic<RESULT, SERVICERESPONSE>(
    IServiceRequest<RESULT, SERVICERESPONSE, MoneroRequestDetails> request, {
    Duration? timeout,
    bool catchStatus = true,
  }) async {
    final params = request.buildRequest(_id++);
    final response = switch (params.requestType) {
      DemonRequestType.json || DemonRequestType.jsonRPC => await service
          .doRequest(params, timeout: timeout),
      DemonRequestType.binary => await service.doRequest(
        params,
        timeout: timeout,
      ),
    };
    return _findError<SERVICERESPONSE>(
      response: response,
      params: params,
      catchStatus: catchStatus,
    );
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  /// response binary data will be returned
  Future<List<int>> requestBinary<RESULT, SERVICERESPONSE>(
    MoneroDaemonRequestParam<RESULT, SERVICERESPONSE> request, {
    Duration? timeout,
  }) async {
    MoneroRequestDetails params = request.buildRequest(
      _id++,
      encoding: ServiceReponseEncoding.binary,
    );
    final response = await service.doRequest(params, timeout: timeout);
    return params.toEncodingResponse<List<int>>(response);
  }
}
