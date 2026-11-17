// Shared plumbing for the Monero regtest examples (local offline daemon on 127.0.0.1:18081).
//
// Everything here is test scaffolding: deterministic accounts, a faucet that
// mines coinbase, and a scanner that turns blocks into spendable outputs. The
// examples themselves only use the public `monero_dart` API.

import 'dart:convert';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:http/http.dart' as http;
import 'package:monero_dart/monero_dart.dart';

/// Daemon JSON-RPC endpoint of the local regtest node.
const String moneroRegtestUrl = 'http://127.0.0.1:18081';

/// Stable throwaway coinbase target used to grow the chain (and to mature
/// outputs). Its rewards are never spent.
const String moneroMinerAddress =
    '42WknUBnfAqVH1h4hdmN1cLtNY9cmNHMdNizH2zVrbR3cPyLq7UBW9f1kWu8r6cUHbTo5LAXpCAGnj8v3yZQRxMMMiEbQzx';

/// Coinbase outputs need this many confirmations before they can be spent.
const int coinbaseMaturity = 60;

/// Number of blocks minted to a fresh account before it is considered funded.
const int fundingBlocks = 70;

/// The examples assume a chain of at least this height before they spend.
///
/// Ring decoys are picked from the chain's RingCT outputs with a gamma
/// distribution. On a chain that is only a few hundred blocks tall most draws
/// overshoot the tip and the transfer fails with "No RCT values found in the
/// range". 1000 blocks is comfortably past that.
const int minChainHeight = 1000;

/// Minimal HTTP service provider for [MoneroProvider].
class MoneroHttpService with MoneroServiceProvider {
  MoneroHttpService({http.Client? client, this.url = moneroRegtestUrl})
      : client = client ?? http.Client();

  final http.Client client;
  final String url;

