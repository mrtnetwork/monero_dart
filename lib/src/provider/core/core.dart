import 'package:blockchain_utils/utils/string/string.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';

enum DemonRequestType { json, jsonRPC, binary }

abstract class DaemonRequestParams {
  abstract final String method;
}

abstract class MoneroDaemonRequestParam<RESULT, RESPONSE>
    implements DaemonRequestParams {
  const MoneroDaemonRequestParam();
  Object get params => {};
  final Map<String, String>? header = null;
  DemonRequestType get requestType => DemonRequestType.json;
  // final DaemonCustomResponseParse? parser = null;

  MoneroRequestDetails toRequest(int v) {
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
      body = StringUtils.fromJson({
        "jsonrpc": "2.0",
        "id": v,
        "method": method,
        "params": params,
      });
    }

    return MoneroRequestDetails(
        id: v,
        method: method,
        header: header ?? {},
        body: body,
        requestType: requestType,
        api: MoneroRequestApiType.daemon);
  }

  RESULT onResonse(RESPONSE result) {
    return result as RESULT;
  }
}

abstract class MoneroWalletRequestParam<RESULT, RESPONSE>
    implements MoneroDaemonRequestParam<RESULT, RESPONSE> {
  const MoneroWalletRequestParam();
  @override
  Object get params => {};
  @override
  final Map<String, String>? header = null;
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;

  @override
  MoneroRequestDetails toRequest(int v) {
    final Object body = StringUtils.fromJson({
      "jsonrpc": "2.0",
      "id": v,
      "method": method,
      "params": params,
    });
    return MoneroRequestDetails(
        id: v,
        method: method,
        header: header ?? {},
        body: body,
        requestType: requestType,
        api: MoneroRequestApiType.wallet);
  }

  @override
  RESULT onResonse(RESPONSE result) {
    return result as RESULT;
  }
}

typedef DaemonCustomResponseParse = Object Function(List<int> responseBytes);

enum MoneroRequestApiType { daemon, wallet }

class MoneroRequestDetails {
  const MoneroRequestDetails({
    required this.id,
    required this.method,
    required this.requestType,
    this.responseParser,
    this.header = const {},
    this.body,
    required this.api,
  });

  final MoneroRequestApiType api;
  final int id;

  final String method;

  final Map<String, String> header;

  final Object? body;

  final DemonRequestType requestType;
  final DaemonCustomResponseParse? responseParser;

  Uri toUrl(String baseUrl) {
    if (api == MoneroRequestApiType.wallet) return Uri.parse(baseUrl);
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
