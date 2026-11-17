// Offline tests for MoneroQuickClientApi
// (lib/src/api/provider/provider.dart). Stub-service tests only — no network.
import 'dart:async';
import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

import 'utils.dart';

class _StubMoneroService with MoneroServiceProvider {
  final BaseServiceResponse Function(MoneroRequestDetails params) respond;
  _StubMoneroService(this.respond);

  @override
  Future<BaseServiceResponse> doRequest(
    MoneroRequestDetails params, {
    Duration? timeout,
  }) async => respond(params);
}

BaseServiceResponse _ok(MoneroRequestDetails params, Map<String, dynamic> payload) {
  final withStatus = {'status': 'OK', ...payload};
  final Object bodyPayload =
      params.requestType == DaemonRequestType.jsonRPC
          ? {'result': withStatus}
          : withStatus;
  return params.toResponse(utf8.encode(jsonEncode(bodyPayload)));
}

class _Client with MoneroQuickClientApi {
  _Client(this._provider);

  final MoneroProvider<_StubMoneroService> _provider;

  @override
  MoneroProvider get provider => _provider;
}

MoneroQuickClientApi _quick(
  BaseServiceResponse Function(MoneroRequestDetails params) respond,
) {
  return _Client(MoneroProvider(_StubMoneroService(respond)));
}

Map<String, dynamic> _header({required int height}) => {
  'major_version': 16,
  'minor_version': 16,
  'timestamp': 1700000000,
  'prev_hash': '00',
  'nonce': 0,
  'orphan_status': false,
  'height': height,
  'depth': 1,
  'hash': 'abc',
  'difficulty': '1000',
  'wide_difficulty': '0x1000',
  'difficulty_top64': 0,
  'cumulative_difficulty': '1000',
  'wide_cumulative_difficulty': '0x1000',
  'reward': '1000',
  'block_size': 100,
  'block_weight': 100,
  'num_txes': 1,
  'pow_hash': '00',
  'long_term_weight': 100,
  'miner_tx_hash': '00',
  'cumulative_difficulty_top64': 0,
};

const _validTxHex =
    "020002020010b2a2d702e69bdc0196be019e26ff89018705e30dd9259109db02db0691028704f4013f810160f9976e961ac513e4fcd1d2373cd6455a7f8db645c5cecb8c8c799ba99d6714020010acf894049ef70ec2e401a9d501a3b20c899101a366b63480028519a753d804c40679256c5cd197962cb2dd516dcbfae4b2ac5ac6eca86b28365e9d7ca0cfb0ededb4d795020003de8063db546d2e0010d6d9da9ed89501d766268e011ac89beef96d2acc76d1c0dd0003b2cfd1de4a268ebd91f74a8400bbf8aa2cb31187a254a4ddefc14e2714fc7dee482c01aee30e15868848c3e8771f84cc3bd8097f5b3e8caaeafb813ebf8936b1b19508020901dcdfc9ff43dbb51506d081bf321d4d56f77ddeabf9eefb40d119102370ede5657ea1554d3e100b27e543be0ba287ca288aca3125b1f4512488e68e483ea607ea4c5998e6f0eae91ad672a4909571e94e148242ecb1be8979ea0f746435";

Map<String, dynamic> _txJson({
  required String txHash,
  bool inPool = false,
  int? height = 100,
  bool doubleSpend = false,
  int confirmations = 5,
  String txHex = _validTxHex,
  List<int>? outputIndices,
}) => {
  'tx_hash': txHash,
  'in_pool': inPool,
  'block_height': height,
  'block_timestamp': 1700000000,
  'double_spend_seen': doubleSpend,
  'confirmations': confirmations,
  'as_hex': txHex,
  'pruned_as_hex': '',
  'prunable_hash': '00' * 32,
  if (outputIndices != null) 'output_indices': outputIndices,
};

void moneroQuickClientApiTest() {
  group('MoneroQuickClientApi (offline)', () {
    test('getHeight reads last block height', () async {
      final quick = _quick(
        (p) => _ok(p, {
          'block_header': _header(height: 100),
        }),
      );
      expect(await quick.getHeight(), 100);
    });

    test('getBlockHeight parses daemon height', () async {
      final quick = _quick(
        (p) => _ok(p, {
          'height': 200,
          'hash': 'abc',
          'top_hash': 'abc',
          'untrusted': false,
        }),
      );
      expect(await quick.getDaemonHeight(), BigInt.from(200));
    });

    test('getTxes maps by input order', () async {
      final quick = _quick(
        (p) => _ok(p, {
          'txs': [_txJson(txHash: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'), _txJson(txHash: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb')],
        }),
      );
      final txes = await quick.getTxes(
        txHashes: [
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ],
        allowMempol: true,
      );
      expect(txes.length, 2);
    });

    test('getSpentKeyImages filters spent', () async {
      final quick = _quick(
        (p) => _ok(p, {'spent_status': [1, 0]}),
      );
      expect(
        await quick.getSpentKeyImages(['k1', 'k2']),
        ['k1'],
      );
      expect(await quick.getSpentKeyImages([]), isEmpty);
    });

    test('sendRawTransaction accepts and rejects', () async {
      final quick = _quick(
        (p) => _ok(p, {'reason': '', 'status': 'OK'}),
      );
      expect(await quick.sendRawTransaction('deadbeef'), 'deadbeef');

      final rejected = _quick(
        (p) => _ok(p, {'reason': 'double spend', 'double_spend': true}),
      );
      expect(
        () => rejected.sendRawTransaction('deadbeef'),
        throwsA(isA<BuError>()),
      );
    });

    test('trackTransaction completes, times out otherwise', () async {
      final quick = _quick(
        (p) => _ok(p, {
          'txs': [_txJson(txHash: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', confirmations: 3)],
        }),
      );
      await quick.trackTransaction(
        transactionId: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        periodicTimeOut: const Duration(milliseconds: 10),
      );

      final never = _quick(
        (p) => _ok(p, {'txs': []}),
      );
      expect(
        () => never.trackTransaction(
          transactionId: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          timeout: const Duration(milliseconds: 50),
          periodicTimeOut: const Duration(milliseconds: 10),
        ),
        throwsA(isA<BuError>()),
      );
    });

    test('getTransactionStatus maps states', () async {
      final block = _quick(
        (p) => _ok(p, {
          'txs': [_txJson(txHash: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', confirmations: 3)],
        }),
      );
      expect(
        await block.getTransactionStatus('cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'),
        MoneroTxStatus.block,
      );

      final pending = _quick(
        (p) => _ok(p, {
          'txs': [_txJson(txHash: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', inPool: true)],
        }),
      );
      expect(
        await pending.getTransactionStatus('cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'),
        MoneroTxStatus.pending,
      );

      final failed = _quick(
        (p) => _ok(p, {
          'txs': [_txJson(txHash: 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', doubleSpend: true)],
        }),
      );
      expect(
        await failed.getTransactionStatus('cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'),
        MoneroTxStatus.failed,
      );

      final missing = _quick((p) => _ok(p, {'txs': []}));
      expect(
        await missing.getTransactionStatus('cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'),
        MoneroTxStatus.unknown,
      );
    });
  });
}

void main() {
  MoneroTestApi.runTest(moneroQuickClientApiTest, 'Monero Quick Client Api');
}