  @override
  Future<BaseServiceResponse> doRequest(
    MoneroRequestDetails params, {
    Duration? timeout,
  }) async {
    final limit = timeout ?? const Duration(seconds: 90);

    /// A local daemon under load occasionally drops a connection; retrying the
    /// same request is safe for every method the examples use.
    for (var attempt = 0;; attempt++) {
      try {
        final response = await client
            .post(
              params.encodeUrl(url),
              headers: params.headers,
              body: params.encodeBody(),
            )
            .timeout(limit);
        return params.toResponse(
          response.bodyBytes,
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (attempt >= 2) rethrow;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
}

/// A live connection to the regtest daemon plus the helpers the examples use.
class MoneroRegtest {
  MoneroRegtest._(this.provider, this.api, this._client);

  final MoneroProvider<MoneroHttpService> provider;
  final MoneroApi api;
  final http.Client _client;

  static Future<MoneroRegtest> connect({String url = moneroRegtestUrl}) async {
    final service = MoneroHttpService(url: url);
    final provider = MoneroProvider<MoneroHttpService>(service);
    final regtest =
        MoneroRegtest._(provider, MoneroApi(provider), service.client);
    await regtest.checkNode();
    return regtest;
  }

  void close() => _client.close();

  /// Fails early with a readable message when the daemon is not reachable.
  Future<void> checkNode() async {
    final info = await provider.request(const DaemonRequestGetInfo());
    if (!info.offline) {
      throw StateError(
        'expected the offline regtest daemon on $url, '
        'but the node reports height ${info.height} and is not offline',
      );
    }
  }

  Future<int> height() async {
    final info = await provider.request(const DaemonRequestGetHeight());
    return info.height;
  }

  /// Mines [blocks] coinbase to [address] and returns the new chain height.
  Future<int> mine(String address, int blocks) async {
    var remaining = blocks;
    while (remaining > 0) {
      final chunk = remaining > 200 ? 200 : remaining;
      await provider.request(
        DaemonRequestGenerateBlocks(
          amountOfBlocks: chunk,
          walletAddress: address,
          prevBlock: '',
          startingNonce: 0,
        ),
      );
      remaining -= chunk;
    }
    return height();
  }

  String get url => moneroRegtestUrl;

  /// Mines to the throwaway address until the chain is [minimum] blocks tall.
  Future<void> ensureHeight([int minimum = minChainHeight]) async {
    final current = await height();
    if (current >= minimum) return;
    await mine(moneroMinerAddress, minimum - current);
  }

  /// Funds [address] with coinbase and waits for it to mature.
  ///
  /// Mining to a subaddress is rejected by the daemon ("Mining to subaddress is
  /// not supported yet"), so subaddresses are funded by a transfer from a
  /// primary address instead.
  Future<int> fund(String address, {int blocks = fundingBlocks}) async {
    final from = await height();
    await mine(address, blocks);

    /// Coinbase outputs only become spendable after [coinbaseMaturity]
    /// confirmations, so the funding blocks are followed by empty ones.
    await mine(moneroMinerAddress, coinbaseMaturity);
    return from;
  }

  /// All unspent outputs [account] can spend, found by scanning from [from].
  ///
  /// The account may be a simple account or a multisig account; the view key
  /// is all that is needed to recognise outputs.
  Future<List<MoneroUnLockedPayment>> scanOutputs(
    MoneroBaseAccountKeys account, {
    required int from,
  }) async {
    final payments = <MoneroUnLockedPayment>[];
    var start = from;
    while (true) {
      /// `get_height` is the height of the next block, so a start height equal
      /// to it addresses a block that does not exist yet.
      final tip = await height();
      if (start >= tip) break;
      final blocks = await api.getBlocks(
        startHeight: start,
        prune: false,
      );
      if (blocks.blocks.isEmpty) break;
      for (var b = 0; b < blocks.blocks.length; b++) {
        final entry = blocks.blocks[b];
        final block = entry.toBlock();
        final txes = entry.txs.map((e) => e.toTx()).toList();
        final indices = blocks.outputIndices[b].indices;
        final all = [block.minerTx, ...txes];
        for (var i = 0; i < all.length; i++) {
          payments.addAll(
            await api.unlockTransactionsPayments(
              transactions: [
                MoneroTransactionWithOutputIndeces(
                  transaction: all[i],
                  outputIndices: indices[i].indices,
                ),
              ],
              account: account,
            ),
          );
        }
      }
      start = blocks.startHeight + blocks.blocks.length;
      if (blocks.blocks.isEmpty) break;

      /// `getblocks.bin` returns everything up to the tip, so a short response
      /// means we are done.
      if (start >= tip) break;
    }
    return api.cleanUpSpent(payments);
  }

  /// Total of [payments] in atomic units.
  static BigInt total(List<MoneroUnLockedPayment> payments) =>
      payments.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);

  /// Builds a transfer from [payments] to [destinations] with change going back
  /// to [change], and returns the signed transaction.
  Future<MoneroRctTxBuilder> buildTransfer({
    required MoneroAccountKeys account,
    required List<MoneroUnLockedPayment> payments,
    required List<MoneroTxDestination> destinations,
    required MoneroAddress change,
  }) {
    return api.createTransfer(
      account: account,
      payments: payments,
      destinations: destinations,
      changeAddress: change,
    );
  }

  /// Submits [tx] and waits until it is in a block.
  ///
  /// Monero has no automining: a transaction stays in the pool until a block is
  /// produced. The regtest daemon mines on demand, so this submits, mines one
  /// block, and polls until the daemon reports the transaction as confirmed.
  Future<String> sendAndWait(
    MoneroTransaction tx, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final hash = tx.getTxHash();
    try {
      await api.sendRawTransaction(tx.serializeHex());
    } catch (e) {
      // ignore: avoid_print
      print('send failed: $e');
      rethrow;
    }
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final status = await api.getTransactionStatus(hash);
      switch (status) {
        case MoneroTxStatus.block:
          return hash;
        case MoneroTxStatus.failed:
          throw StateError('transaction $hash double-spent');
        case MoneroTxStatus.unknown:
        case MoneroTxStatus.pending:
      }
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('transaction $hash was not mined in time');
      }
      await mine(moneroMinerAddress, 1);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Mines a few blocks so a freshly mined transaction gains confirmations.
  Future<void> confirm({int blocks = 2}) => mine(moneroMinerAddress, blocks);
}

/// Deterministic account for [index].
///
/// The seed is `sha256("monero_dart/example", index)`; the spend key is the
/// account's private spend key derived from it, so the same index always gives
/// the same address on every run.
MoneroAccount moneroAccount(int index) {
  final seed = QuickCrypto.sha256Hash([
    ...'monero_dart/example'.codeUnits,
    ...utf8.encode(':$index'),
  ]);
  return MoneroAccount.fromSeed(
    seed,
    coinType: MoneroCoins.moneroMainnet,
  );
}

/// Deterministic account keys with [indexes] active.
MoneroAccountKeys moneroAccountKeys(
  int index, {
  List<MoneroSubIndex>? indexes,
}) {
  return MoneroAccountKeys(
    account: moneroAccount(index),
    indexes: indexes ??
        [
          MoneroSubIndex.primary,
          MoneroSubIndex.minor1,
          MoneroSubIndex(major: 0, minor: 2),
        ],
    network: MoneroNetwork.mainnet,
  );
}

/// Formats an amount in atomic units as an XMR string.
String formatXmr(BigInt piconero) => MoneroTransactionHelper.toXMR(piconero);

/// Formats a signed amount change.
String formatSigned(BigInt delta) {
  final sign = delta.isNegative ? '-' : '+';
  return '$sign${formatXmr(delta.abs())}';
}

/// Prints a two-column `name : value` line.
String field(String name, String value) {
  return '  ${name.padRight(20)} $value';
}
