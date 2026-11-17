// Monero regtest: 2-of-3 multisig (key exchange, fund, co-sign a spend).

import 'package:example/examples/local/monero_node.dart';
import 'package:monero_dart/monero_dart.dart';

/// Participants: any two of these three can spend.
const int threshold = 2;

/// Paid to each multisig subaddress, in XMR.
const String fundAmount = '5';

/// Sent out of the multisig account, in XMR.
const String spendAmount = '3';

Future<void> main() async {
  final net = await MoneroRegtest.connect();

  print('Monero regtest: 2-of-3 multisig');
  print(field('node', moneroRegtestUrl));
  print('');

  /// ---- 1. key exchange -------------------------------------------------
  final wallets = [for (var i = 0; i < 3; i++) moneroAccount(20 + i)];
  final accounts = wallets
      .map(
        (e) => MoneroMultisigAccount.initialize(
          privateSpendKey: e.privSkey!,
          privateViewKey: e.privVkey,
        ),
      )
      .toList();

  print('participants');
  for (var i = 0; i < wallets.length; i++) {
    final address = MoneroAccountKeys(
      account: wallets[i],
      network: MoneroNetwork.mainnet,
    ).primaryAddress();
    print(field('  participant $i', address.address));
  }
  print('');

  var messages =
      accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
  final signers = messages.map((e) => e.signingPubKey).toList();
  for (final account in accounts) {
    account.initializeKex(threshold, signers, messages);
  }
  var round = 1;
  while (!accounts.every((e) => e.multisigIsReady)) {
    messages = accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
    for (final account in accounts) {
      account.kexUpdate(messages);
    }
    round++;
    if (round > 10) throw StateError('key exchange did not converge');
  }

  final addresses = accounts
      .map((e) => e.toAddress(network: MoneroNetwork.mainnet).address)
      .toSet();
  if (addresses.length != 1) {
    throw StateError('participants derived different addresses');
  }
  print(field('kex rounds', '$round'));
  print(field('multisig address', addresses.single));
  print('');

  final keys = accounts
      .map(
        (e) => MoneroMultisigAccountKeys(
          multisigAccount: e,
          indexes: const [MoneroSubIndex.primary, MoneroSubIndex.minor1],
          network: MoneroNetwork.mainnet,
        ),
      )
      .toList();
  final primary = keys[0].primaryAddress();
  final sub1 = keys[0].subAddress(const MoneroSubIndex.unsafe(minor: 1));
  print(field('primary', primary.address));
  print(field('subaddress 1/0', sub1.address));
  print('');

  /// ---- 2. fund ---------------------------------------------------------
  await net.ensureHeight();
  final treasury = moneroAccountKeys(
    23,
    indexes: const [MoneroSubIndex.primary],
  );
  final treasuryFrom = await net.fund(treasury.primaryAddress().address);
  var treasuryOuts = await net.scanOutputs(treasury, from: treasuryFrom);
  if (treasuryOuts.length < 2) {
    throw StateError('treasury has no spendable outputs');
  }
  print('funding the multisig address from a normal account');
  print(field('treasury', treasury.primaryAddress().address));

  final fundTx = await net.buildTransfer(
    account: treasury,
    payments: treasuryOuts.take(2).toList(),
    destinations: [
      MoneroTxDestination.fromXMR(amount: fundAmount, address: primary),
      MoneroTxDestination.fromXMR(amount: fundAmount, address: sub1),
    ],
    change: treasury.primaryAddress(),
  );
  print(field('amount', '$fundAmount XMR to each subaddress'));
  print(field('fee', '${fundTx.feeAsXMR} XMR'));
  final fundHash = await net.sendAndWait(fundTx.getFinalTx());
  print(field('tx', fundHash));
  await net.confirm(blocks: 12);
  print(field('confirmed', 'yes'));
  print('');

  /// ---- 3. scan with the multisig view key -------------------------------
  final from = treasuryFrom;
  final multisigOuts = await net.scanOutputs(keys[0], from: from);
  final primaryOuts =
      multisigOuts.where((e) => !e.output.accountIndex.isSubaddress).toList();
  final subOuts =
      multisigOuts.where((e) => e.output.accountIndex.isSubaddress).toList();
  print('outputs the multisig account can spend');
  print(field('primary', '${primaryOuts.length}'));
  print(field('subaddress 1/0', '${subOuts.length}'));
  for (final out in [...primaryOuts, ...subOuts]) {
    print(
      field(
        '  ${out.output.accountIndex.minor}/0',
        '${formatXmr(out.output.amount)} XMR  index ${out.globalIndex}',
      ),
    );
  }
  print('');

  /// ---- 4. spend --------------------------------------------------------
  ///
  /// 2-of-3: the creator builds the transaction, then one of the other two
  /// participants signs it. The two co-signers exchange multisig info (partial
  /// key images plus the nonces that go with it); the creator must not supply
  /// its own info.
  const creator = 0;
  const coSigner = 1;
  final recipient =
      moneroAccountKeys(24, indexes: const [MoneroSubIndex.primary]);
  final recipientAddress = recipient.primaryAddress();

  /// The co-signer exports its info for the output the creator will spend.
  final coInfo = multisigOuts
      .map((e) => keys[coSigner].multisigAccount.generateMultisigInfo(e.output))
      .toList();

  final spendPayments = await net.api.unlockMultisigPayments(
    account: keys[creator],
    payments: List.generate(
      multisigOuts.length,
      (i) => UnlockMultisigOutputRequest(
        payment: multisigOuts[i],
        multisigInfos: [coInfo[i].info],
      ),
    ),
    cleanUpSpent: true,
  );
  final spendable =
      spendPayments.where((e) => e.output.amount > BigInt.zero).toList();
  if (spendable.isEmpty) {
    throw StateError('no spendable multisig outputs');
  }

  final spendTx = await net.api.createMultisigTransfer(
    account: keys[creator],
    payments: spendable,
    destinations: [
      MoneroTxDestination.fromXMR(
          amount: spendAmount, address: recipientAddress),
    ],
    changeAddress: keys[creator].primaryAddress(),
    signers: [coInfo[0].info.signer],
  );
  print('spending from the multisig account');
  print(field('creator', 'participant $creator'));
  print(field('co-signer', 'participant $coSigner'));
  print(field('destination', recipientAddress.address));
  print(field('amount', '$spendAmount XMR'));
  print(field('fee', '${spendTx.feeAsXMR} XMR'));
  print(field('inputs', '${spendTx.totalInputAsXMR} XMR'));
  print(field('outputs', '${spendTx.totalOutputAsXMR} XMR'));

  /// The co-signer adds the second partial signature; the nonces must match
  /// the ones the co-signer exported in [coInfo].
  spendTx.sign(
    account: keys[coSigner],
    multisigNonces: coInfo.expand((e) => e.nonces).toList(),
  );
  if (!spendTx.isReady) {
    throw StateError('transaction is still missing signatures');
  }

  final spendHash = await net.sendAndWait(spendTx.getFinalTx());
  print(field('tx', spendHash));
  await net.confirm(blocks: 12);
  print(field('confirmed', 'yes'));
  print('');

  /// The recipient account sees the payment on its own.
  final recipientOuts = await net.scanOutputs(recipient, from: treasuryFrom);
  final recipientDelta = recipientOuts.fold<BigInt>(
    BigInt.zero,
    (p, c) => p + c.output.amount,
  );
  print('recipient account');
  print(field('outputs', '${recipientOuts.length}'));
  print(field('received', '${formatXmr(recipientDelta)} XMR'));
  print('');

  net.close();
  print('');
  print('done.');
}
