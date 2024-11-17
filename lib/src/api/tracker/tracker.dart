import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/api/api.dart';
import 'package:monero_dart/src/api/models/models.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';

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
      print("current height $_currentHeight $_blockHeight");
      final r = await provider.getBlocks(startHeight: _currentHeight);
      final txes = r.toTxes();
      final keyImages = txes
          .map((e) => e.transaction.getInputsKeyImages())
          .expand((e) => e)
          .toList();
      print("txes ${txes.length}");
      for (final i in txes) {
        final unlock = api.unlockSingleOutput(
            transaction: i.transaction, account: _account);
        if (unlock.isNotEmpty) {
          outputs.addAll(unlock
              .map((e) => AccountTxOutputs(
                  transaction: i.transaction, txHash: i.txHash, output: e))
              .toList());
        }
      }
      _currentHeight += r.blocks.length;
      if (outputs.isNotEmpty) {
        outputs.removeWhere((e) => keyImages.contains(e.keyImage));
      }
      print("unlocked outs ${outputs.length}");
    }

    final total = outputs.map((e) => e.output.amount).toList();
    final txes = outputs.map((e) => e.txHash).toList();
    print("at the end $total");
    print(StringUtils.fromJson(txes));
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
