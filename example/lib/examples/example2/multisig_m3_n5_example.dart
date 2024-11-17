// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/models/models.dart';
// import 'package:monero_dart/src/crypto/multisig/account/account.dart';
// import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
// import 'package:monero_dart/src/helper/transaction.dart';
// import 'package:monero_dart/src/network/network.dart';
// import 'new_test.dart';

// /// 1e7b13a6687cff6bcbcbf39f43e611a59dde355bf5b19c2d36bbc7c1b092554d
// void main() async {
//   final accounts = createMultisigAccountsM3N5();
//   final api = MoneroApi(QuickMoneroProvider(provider));
//   final MoneroAccountInfo2 myAccount = MoneroAccountInfo2(
//       account: accounts[0].toAccount(), multisigAccount: accounts[0]);
//   final List<MoneroUnLockedPayment> outs = await api.unlockOutputs(
//       txHashes: [
//         "67b068dd54c9f131939262ea7f2df20b8b38986da6082e89b1a1d9bba872df12",
//       ],
//       account: myAccount,
//       accountIndexes: [
//         AccountIndex(address: myAccount.toPrimaryAddress()),
//         AccountIndex(address: myAccount.toSubAddress(), minor: 1)
//       ]);
//   final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
//   print("total ${MoneroTransactionHelper.fromXMR(total)}");
//   final multisigInfos = outs
//       .map((a) => UnlockMultisigOutputRequest(
//           payment: a,
//           multisigInfos:
//               accounts.map((e) => e.outputMultisigInfo2(a.output)).toList()))
//       .toList();
//   final multisigPayments =
//       api.unlockMultisigOutput(account: myAccount, payments: multisigInfos);
//   final n = myAccount.multisigAccount!.signers
//       .where((e) => e != myAccount.multisigAccount!.multisigSignerPubKey)
//       .toList()
//       .sublist(2);
//   assert(n.length == 2);
//   print("n ${n.length}");
//   final tx = await api.createMultisigTransfer(
//       account: myAccount,
//       payments: multisigPayments,
//       destinations: [
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.01"),
//             address: receiver3().toSubAddress()),
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.01"),
//             address: myAccount.toSubAddress()),
//         // TxDestination(
//         //     amount: MoneroTransactionHelper.toXMR("0.1"),
//         //     address: receiver3().toSubAddress())
//       ],
//       changeAddress: myAccount.toPrimaryAddress(),
//       signers: n);
//   MoneroMultisigAccount another =
//       accounts.firstWhere((e) => e.multisigSignerPubKey == n[0]);
//   tx.sign(another);
//   another = accounts.firstWhere((e) => e.multisigSignerPubKey == n[1]);
//   tx.sign(another);
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
//   /// 1e7b13a6687cff6bcbcbf39f43e611a59dde355bf5b19c2d36bbc7c1b092554d
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
