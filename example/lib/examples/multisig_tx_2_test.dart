// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:monero_dart/src/account/account.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/models/models.dart';
// import 'package:monero_dart/src/api/tx_builder/tx_builder.dart';
// import 'package:monero_dart/src/crypto/multisig/account/account.dart';
// import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
// import 'package:monero_dart/src/crypto/multisig/models/models.dart';
// import 'package:monero_dart/src/helper/transaction.dart';
// import 'package:monero_dart/src/network/network.dart';
// import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';
// import 'new_test.dart';

// Future<List<MoneroMultisigInfo>> getMultisigInfo({
//   required MoneroMultisigAccountKeys account,
//   required MoneroApi api,
//   required List<String> txHashes,
// }) async {
//   final List<MoneroUnLockedPayment> outs =
//       await api.unlockTxHashesPayments(txHashes: txHashes, account: account);
//   return outs.map((e) {
//     final ser =
//         account.multisigAccount.generateMultisigInfo(e.output).serialize();
//     return MoneroMultisigInfo.deserialize(ser);
//   }).toList();
// }

// void main() async {
//   final accounts = createMultisigAccountsM3N5();
//   final MoneroMultisigAccountKeys myAccount = accounts[0];
//   final api = MoneroApi(QuickMoneroProvider(provider));

//   final signer1Info =
//       await getMultisigInfo(account: accounts[1], api: api, txHashes: [
//     "8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26",
//   ]);

//   final signer2Info =
//       await getMultisigInfo(account: accounts[2], api: api, txHashes: [
//     "8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26",
//   ]);

//   final List<MoneroUnLockedPayment> outs = await api.unlockTxHashesPayments(txHashes: [
//     "8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26"
//   ], account: myAccount);

//   final multisigInfos = List.generate(
//       outs.length,
//       (o) => UnlockMultisigOutputRequest(
//           payment: outs[o],
//           multisigInfos: [signer1Info[o].info, signer2Info[o].info]));

//   List<MoneroUnlockedMultisigPayment> multisigPayments =
//       api.unlockMultisigPayments(account: myAccount, payments: multisigInfos);
//   final keyImages =
//       multisigPayments.map((e) => BytesUtils.toHexString(e.keyImage)).toList();
//   final spent = await api.provider.keyImageSpends(keyImages);
//   final List<String> spents = [];
//   for (int i = 0; i < keyImages.length; i++) {
//     if (spent.spentStatus[i] != DaemonKeyImageSpentStatus.unspent) {
//       spents.add(keyImages[i]);
//       continue;
//     }
//   }
//   multisigPayments = multisigPayments
//       .where((e) => !spents.contains(BytesUtils.toHexString(e.keyImage)))
//       .toList();
//   final total =
//       multisigPayments.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
//   print("total ${MoneroTransactionHelper.fromXMR(total)}");
//   MoneroMultisigTxBuilder tx = await api.createMultisigTransfer(
//     account: myAccount,
//     payments: multisigPayments,
//     destinations: [
//       TxDestination(
//           amount: MoneroTransactionHelper.toXMR("0.01"),
//           address: receiver3().subAddress(const MoneroAccountIndex(minor: 1))),
//       TxDestination(
//           amount: MoneroTransactionHelper.toXMR("0.01"),
//           address: receiver1().subAddress(const MoneroAccountIndex(minor: 1))),
//       TxDestination(
//           amount: MoneroTransactionHelper.toXMR("0.01"),
//           address: receiver2().subAddress(const MoneroAccountIndex(minor: 1))),
//     ],
//     changeAddress: myAccount.primaryAddress(),
//     signers: [signer1Info[0].info.signer, signer2Info[0].info.signer],
//   );
//   String hex = tx.serializeHex();
//   tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
//   assert(tx.serializeHex() == hex);
//   // MoneroMultisigAccount another =
//   //     accounts.firstWhere((e) => e.multisigSignerPubKey == n[0]);
//   tx.sign(
//       account: accounts[1],
//       multisigNonces:
//           signer1Info.map((e) => e.nonces).expand((e) => e).toList());
//   hex = tx.serializeHex();
//   tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
//   assert(tx.serializeHex() == hex);
//   tx.sign(
//       account: accounts[2],
//       multisigNonces:
//           signer2Info.map((e) => e.nonces).expand((e) => e).toList());
//   hex = tx.serializeHex();
//   tx = MoneroMultisigTxBuilder.deserialize(BytesUtils.fromHexString(hex));
//   assert(tx.serializeHex() == hex);
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

// List<MoneroMultisigAccountKeys> createMultisigAccountsM3N5() {
//   /// 8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26
//   final List<MoneroAccount> w = [msig1(), msig2(), msig3(), msig4(), msig5()];
//   final List<MultisigKexMessageSerializableRound1> kexMessage = [];
//   final List<MoneroMultisigAccount> accounts = [];
//   const int threshold = 3;
//   for (final account in w) {
//     final acc = getUninitializedMultisigAccount(account);
//     accounts.add(acc);
//     kexMessage.add(acc.nextRoundKexMessage.cast());
//   }

//   final messages =
//       accounts.map((e) => e.nextRoundKexMessage.toMessage()).toList();
//   final signers = messages.map((e) => e.signingPubKey).toList();
//   for (final i in accounts) {
//     i.initializeKex(threshold, signers, messages);
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
//     assert(i.threshold == threshold);
//   }
//   for (int i = 1; i < accounts.length; i++) {
//     assert(accounts[0].toAddress() == accounts[i].toAddress());
//   }
//   for (int i = 1; i < accounts.length; i++) {
//     assert(
//         CompareUtils.iterableIsEqual(accounts[0].signers, accounts[i].signers));
//   }

//   return accounts
//       .map((e) => MoneroMultisigAccountKeys(
//           multisigAccount: e, network: MoneroNetwork.stagenet))
//       .toList();
// }

// MoneroMultisigAccount getUninitializedMultisigAccount(MoneroAccount monero) {
//   return MoneroMultisigAccount.initialize(
//       privateSpendKey: monero.privateSpendKey, privateViewKey: monero.privVkey);
// }

// /// https://stagenet.xmrchain.net/search?value=4ace5177c09dc5aea7693c8056d1e36f297803c3dfbcfaf21e58a2a4b97390a0
