// ignore_for_file: unused_local_variable

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';

class MoneroChainAccountTracker {
  final MoneroBaseAccountKeys _account;
  final int startHeight;
  final MoneroApi api;
  QuickMoneroProvider get provider => api.provider;
  late int _currentHeight = startHeight;
  int _blockHeight = 0;
  List<AccountTxOutputs> outputs = [];
  MoneroChainAccountTracker._({
    required this.api,
    required this.startHeight,
    required MoneroBaseAccountKeys account,
  }) : _account = account;
  factory MoneroChainAccountTracker(
      {required MoneroApi api,
      required MoneroBaseAccountKeys account,
      required int startHeight}) {
    return MoneroChainAccountTracker._(
        api: api, account: account, startHeight: startHeight);
  }

  Future<void> updateLatestHeight() async {
    final latestHeight = await provider.currentHeight();
    _blockHeight = latestHeight.height;
  }

  Future<void> startFetchingHeight() async {
    await updateLatestHeight();
    while (_currentHeight < _blockHeight) {
      final r =
          await provider.getBlocks(startHeight: _currentHeight, blockIds: []);
      final f = r.blocks.first.toBlock().previousBlockHash();
      final l = r.blocks.last.toBlock().previousBlockHash();
      _currentHeight += r.blocks.length;
      final txes = r.toTxes();
      final keyImages = txes
          .map((e) => e.transaction.getInputsKeyImages())
          .expand((e) => e)
          .toList();
      for (final i in txes) {
        final unlock = api.unlockSingleTxOutputs(
            transaction: i.transaction, account: _account);
        if (unlock.isNotEmpty) {
          outputs.addAll(unlock
              .map((e) => AccountTxOutputs(
                  transaction: i.transaction, txHash: i.txHash, output: e))
              .toList());
        }
      }
      if (outputs.isNotEmpty) {
        outputs.removeWhere((e) => keyImages.contains(e.keyImage));
      }
    }

    final total = outputs.map((e) => e.output.amount).toList();
    final txes = outputs.map((e) => e.txHash).toSet();
  }
}

class AccountTxOutputs {
  final MoneroTransaction transaction;
  final String txHash;
  final MoneroOutput output;
  final String? keyImage;
  AccountTxOutputs(
      {required this.transaction, required this.txHash, required this.output})
      : keyImage = output.type == MoneroOutputType.locked
            ? null
            : BytesUtils.toHexString(
                output.cast<MoneroUnlockedOutput>().keyImage);
}
