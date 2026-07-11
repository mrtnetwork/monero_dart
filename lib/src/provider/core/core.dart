import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';

enum DemonRequestType {
  json(0),
  jsonRPC(1),
  binary(2);

  final int value;
  const DemonRequestType(this.value);
  static DemonRequestType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "DemonRequestType"),
    );
  }
}

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
  RequestMethod get requestMethod => RequestMethod.post;

  @override
  MoneroRequestDetails buildRequest(
    int requestID, {
    ServiceReponseEncoding? encoding,
  }) {
    final String? bodyString = switch (encodingType) {
      DemonRequestType.json => StringUtils.fromJson(params),
      DemonRequestType.jsonRPC => StringUtils.fromJson(
        ServiceProviderUtils.buildJsonRPCParams(
          params: params,
          method: method,
          requestId: requestID,
        ),
      ),
      _ => null,
    };
    List<int>? bodyBytes;
    if (encodingType == DemonRequestType.binary) {
      final bodyJson = params as Map<String, dynamic>;
      if (bodyJson.isNotEmpty) {
        final storage = MoneroStorage.fromJson(bodyJson);
        bodyBytes = storage.serialize();
      }
    }
    return MoneroRequestDetails(
      requestID: requestID,
      method: method,
      headers: headers,
      bodyString: bodyString,
      bodyBytes: bodyBytes,
      requestType: encodingType,
      responseEncoding:
          encoding ??
          switch (encodingType) {
            DemonRequestType.binary => ServiceReponseEncoding.binary,
            _ => ServiceReponseEncoding.map,
          },
      requestMethod: requestMethod,
      api: MoneroProviderApi.daemon,
    );
  }
}

abstract class MoneroWalletRequestParam<RESULT, RESPONSE>
    extends MoneroDaemonRequestParam<RESULT, RESPONSE> {
  const MoneroWalletRequestParam();
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  MoneroRequestDetails buildRequest(
    int requestID, {
    ServiceReponseEncoding? encoding,
  }) {
    return MoneroRequestDetails(
      requestID: requestID,
      method: method,
      headers: headers,
      responseEncoding: encoding ?? ServiceReponseEncoding.map,
      bodyString: StringUtils.fromJson(
        ServiceProviderUtils.buildJsonRPCParams(
          params: params,
          method: method,
          requestId: requestID,
        ),
      ),
      requestType: encodingType,
      requestMethod: requestMethod,
      api: MoneroProviderApi.wallet,
    );
  }
}

/// monero api type (daemon, wallet)
enum MoneroProviderApi {
  daemon(0),
  wallet(1);

  final int value;
  const MoneroProviderApi(this.value);

  static MoneroProviderApi fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(name: "MoneroProviderApi"),
    );
  }
}

class MoneroRequestDetails extends BaseServiceRequestParams {
  final MoneroProviderApi api;
  final DemonRequestType requestType;
  final String method;

  const MoneroRequestDetails({
    required super.requestID,
    super.path,
    required super.responseEncoding,
    required super.headers,
    required this.requestType,
    required this.method,
    super.successStatusCodes,
    super.errorStatusCodes,
    super.requestMethod = RequestMethod.post,
    super.bodyBytes,
    super.bodyString,
    required this.api,
  }) : super(network: BlockchainNetwork.monero);
  factory MoneroRequestDetails.deserialize({
    List<int>? bytes,
    CborObject? obj,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainNetwork.monero.identifier,
      cborBytes: bytes,
      cborObject: obj,
    );
    return MoneroRequestDetails(
      headers: values
          .mapAt<CborStringValue, CborStringValue>(0)
          .map((k, v) => MapEntry(k.value, v.value)),
      requestMethod: RequestMethod.fromValue(values.rawValueAt(1)),
      responseEncoding: ServiceReponseEncoding.fromValue(values.rawValueAt(2)),
      successStatusCodes:
          values
              .listAt<CborIntValue>(3)
              .map((e) => e.value)
              .toList()
              .emptyAsNull,
      errorStatusCodes:
          values
              .listAt<CborIntValue>(4)
              .map((e) => e.value)
              .toList()
              .emptyAsNull,
      bodyBytes: values.rawValueAt(5),
      bodyString: values.rawValueAt(6),
      path: values.rawValueAt(7),
      requestID: values.rawValueAt(8),
      api: MoneroProviderApi.fromValue(values.rawValueAt(9)),
      requestType: DemonRequestType.fromValue(values.rawValueAt(10)),
      method: values.rawValueAt(11),
    );
  }
  MoneroRequestDetails copyWith({
    int? requestID,
    String? path,
    RequestMethod? requestMethod,
    Map<String, String>? headers,
    List<int>? bodyBytes,
    String? bodyString,
    ServiceReponseEncoding? responseEncoding,
    List<int>? errorStatusCodes,
    List<int>? successStatusCodes,
    MoneroProviderApi? api,
    DemonRequestType? requestType,
    String? method,
  }) {
    return MoneroRequestDetails(
      requestID: requestID ?? this.requestID,
      headers: headers ?? this.headers,
      path: path ?? this.path,
      responseEncoding: responseEncoding ?? this.responseEncoding,
      requestMethod: requestMethod ?? this.requestMethod,
      bodyString: bodyString ?? this.bodyString,
      errorStatusCodes: errorStatusCodes ?? this.errorStatusCodes,
      bodyBytes: bodyBytes ?? this.bodyBytes,
      successStatusCodes: successStatusCodes ?? this.successStatusCodes,
      api: api ?? this.api,
      requestType: requestType ?? this.requestType,
      method: method ?? this.method,
    );
  }

  @override
  Uri encodeUrl(String uri) {
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
      "type": requestMethod.name,
      "body": bodyString ?? BytesUtils.tryToHexString(bodyBytes),
      "api": api.name,
      "request_type": requestType.name,
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      BlockchainNetwork.monero.identifier;

  @override
  List<CborObject?> get serializationItems => [
    CborMapValue.definite(
      headers.map((k, v) => MapEntry(CborStringValue(k), CborStringValue(v))),
    ),
    requestMethod.value.toCbor(),
    responseEncoding.value.toCbor(),
    CborTagSerializable.listFromDynamic(
      successStatusCodes?.map((e) => CborIntValue(e)).toList() ?? [],
    ),
    CborTagSerializable.listFromDynamic(
      errorStatusCodes?.map((e) => CborIntValue(e)).toList() ?? [],
    ),
    bodyBytes?.toCborBytes(),
    bodyString?.toCbor(),
    path?.toCbor(),
    requestID.toCbor(),
    api.value.toCbor(),
    requestType.value.toCbor(),
    method.toCbor(),
  ];
}
