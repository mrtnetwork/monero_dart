import 'package:blockchain_utils/utils/string/string.dart';
import 'package:monero_dart/src/provider/utils/utils.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';

enum DemonRequestType { json, jsonRPC, binary }

abstract class MoneroRPCMethodParams<RESULT, RESPONSE> {
  abstract final String method;
  const MoneroRPCMethodParams();

  /// request params.
  Object get params => {};

  /// request headers.
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  /// type of request
  DemonRequestType get requestType => DemonRequestType.json;

  /// convert request params, method and etc for service provider.
  MoneroRequestDetails toRequest(int id);

  /// convert response to specify object.
  /// should be overwrite in each request methods.
  RESULT onResonse(RESPONSE result) {
    return result as RESULT;
  }
}

/// monero daemon request
abstract class MoneroDaemonRequestParam<RESULT, RESPONSE>
    extends MoneroRPCMethodParams<RESULT, RESPONSE> {
  const MoneroDaemonRequestParam();

  @override
  MoneroRequestDetails toRequest(int id) {
    final p = params;
    Object? body;
    if (requestType == DemonRequestType.binary) {
      if (p is Map && p.isNotEmpty) {
        final storage = MoneroStorage.fromJson(p.cast());
        body = storage.serialize();
      }
    } else if (requestType == DemonRequestType.json) {
      body = StringUtils.fromJson(params);
    } else {
      body =
          ProviderUtils.buildRpcRequest(params: params, method: method, id: id);
    }

    return MoneroRequestDetails(
        id: id,
        method: method,
        headers: headers,
        body: body,
        requestType: requestType,
        api: MoneroRequestApiType.daemon);
  }
}

abstract class MoneroWalletRequestParam<RESULT, RESPONSE>
    extends MoneroDaemonRequestParam<RESULT, RESPONSE> {
  const MoneroWalletRequestParam();
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;

  @override
  MoneroRequestDetails toRequest(int id) {
    final body =
        ProviderUtils.buildRpcRequest(params: params, method: method, id: id);
    return MoneroRequestDetails(
        id: id,
        method: method,
        headers: headers,
        body: body,
        requestType: requestType,
        api: MoneroRequestApiType.wallet);
  }
}

/// monero api type (daemon, wallet)
enum MoneroRequestApiType { daemon, wallet }

/// the data of request can be build to request in provider
/// like method, params and headers
class MoneroRequestDetails {
  const MoneroRequestDetails({
    required this.id,
    required this.method,
    required this.requestType,
    this.headers = const {},
    this.body,
    required this.api,
  });

  /// api of request
  final MoneroRequestApiType api;

  /// request id
  final int id;

  /// request method
  final String method;

  /// the header of request.
  final Map<String, String> headers;

  /// body of request
  final Object? body;

  final DemonRequestType requestType;

  Uri toUrl(String baseUrl) {
    if (requestType == DemonRequestType.binary) {
      return Uri.parse(baseUrl).replace(path: method);
    }
    if (requestType == DemonRequestType.json) {
      return Uri.parse(baseUrl).replace(path: method);
    } else {
      return Uri.parse(baseUrl).replace(path: "json_rpc");
    }
  }
}
