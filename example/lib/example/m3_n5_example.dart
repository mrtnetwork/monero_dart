// ignore_for_file: avoid_print, unused_local_variable

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/example/provider_example.dart';
import 'package:monero_dart/monero_dart.dart';

Future<List<MoneroMultisigInfo>> getMultisigInfo(
    {required MoneroMultisigAccountKeys account,
    required MoneroApi api,
    required List<String> txHashes}) async {
  final List<MoneroUnLockedPayment> outs =
      await api.unlockTxHashesPayments(txHashes: txHashes, account: account);
  return outs.map((e) {
    return account.multisigAccount.generateMultisigInfo(e.output);
  }).toList();
}

void main() async {
  final provider = createProvider();

  /// create 3/5 multisig account.
  final accounts = createMultisigAccountsM3N5();

  /// pick account 1
  final MoneroMultisigAccountKeys myAccount = accounts[0];
  final api = MoneroApi(provider);

  /// pick UTXO.
  const List<String> txhashes = [
    "929e7286d568f79dbdc90e9041620b137895953d4723436f2c4e3a40a4a408a4",
    "f3686393b98d718e01aaf1569458d0f4fa0a92baddd76058b833a48199212293",
    "566fcafb81a260f5206f040251eb2136f926d3bc29abbda2df5d18e7f499fda4",
    "f15819aaaaff96d4250bd94549d1a154337bd711a1adf32a4468023fa25618e0",
    "f1c6f6da3972e4e2d31079fe7377d34e71eabcbcd24a989d9bf77b8b9eda8b24",
    "c325e446d0d1007583d2d893a449b75f6588aab520922137cca6da8091719886",
    "0102eb7ce7da72b459a084dd6e4bc9bf826a63f4b23775594ecfa386f8e65bb4",
    "8e28553ae3e7d25ccb3ad421742296e3b041b4c75842bad6f031e0875ba7f145",
    "8fa7103499d315dcbcc3eb9de7228fcb9779e62c0352544f67fda9d4756907cd"
  ];

  /// Each account create multisig info and partial key images for each output
  /// in this key when creating multisig info we have some random nonces and we need this for signing transaction.
  List<MoneroMultisigInfo> signer1Info =
      await getMultisigInfo(account: accounts[1], api: api, txHashes: txhashes);
  List<MoneroMultisigInfo> signer2Info =
      await getMultisigInfo(account: accounts[2], api: api, txHashes: txhashes);

  /// transaction creator generate unlocked payments for create transaction
  final List<MoneroUnLockedPayment> outs =
      await api.unlockTxHashesPayments(txHashes: txhashes, account: myAccount);

  /// now we need the other multisig output info to generate multisig key image
  final multisigInfos = List.generate(
      outs.length,
      (o) => UnlockMultisigOutputRequest(
          payment: outs[o],
          multisigInfos: [signer1Info[o].info, signer2Info[o].info]));

  /// convert the unlocked payment to multisig unlocked paymet
  /// and now we have multisig key image
  List<MoneroUnlockedMultisigPayment> multisigPayments =
      await api.unlockMultisigPayments(
    account: myAccount,
    payments: multisigInfos,

    /// remove all spent key Images.
    cleanUpSpent: true,
  );
  final total =
      multisigPayments.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
  if (total <= BigInt.zero) return;

  /// ok we create multisig tx.
  MoneroMultisigTxBuilder tx = await api.createMultisigTransfer(
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

    /// we pick account signers thats give me a multisig outputs info
    signers: [signer1Info[0].info.signer, signer2Info[0].info.signer],
  );

  /// we check inputs of tx
  print("tx fee: ${tx.feeAsXMR}");
  print("total input: ${tx.totalInputAsXMR}");
  print("total output: ${tx.totalOutputAsXMR}");
  print("change address: ${tx.change?.address}");
  print("change amount: ${tx.change?.amountAsXMR}");

  /// debuging (check tx builder serialization, keep us a correct tx builder)
  String hex = tx.serializeHex();
  tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
  assert(tx.serializeHex() == hex);

  /// now we sign the tx with account 2.
  tx.sign(
    account: accounts[1],

    /// account 2 porvides nonces when create multisig info
    multisigNonces: signer1Info.map((e) => e.nonces).expand((e) => e).toList(),
  );

  /// debuging (check tx builder serialization, keep us a correct tx builder)
  hex = tx.serializeHex();
  tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
  assert(tx.serializeHex() == hex);

  /// now we sign the tx with account 3.
  tx.sign(
      account: accounts[2],

      /// account 3 porvides nonces when create multisig info
      multisigNonces:
          signer2Info.map((e) => e.nonces).expand((e) => e).toList());

  /// debuging (check tx builder serialization, keep us a correct tx builder)
  hex = tx.serializeHex();
  tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
  assert(tx.serializeHex() == hex);
  assert(tx.isReady);

  /// now the transaction 3/5 is ready we create with account 1 and sign with accounts 2,3

  /// get the final transaction
  final finalTx = tx.getFinalTx();
  print(finalTx.getTxHash());

  /// send to the network.
  await api.provider.sendTx(finalTx);
  final receiver = MoneroAddress(
      "51yw3EafPkXS6gwhJGGvNn7DzPEEGrgfeJZBvAFjzu8w252Zr1nx4PfVdXi4e6kiiQMBJ8k4JCFby2pANTAjofbo2rWBpbx");

  /// generate proof for some receiver
  final proof = tx.generateProofVar(
      receiverAddress: receiver, message: "everything you want.");

  /// https://stagenet.xmrchain.net/search?value=46d5655a4848436e4694c23d69b481abafefbc9c9aa8aa0a0d1fd0336cd579e4
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

List<MoneroMultisigAccountKeys> createMultisigAccountsM3N5() {
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
