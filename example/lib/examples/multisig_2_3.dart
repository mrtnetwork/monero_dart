// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:monero_dart/src/account/account.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/models/models.dart';
// import 'package:monero_dart/src/crypto/multisig/account/account.dart';
// import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
// import 'package:monero_dart/src/helper/transaction.dart';
// import 'package:monero_dart/src/network/network.dart';
// import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';
// import 'new_test.dart';

// void main() async {
//   final accounts = createMultisigAccounts();
//   final api = MoneroApi(QuickMoneroProvider(provider));
//   final MoneroMultisigAccountKeys myAccount = MoneroMultisigAccountKeys(
//       multisigAccount: accounts[0], network: MoneroNetwork.stagenet);
//   final List<MoneroUnLockedPayment> siger1Outs =
//       await api.unlockOutputs(txHashes: [
//     "f8dedeb30ac98b9c4f18152c81a44dbad28e6c8871a2efcaaa4d20922b6b0aa7",
//   ], account: MoneroMultisigAccountKeys(multisigAccount: accounts[1]));
//   final signer1MultisigInfo = siger1Outs
//       .map((e) => accounts[1].generateMultisigInfo(e.output))
//       .toList();

//   final List<MoneroUnLockedPayment> outs = await api.unlockOutputs(txHashes: [
//     "f8dedeb30ac98b9c4f18152c81a44dbad28e6c8871a2efcaaa4d20922b6b0aa7",
//   ], account: myAccount);
//   final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
//   print("total ${MoneroTransactionHelper.fromXMR(total)}");

//   // return;
//   final multisigInfos = List.generate(outs.length, (o) {
//     return UnlockMultisigOutputRequest(
//         payment: outs[o], multisigInfos: [signer1MultisigInfo[o].info]);
//   });
//   List<MoneroUnlockedMultisigPayment> multisigPayments =
//       api.unlockMultisigOutput(account: myAccount, payments: multisigInfos);
//   final keyImages =
//       multisigPayments.map((e) => BytesUtils.toHexString(e.keyImage)).toList();
//   // print("keyimages $")
//   final spent = await api.provider.keyImageSpends(keyImages);
//   final List<String> spents = [];
//   for (int i = 0; i < keyImages.length; i++) {
//     if (spent.spentStatus[i] != DaemonKeyImageSpentStatus.unspent) {
//       print("key image spent ${keyImages[i]}");
//       spents.add(keyImages[i]);
//       continue;
//     }
//   }
//   multisigPayments = multisigPayments
//       .where((e) => !spents.contains(BytesUtils.toHexString(e.keyImage)))
//       .toList();
//   // final n = myAccount.multisigAccount.signers
//   //     .firstWhere((e) => e != myAccount.multisigAccount.multisigSignerPubKey);
//   final tx = await api.createMultisigTransfer(
//       account: myAccount,
//       payments: multisigPayments,
//       destinations: [
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.1"),
//             address: myAcc1().subAddress(MoneroAccountIndex.minor1)),
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.1"),
//             address: receiver2().subAddress(MoneroAccountIndex.minor1)),
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.1"),
//             address: receiver3().subAddress(MoneroAccountIndex.minor1))
//       ],
//       changeAddress: myAccount.primaryAddress(),
//       signers: [signer1MultisigInfo[0].info.signer]);

//   tx.sign(
//       account: accounts[1],
//       multisigNonces:
//           signer1MultisigInfo.map((e) => e.nonces).expand((e) => e).toList());
//   final finalTx = tx.getFinalTx();
//   print(finalTx.getTxHash());
//   final txId = await api.provider.sendTx(finalTx);
//   print("done $txId");
// }

// MoneroAccount msig3() {
//   final mn = Mnemonic.fromString(
//       "corrode dove tuesday voted geek using sizes bagpipe wildly muppet sushi opened ionic sober ravine slid obvious fictional obtains entrance rabbits usual beyond revamp sober");
//   final seed = MoneroSeedGenerator(mn).generate();
//   return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
// }

// MoneroAccount msig2() {
//   final mn = Mnemonic.fromString(
//       "fully nucleus meeting hefty cider shocking mocked rustled fancy wield atom lemon hairy estate last malady pedantic wobbly orphans ginger rover tyrant doctor pioneer hairy");
//   final seed = MoneroSeedGenerator(mn).generate();
//   return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
// }

// MoneroAccount msig1() {
//   final mn = Mnemonic.fromString(
//       "rumble avoid oncoming upbeat obvious cedar itself riots today guest enraged enjoy shackles smuggled kennel boil skirting voted elbow swagger zigzags solved negative hiding kennel");
//   final seed = MoneroSeedGenerator(mn).generate();
//   return MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
// }

// MoneroAccount msig4() {
//   return receiver3().account;
// }

// MoneroAccount msig5() {
//   return receiver2().account;
// }

// List<MoneroMultisigAccount> createMultisigAccounts() {
//   final List<MoneroAccount> w = [msig1(), msig2(), msig3()];
//   final List<MultisigKexMessageSerializableRound1> kexMessage = [];
//   final List<MoneroMultisigAccount> accounts = [];
//   for (final account in w) {
//     final acc = getUninitializedMultisigAccount(account);
//     accounts.add(acc);
//     kexMessage.add(acc.nextRoundKexMessage.cast());
//   }

//   final messages =
//       accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
//   final signers = messages.map((e) => e.signingPubKey).toList();
//   for (final i in accounts) {
//     i.initializeKex(2, signers, messages);
//   }
//   while (!accounts[0].multisigIsReady) {
//     final messages =
//         accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
//     for (final i in accounts) {
//       i.kexUpdate(messages);
//     }
//   }
//   for (final i in accounts) {
//     assert(i.multisigIsReady);
//   }
//   return accounts;
// }

// /// 56NApw2yuPPCSZR3eQDGdvJJ8QyDSLtJQeSma1p9oVbjiSxNmwQvameWUjB7KJtztYZZt6BVmVmLsWc4tbF5g2R5Q1yYWRL
// List<MoneroMultisigAccount> createMultisigAccountsM3N5() {
//   /// 67b068dd54c9f131939262ea7f2df20b8b38986da6082e89b1a1d9bba872df12
//   final List<MoneroAccount> w = [msig1(), msig2(), msig3(), msig4(), msig5()];
//   final List<MultisigKexMessageSerializableRound1> kexMessage = [];
//   final List<MoneroMultisigAccount> accounts = [];
//   for (final account in w) {
//     final acc = getUninitializedMultisigAccount(account);
//     accounts.add(acc);
//     kexMessage.add(acc.nextRoundKexMessage.cast());
//   }

//   final messages =
//       accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
//   final signers = messages.map((e) => e.signingPubKey).toList();
//   for (final i in accounts) {
//     i.initializeKex(3, signers, messages);
//   }
//   while (!accounts[0].multisigIsReady) {
//     final messages =
//         accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
//     for (final i in accounts) {
//       i.kexUpdate(messages);
//     }
//   }
//   for (final i in accounts) {
//     assert(i.multisigIsReady);
//   }
//   return accounts;
// }

// MoneroMultisigAccount getUninitializedMultisigAccount(MoneroAccount monero) {
//   return MoneroMultisigAccount.initialize(
//       privateSpendKey: monero.privateSpendKey, privateViewKey: monero.privVkey);
// }
// /// https://stagenet.xmrchain.net/search?value=8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a