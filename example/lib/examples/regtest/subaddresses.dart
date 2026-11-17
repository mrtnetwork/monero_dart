// Monero regtest: one account, several subaddresses (fund, read back, spend).

import 'package:example/examples/local/monero_node.dart';
import 'package:monero_dart/monero_dart.dart';

/// Paid to each subaddress, in XMR.
const String subaddressAmount = '5';

/// Sent out of the subaddresses, in XMR.
const String spendAmount = '3';

void main() async {
  final net = await MoneroRegtest.connect();

  final alice = moneroAccountKeys(
    10,
    indexes: [
      MoneroSubIndex.primary,
      MoneroSubIndex.minor1,
      MoneroSubIndex(major: 0, minor: 2),
    ],
  );

  /// The receiver is a separate account with its own keys.
  final bob = moneroAccountKeys(11, indexes: const [MoneroSubIndex.primary]);

  final sub1 = alice.subAddress(const MoneroSubIndex.unsafe(minor: 1));
  final sub2 = alice.subAddress(const MoneroSubIndex.unsafe(minor: 2));

  print('Monero regtest: subaddresses');
  print(field('node', moneroRegtestUrl));
  print(field('alice primary', alice.primaryAddress().address));
  print(field('alice 1/0', sub1.address));
  print(field('alice 2/0', sub2.address));
  print(field('bob', bob.primaryAddress().address));
  print('');

  await net.ensureHeight();
  final bobFrom = await net.height();
  final aliceFrom = await net.fund(alice.primaryAddress().address);
  print(
    field(
      'alice funded',
      '${formatXmr(MoneroRegtest.total(await net.scanOutputs(alice, from: aliceFrom)))} XMR',
    ),
  );

  /// ---- 1. pay the subaddresses ----------------------------------------
  final payments = await net.scanOutputs(alice, from: aliceFrom);
  final inputs = payments.take(2).toList();

  print('');
  print('paying the subaddresses from the primary address');
  print(field('inputs', '${inputs.length} coinbase outputs'));
  print(field('input total', '${formatXmr(MoneroRegtest.total(inputs))} XMR'));

  final builder = await net.buildTransfer(
    account: alice,
    payments: inputs,
    destinations: [
      MoneroTxDestination.fromXMR(amount: subaddressAmount, address: sub1),
      MoneroTxDestination.fromXMR(amount: subaddressAmount, address: sub2),
    ],
    change: alice.primaryAddress(),
  );
  print(field('fee', '${builder.feeAsXMR} XMR'));
  print(field('output total', '${builder.totalOutputAsXMR} XMR'));
  print(field('change', '${builder.change?.amountAsXMR} XMR'));
  final hash = await net.sendAndWait(builder.getFinalTx());
  print(field('tx', hash));

  /// An output can only be spent after 10 confirmations, so the subaddress
  /// outputs are left to settle before the next step.
  await net.confirm(blocks: 12);
  print(field('confirmed', 'yes'));
  print('');

  /// ---- 2. read the subaddress outputs back ----------------------------
  final after = await net.scanOutputs(alice, from: aliceFrom);
  final sub1Outs = after
      .where(
          (e) => e.output.accountIndex == const MoneroSubIndex.unsafe(minor: 1))
      .toList();
  final sub2Outs = after
      .where(
          (e) => e.output.accountIndex == const MoneroSubIndex.unsafe(minor: 2))
      .toList();
  print('outputs the account can spend');
  print(field('primary',
      '${after.where((e) => !e.output.accountIndex.isSubaddress).length}'));
  print(field('subaddress 1/0', '${sub1Outs.length}'));
  print(field('subaddress 2/0', '${sub2Outs.length}'));
  for (final out in [...sub1Outs, ...sub2Outs]) {
    print(
      field(
        '  ${out.output.accountIndex.minor}/0',
        '${formatXmr(out.output.amount)} XMR  index ${out.globalIndex}',
      ),
    );
  }
  print('');

  /// ---- 3. spend from both subaddresses at once ------------------------
  final aliceBefore = MoneroRegtest.total(after);
  final bobBefore = MoneroRegtest.total(
    await net.scanOutputs(bob, from: bobFrom),
  );

  print('spending from both subaddresses in one transaction');
  final spend = await net.buildTransfer(
    account: alice,
    payments: [sub1Outs.first, sub2Outs.first],
    destinations: [
      MoneroTxDestination.fromXMR(
        amount: spendAmount,
        address: bob.primaryAddress(),
      ),
    ],
    change: alice.primaryAddress(),
  );
  print(field('fee', '${spend.feeAsXMR} XMR'));
  print(field('input total', '${spend.totalInputAsXMR} XMR'));
  print(field('output total', '${spend.totalOutputAsXMR} XMR'));
  final spendHash = await net.sendAndWait(spend.getFinalTx());
  print(field('tx', spendHash));
  await net.confirm();

  final aliceAfter = MoneroRegtest.total(
    await net.scanOutputs(alice, from: aliceFrom),
  );
  final bobAfter = MoneroRegtest.total(
    await net.scanOutputs(bob, from: bobFrom),
  );
  print(field('alice change', formatSigned(aliceAfter - aliceBefore)));
  print(field('bob received', formatSigned(bobAfter - bobBefore)));

  net.close();
  print('');
  print('done.');
}
