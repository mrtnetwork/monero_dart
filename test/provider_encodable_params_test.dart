import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

void main() {
  test('encodable provider params', () {
    final param = DaemonRequestGetBlocksByHeightBin([1, 2, 3]);
    final request = param.buildRequest(0);
    final deserialize = MoneroRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.method, request.method);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.monero);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, request.api);
  });

  test('encodable provider params', () {
    final param = DaemonRequestGetPeerList(
      includeBlock: false,
      publicOnly: true,
    );
    final request = param.buildRequest(0);
    final deserialize = MoneroRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.method, request.method);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.monero);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, request.api);
  });
  test('encodable provider params', () {
    final param = DaemonRequestFlushTxPool(
      txids: [QuickCrypto.generateRandomHex()],
    );
    final request = param.buildRequest(0);
    final deserialize = MoneroRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.method, request.method);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.monero);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, request.api);
  });

  test('encodable provider params', () {
    final param = WalletRequestGetAddressBook([1, 2, 34]);
    final request = param.buildRequest(0);
    final deserialize = MoneroRequestDetails.deserialize(
      bytes: request.toCbor().encode(),
    );
    expect(deserialize.method, request.method);
    expect(deserialize.encodeBody(), request.encodeBody());
    expect(deserialize.successStatusCodes, request.successStatusCodes);
    expect(deserialize.errorStatusCodes, request.errorStatusCodes);
    expect(deserialize.network, BlockchainNetwork.monero);
    expect(deserialize.responseEncoding, request.responseEncoding);
    expect(deserialize.requestMethod, request.requestMethod);
    expect(deserialize.api, request.api);
  });
}
