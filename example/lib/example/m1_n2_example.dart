// ignore_for_file: avoid_print

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/example/provider_example.dart';
import 'package:monero_dart/monero_dart.dart';

void main() async {
  final provider = createProvider();
  final accounts = createMultisigAccountsM1N2();
  final api = MoneroApi(provider);

  final MoneroMultisigAccountKeys myAccount = accounts[0];
  final List<MoneroUnLockedPayment> outs = await api.unlockTxHashesPayments(
      txHashes: [
        "38f76f09d7ab711827171f3f8d02f8f5422c56adf29611352d87b114fad136f7"
      ],
      account: myAccount);

  final multisigInfos = outs
      .map((a) => UnlockMultisigOutputRequest(
            payment: a,

            /// we dont need multisig infos.
            multisigInfos: [],
          ))
      .toList();
  final multisigPayments = await api.unlockMultisigPayments(
      account: myAccount, payments: multisigInfos, cleanUpSpent: true);
  final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
  if (total <= BigInt.zero) return;
  final builder = await api.createMultisigTransfer(
      account: myAccount,
      payments: multisigPayments,
      destinations: [
        MoneroTxDestination.fromXMR(
            amount: "0.001",
            address: MoneroAddress(
                "72wPFyWbpgxStTLKy8eeXsawUuD7SAXBMT526pSbzrn91vn35qFgBngisd4sCf7XMhSfKv74kcViS7Jeeu7TE464KixVTHo")),
        MoneroTxDestination.fromXMR(
            amount: "0.001",
            address: MoneroAddress(
                "76dZbjNCQeVaQVeCq9y6H4dZ5wZqA9NY7WSnjjNUYzz5aht9rd3Qro57SSaN2eerE1aHkS9qvw5iscx3JrAT87bL8FiJ1Ye")),
        MoneroTxDestination.fromXMR(
            amount: "0.001",
            address: MoneroAddress(
                "51yw3EafPkXS6gwhJGGvNn7DzPEEGrgfeJZBvAFjzu8w252Zr1nx4PfVdXi4e6kiiQMBJ8k4JCFby2pANTAjofbo2rWBpbx")),
      ],
      changeAddress: myAccount.primaryAddress(),

      /// we don't need singer, key image of account 1 is enough
      signers: []);

  /// we check inputs of tx
  print("tx fee: ${builder.feeAsXMR}");
  print("total input: ${builder.totalInputAsXMR}");
  print("total output: ${builder.totalOutputAsXMR}");
  print("change address: ${builder.change?.address}");
  print("change amount: ${builder.change?.amountAsXMR}");

  final finalTx = builder.getFinalTx();
  await api.provider.sendTx(finalTx);

  /// https://stagenet.xmrchain.net/search?value=bebefc3fad09d2ef52969a8e347248dc6178f3cb135a936e1a2822fc47d387d9
}

MoneroAccount acc4() {
  const mnemonic =
      "pause mobile lottery smidgen inflamed hacksaw being sighting bested purged keyboard upkeep punch until stick owner vastness aztec hockey jeers moat moment business wounded keyboard";
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
  return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
}

MoneroAccount acc5() {
  const mnemonic =
      "reheat cuddled gawk limits sayings seventh truth pigment recipe edgy adrenalin fall vampire last elapse shyness exhale ghetto roped hotel bemused nestle scuba southern exhale";
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
  return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
}

List<MoneroMultisigAccountKeys> createMultisigAccountsM1N2() {
  /// threshhold 1
  const int threshold = 1;

  /// accounts 2
  final List<MoneroAccount> wallets = [acc5(), acc4()];

  /// then we have 1/2 multisig account.
  /// 1 signer requirment for building tx

  /// initialize multisig account for each wallet
  final List<MoneroMultisigAccount> accounts = wallets
      .map((e) => MoneroMultisigAccount.initialize(
          privateSpendKey: e.privateSpendKey, privateViewKey: e.privVkey))
      .toList();

  /// get each account next round kex message
  final messages =
      accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
  final signers = messages.map((e) => e.signingPubKey).toList();

  /// initializeKex for each account with all initialize message and threshhold
  for (final i in accounts) {
    i.initializeKex(threshold, signers, messages);
  }

  /// the we loop accounts to generate each round kex message and shared to other accounts.
  while (!accounts[0].multisigIsReady) {
    /// get all kex messages
    final messages =
        accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();

    /// update each account in current round.
    for (final i in accounts) {
      i.kexUpdate(messages);
    }

    /// now the accounts round updated and in next itration we have new kex round messages.
    /// we check all accounts has same round.
    for (int i = 1; i < accounts.length; i++) {
      assert(accounts[0].kexRoundsComplete == accounts[i].kexRoundsComplete);
    }
  }

  /// at the end we check everything
  assert(accounts[0].multisigIsReady);
  assert(accounts[0].threshold == threshold);
  for (int i = 1; i < accounts.length; i++) {
    assert(accounts[i].multisigIsReady);
    assert(accounts[i].threshold == threshold);
    assert(accounts[0].toAddress() == accounts[i].toAddress());
    assert(
        CompareUtils.iterableIsEqual(accounts[0].signers, accounts[i].signers));
  }

  return accounts
      .map((e) => MoneroMultisigAccountKeys(
          multisigAccount: e, network: MoneroNetwork.stagenet))
      .toList();
}
