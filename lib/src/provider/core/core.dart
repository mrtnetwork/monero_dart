import 'package:blockchain_utils/service/service.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';

enum DemonRequestType { json, jsonRPC, binary }

/// monero daemon request
abstract class MoneroDaemonRequestParam<RESULT, RESPONSE>
    extends BaseServiceRequest<RESULT, RESPONSE, MoneroRequestDetails> {
  const MoneroDaemonRequestParam();

  abstract final String method;

  /// request params.
  Object get params => {};

  /// request headers.
  Map<String, String> get headers => {'Content-Type': 'application/json'};

  /// type of request
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  RequestServiceType get requestType => RequestServiceType.post;

  @override
  MoneroRequestDetails buildRequest(int requestID) {
    // final p = params;
    final body = switch (encodingType) {
      DemonRequestType.binary ||
      DemonRequestType.json => (params as Map<String, dynamic>),
      DemonRequestType.jsonRPC => ServiceProviderUtils.buildJsonRPCParams(
        params: params,
        method: method,
        requestId: requestID,
      ),
    };
    return MoneroRequestDetails(
      requestID: requestID,
      method: method,
      headers: headers,
      jsonBody: body,
      requestType: encodingType,
      type: requestType,
      api: MoneroRequestApiType.daemon,
    );
  }
}

abstract class MoneroWalletRequestParam<RESULT, RESPONSE>
    extends MoneroDaemonRequestParam<RESULT, RESPONSE> {
  const MoneroWalletRequestParam();
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  MoneroRequestDetails buildRequest(int requestID) {
    return MoneroRequestDetails(
      requestID: requestID,
      method: method,
      headers: headers,
      jsonBody: ServiceProviderUtils.buildJsonRPCParams(
        params: params,
        method: method,
        requestId: requestID,
      ),
      requestType: encodingType,
      type: requestType,
      api: MoneroRequestApiType.wallet,
    );
  }
}

/// monero api type (daemon, wallet)
enum MoneroRequestApiType { daemon, wallet }

/// the data of request can be build to request in provider
/// like method, params and headers
class MoneroRequestDetails extends BaseServiceRequestParams {
  const MoneroRequestDetails({
    required super.requestID,
    required this.method,
    required this.requestType,
    required super.headers,
    super.type = RequestServiceType.post,
    required this.jsonBody,
    required this.api,
  });

  /// api of request
  final MoneroRequestApiType api;

  /// request method
  final String method;

  @override
  List<int>? body() {
    switch (requestType) {
      case DemonRequestType.json:
      case DemonRequestType.jsonRPC:
        return StringUtils.encode(StringUtils.fromJson(jsonBody));
      case DemonRequestType.binary:
        if (jsonBody.isNotEmpty) {
          final storage = MoneroStorage.fromJson(jsonBody);
          return storage.serialize();
        }
    }
    return null;
  }

  final Map<String, dynamic> jsonBody;

  final DemonRequestType requestType;

  @override
  Uri toUri(String uri) {
    if (requestType == DemonRequestType.binary) {
      return Uri.parse(uri).replace(path: method);
    }
    if (requestType == DemonRequestType.json) {
      return Uri.parse(uri).replace(path: method);
    } else {
      return Uri.parse(uri).replace(path: "json_rpc");
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": requestID,
      "type": type.name,
      "body": jsonBody,
      "api": api.name,
      "request_type": requestType.name,
    };
  }
}
