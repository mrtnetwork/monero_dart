import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

void main() {
  group("multisig", () {
    test("3/5", () {
      final addr = _createMultisigAccountsM3N5();
      expect(addr[0].primaryAddress().address,
          "56NApw2yuPPCSZR3eQDGdvJJ8QyDSLtJQeSma1p9oVbjiSxNmwQvameWUjB7KJtztYZZt6BVmVmLsWc4tbF5g2R5Q1yYWRL");
    });
    test("1/2", () {
      final addr = _createMultisigAccountsM1N2();
      expect(addr[0].primaryAddress().address,
          "5AoMqeai86EJh7YzQ9y9ZWHzSCR4QsbdtJidYq7PWxDjPWRKFoSdPXNQoK8r9Xo6PG33DScGPG4MiCrUtre6qMa8R9bSo8q");
    });
  });
}

List<MoneroMultisigAccountKeys> _createMultisigAccountsM1N2() {
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
      expect(accounts[0].kexRoundsComplete, accounts[i].kexRoundsComplete);
    }
  }

  /// at the end we check everything
  expect(accounts[0].multisigIsReady, true);
  expect(accounts[0].threshold, threshold);
  for (int i = 1; i < accounts.length; i++) {
    expect(accounts[i].multisigIsReady, true);
    expect(accounts[i].threshold, threshold);
    expect(accounts[0].toAddress(), accounts[i].toAddress());
    expect(
        CompareUtils.iterableIsEqual(accounts[0].signers, accounts[i].signers),
        true);
  }

  return accounts
      .map((e) => MoneroMultisigAccountKeys(
          multisigAccount: e, network: MoneroNetwork.stagenet))
      .toList();
}

List<MoneroMultisigAccountKeys> _createMultisigAccountsM3N5() {
  /// threshhold 3
  const int threshold = 3;

  /// accounts 5
  final List<MoneroAccount> wallets = [acc1(), acc2(), acc3(), acc4(), acc5()];

  /// then we have 3/5 multisig account.
  /// 3 signer requirment for building tx

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
  expect(accounts[0].multisigIsReady, true);
  expect(accounts[0].threshold, threshold);
  for (int i = 1; i < accounts.length; i++) {
    expect(accounts[i].multisigIsReady, true);
    expect(accounts[i].threshold, threshold);
    expect(accounts[0].toAddress(), accounts[i].toAddress());
    expect(
        CompareUtils.iterableIsEqual(accounts[0].signers, accounts[i].signers),
        true);
  }

  return accounts
      .map((e) => MoneroMultisigAccountKeys(
              multisigAccount: e,
              network: MoneroNetwork.stagenet,
              indexes: [
                MoneroAccountIndex.primary,
                MoneroAccountIndex.minor1,
                ...List.generate(15, (i) => MoneroAccountIndex(minor: i + 2))
              ]))
      .toList();
}

MoneroAccount acc3() {
  final mn = Mnemonic.fromString(
      "corrode dove tuesday voted geek using sizes bagpipe wildly muppet sushi opened ionic sober ravine slid obvious fictional obtains entrance rabbits usual beyond revamp sober");
  final seed = MoneroSeedGenerator(mn).generate();
  return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
}

MoneroAccount acc2() {
  final mn = Mnemonic.fromString(
      "fully nucleus meeting hefty cider shocking mocked rustled fancy wield atom lemon hairy estate last malady pedantic wobbly orphans ginger rover tyrant doctor pioneer hairy");
  final seed = MoneroSeedGenerator(mn).generate();
  return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
}

MoneroAccount acc1() {
  final mn = Mnemonic.fromString(
      "rumble avoid oncoming upbeat obvious cedar itself riots today guest enraged enjoy shackles smuggled kennel boil skirting voted elbow swagger zigzags solved negative hiding kennel");
  final seed = MoneroSeedGenerator(mn).generate();
  return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
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
