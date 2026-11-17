// Monero regtest: read an account's UTXOs with the block processor.

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/examples/local/monero_node.dart';
import 'package:monero_dart/monero_dart.dart';

void main() async {
  final net = await MoneroRegtest.connect();

  print('Monero regtest: block processor');
  print(field('node', moneroRegtestUrl));
  print(field('chain height', '${await net.height()}'));
  print('');

  final account = moneroAccountKeys(
    5,
    indexes: const [MoneroSubIndex.primary],
  );
  print(field('account', account.primaryAddress().address));
  print('');

  await net.ensureHeight();

  /// A short funding window keeps the scan quick: `scanBlock` re-requests the
  /// range from the daemon for every block, so scanning a few hundred blocks is
  /// noticeably slower than scanning a handful.
  const mined = 12;
  final from = await net.fund(account.primaryAddress().address, blocks: mined);
  final fundedTo = from + mined - 1;
  print(field('mined', '$mined blocks ($from..$fundedTo)'));
  print(field('chain height', '${await net.height()}'));
  print('');

  /// The unlocker is what recognises outputs; the processor calls it once per
  /// block with every transaction of that block.
  final processor = DefaultMoneroBlockProcessor(
    provider: net.provider,
    config: BlockProcessorConfig(
      network: MoneroNetwork.mainnet,
      unlocker: DefaultMoneroOutputUnlocker(accounts: [account]),
    ),
  );

  var total = BigInt.zero;
  var outputs = 0;
  var blocksWithFunds = 0;
  final seen = <BigInt>{};

  await for (final block in processor.scanBlock(from, fundedTo)) {
    final found = block.unlockedOutputs();
    if (found.isEmpty) continue;
    blocksWithFunds++;
    print(
        'block ${block.blockHeight}  ${block.txes.length} tx  ${found.length} output');
    for (final out in found) {
      outputs++;
      total += out.output.amount;
      seen.add(out.globalIndex);
      print(
        field(
          '  output',
          '${formatXmr(out.output.amount)} XMR  index ${out.globalIndex}  '
              '${out.output.coinbase ? 'coinbase' : 'transfer'}  '
              'key ${BytesUtils.toHexString(out.output.outputPublicKey).substring(0, 16)}…',
        ),
      );
    }
  }

  print('');
  print(field('blocks scanned', '${fundedTo - from + 1}'));
  print(field('blocks with funds', '$blocksWithFunds'));
  print(field('outputs', '$outputs'));
  print(field('total', '${formatXmr(total)} XMR'));

  /// The same scan can be repeated for several accounts at once: the unlocker
  /// reports which account each output belongs to.
  final other = moneroAccountKeys(6, indexes: const [MoneroSubIndex.primary]);
  final shared = DefaultMoneroBlockProcessor(
    provider: net.provider,
    config: BlockProcessorConfig(
      network: MoneroNetwork.mainnet,
      unlocker: DefaultMoneroOutputUnlocker(accounts: [account, other]),
    ),
  );
  var otherTotal = BigInt.zero;
  await for (final block in shared.scanBlock(from, fundedTo)) {
    for (final out in block.unlockedOutputs()) {
      if (out.account.account == other.account) {
        otherTotal += out.output.amount;
      }
    }
  }
  print('');
  print(field('other account', other.primaryAddress().address));
  print(field('other total', '${formatXmr(otherTotal)} XMR'));

  net.close();
  print('');
  print('done.');
}
