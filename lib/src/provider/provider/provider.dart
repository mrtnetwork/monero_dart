import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/service/service.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';

/// Facilitates communication with the monero deamon or wallet api by making requests using a provided [MoneroProvider].
class MoneroProvider {
  /// The underlying deamon service provider used for network communication.
  final MoneroServiceProvider rpc;

  /// Constructs a new [MoneroProvider] instance with the specified [rpc] service provider.
  MoneroProvider(this.rpc);

  int _id = 0;

  static dynamic _parseResponse(
      {required MoneroServiceResponse response,
      required MoneroRequestDetails request}) {
    String body = "Daemon request failed with status code ${response.status}";
    if (response.responseBytes.isNotEmpty) {
      final encode = StringUtils.tryDecode(response.responseBytes);
      body = encode ?? body;
    }
    if (!response.isSuccess) {
      throw RPCError(
          message: body, errorCode: null, details: StringUtils.tryToJson(body));
    }

    if (request.requestType == DemonRequestType.binary) {
      try {
        return MoneroStorageSerializer.deserialize(response.responseBytes);
      } catch (e) {
        throw RPCError(
            message: "Monero storage deserialization failed.",
            errorCode: null,
            details: {"error": e.toString(), "method": request.method});
      }
    }
    final Map<String, dynamic>? bodyJson = StringUtils.tryToJson(body);
    if (bodyJson == null) {
      throw RPCError(
          message: "response convertion to json failed.",
          errorCode: null,
          details: {"method": request.method});
    }
    if (request.requestType == DemonRequestType.jsonRPC) {
      final error = bodyJson["error"];
      if (error != null) {
        throw RPCError(
            message: error["message"] ?? body,
            errorCode: int.tryParse(error["code"]?.toString() ?? ""),
            details: error is Map ? Map<String, dynamic>.from(error) : null);
      }
      return bodyJson["result"];
    }

    return bodyJson;
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  /// Whatever is received will be returned
  Future<dynamic> requestDynamic(
    MoneroDaemonRequestParam request, {
    Duration? timeout,

    /// if false the [MoneroServiceResponse] returned.
    bool parseResponse = true,
  }) async {
    final id = ++_id;
    final params = request.toRequest(id);
    final data = await rpc.post(params, timeout: timeout);
    if (!parseResponse) return data;
    return _parseResponse(response: data, request: params);
  }

  /// Sends a request to the monero network using the specified [request] parameter.
  ///
  /// The [timeout] parameter, if provided, sets the maximum duration for the request.
  Future<T> request<T, E>(MoneroDaemonRequestParam<T, E> request,
      {Duration? timeout}) async {
    final data = await requestDynamic(request, timeout: timeout);
    if (data is Map && data.containsKey("status")) {
      if (data["status"] != "OK") {
        throw RPCError(
            message: data["status"],
            errorCode: null,
            details: Map<String, dynamic>.from(data));
      }
    }
    final Object result;
    if (E == List<Map<String, dynamic>>) {
      result = (data as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } else {
      result = data;
    }
    return request.onResonse(result as E);
  }
}
