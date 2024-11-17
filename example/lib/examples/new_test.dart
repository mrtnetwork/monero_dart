// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:monero_dart/src/account/account.dart';
// import 'package:monero_dart/src/address/address/address.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/models/models.dart';
// import 'package:monero_dart/src/helper/transaction.dart';
// import 'package:monero_dart/src/network/network.dart';
// import 'package:monero_dart/src/provider/provider.dart';
// import '../../../test/junk/provider_test.dart';

// /// "http://stagenet.tools.rino.io:38081"
// /// "http://node.tools.rino.io:18081"
// MoneroProvider createProvider({String? url}) {
//   // final provider = MoneroProvider(
//   //     MoneroHTTPProvider(url ?? "http://node3.monerodevs.org:38089"));
//   // final provider = MoneroProvider(
//   //     MoneroHTTPProvider(url ?? "http://xmr-node.agates.io:18089"));
//   final provider = MoneroProvider(MoneroHTTPProvider(
//       url ?? "http://stagenet.tools.rino.io:38081",
//       walletUrl: "http://127.0.0.1:18082/json_rpc"));
//   return provider;
// }

// final provider = createProvider();
// void main() async {
//   final myAccount = receiver3();
//   // print("to addr ${myAccount.toPrimaryAddress()}");
//   // return;
//   final api = MoneroApi(QuickMoneroProvider(provider));
//   List<MoneroUnLockedPayment> outs =
//       await api.unlockTxHashesPayments(txHashes: [
//     "933c121f9d7a22bdb9b33acc7b0ae5227b56163a5852009a4a100de474b8c132",
//     "cd20d700458b0cf199f630c270cc61f3b82f77dbe7ac01f2ba50c7341ace5363"
//   ], account: myAccount);
//   if (outs.isEmpty) return;

//   final keyImages =
//       outs.map((e) => BytesUtils.toHexString(e.keyImage)).toList();
//   final spent = await api.provider.keyImageSpends(keyImages);
//   final List<String> spents = [];
//   for (int i = 0; i < keyImages.length; i++) {
//     if (spent.spentStatus[i] != DaemonKeyImageSpentStatus.unspent) {
//       print("key image spent ${keyImages[i]}");
//       spents.add(keyImages[i]);
//       continue;
//     }
//   }
//   outs = outs
//       .where((e) => !spents.contains(BytesUtils.toHexString(e.keyImage)))
//       .toList();
//   final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
//   if (total <= BigInt.zero) return;

//   final payment = await api.createTransfer(
//       account: myAccount,
//       payments: outs,
//       destinations: [
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.001"),
//             address: receiver1().primaryAddress()),
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.001"),
//             address: receiver2().subAddress(MoneroAccountIndex.minor1))
//       ],
//       changeAddress: myAccount.primaryAddress());
//   final tx = payment.transaction;
//   // return;
//   final id = await api.provider.sendTx(tx);
//   print("txid $id");
// }

// MoneroAccountKeys myAcc1() {
//   /// ["6ce8b0959ad004a80a9f26047642d5964a3a8219605036f2e3be9c597830715c","8df0ce6199766a9873c17e4f85a6e78fe05e3e29527ed5fb15dfc0f0a15c3243","f86efae0e13e92c8fbf29d4a1bd4222a8bf9884942e0ea1e026735d1cedd95f1","acea52068f5f1cbc627d65a1a94f48b4ce219624d4aa8a59b15cb6c9f6aa3b18","614911d5dcd62814f6ff3165da2b17bb082d7b17a29013b63ef419ffe2ad79b2","d20ccc306ae3174c40d5048ab892758c2c21ccb786f3aafe11f57f3f5089908d","8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a"]
//   const mnemonic =
//       "flippant godfather toilet paper ruined mohawk waveform boss nodes coils maverick anxiety waveform fading keyboard bevel apart jeopardy iceberg sober leech exit cowl ailments waveform";
//   final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
//   final moneroAccount =
//       MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
//   return MoneroAccountKeys(
//       account: moneroAccount, network: MoneroNetwork.stagenet);
// }

// MoneroAccountKeys receiver1() {
//   /// ["b45466aecedac9ff92b80a2fad3f5f4551db85e78bfc38b1bc0f5117c2013dce","6ce8b0959ad004a80a9f26047642d5964a3a8219605036f2e3be9c597830715c","6ce8b0959ad004a80a9f26047642d5964a3a8219605036f2e3be9c597830715c","d20ccc306ae3174c40d5048ab892758c2c21ccb786f3aafe11f57f3f5089908d","4ace5177c09dc5aea7693c8056d1e36f297803c3dfbcfaf21e58a2a4b97390a0","6fcee257a495ffe944fcb79afff0077ddb38a80e27c8937202d8f8e85358dbb0","09a0479c8fb2e6c8a4a5b96b8c0cb98caf0382dae818e85eb793696b620e4cf9","1e00f275569bc3d4ee795211a9e8e3bf4a40764561a6b23cca8e49d1e4dcfce9"]
//   const mnemonic =
//       "nocturnal eluded pancakes atom ultimate goblet elapse remedy sieve going weird examine federal zones duties mews howls vortex rebel zoom delayed puddle moment ozone going";
//   final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
//   final moneroAccount =
//       MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
//   return MoneroAccountKeys(
//       account: moneroAccount, network: MoneroNetwork.stagenet);
// }

// MoneroAccountKeys receiver2() {
//   /// ["acea52068f5f1cbc627d65a1a94f48b4ce219624d4aa8a59b15cb6c9f6aa3b18","614911d5dcd62814f6ff3165da2b17bb082d7b17a29013b63ef419ffe2ad79b2","88e650b79a1480fa528df1b5c81c25361f51f04fbe90e8c63b5aa0931e4f2be5","8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a","4ace5177c09dc5aea7693c8056d1e36f297803c3dfbcfaf21e58a2a4b97390a0","09a0479c8fb2e6c8a4a5b96b8c0cb98caf0382dae818e85eb793696b620e4cf9","1e00f275569bc3d4ee795211a9e8e3bf4a40764561a6b23cca8e49d1e4dcfce9"]
//   const mnemonic =
//       "reheat cuddled gawk limits sayings seventh truth pigment recipe edgy adrenalin fall vampire last elapse shyness exhale ghetto roped hotel bemused nestle scuba southern exhale";
//   final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
//   final moneroAccount =
//       MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
//   return MoneroAccountKeys(
//       account: moneroAccount, network: MoneroNetwork.stagenet);
// }

// MoneroAccountKeys randomReceiver() {
//   final mnemonic =
//       MoneroMnemonicGenerator().fromWordsNumber(MoneroWordsNum.wordsNum25);
//   final seed = MoneroSeedGenerator(mnemonic).generate();
//   final moneroAccount =
//       MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
//   return MoneroAccountKeys(
//       account: moneroAccount, network: MoneroNetwork.stagenet);
// }

// MoneroAccountKeys receiver3() {
//   /// ["acea52068f5f1cbc627d65a1a94f48b4ce219624d4aa8a59b15cb6c9f6aa3b18","4ace5177c09dc5aea7693c8056d1e36f297803c3dfbcfaf21e58a2a4b97390a0","eb4a527799d5678e8a3a240867f0a506068ed2dd853a09c31c0df65195111cc3","09a0479c8fb2e6c8a4a5b96b8c0cb98caf0382dae818e85eb793696b620e4cf9","1e00f275569bc3d4ee795211a9e8e3bf4a40764561a6b23cca8e49d1e4dcfce9"]
//   const mnemonic =
//       "pause mobile lottery smidgen inflamed hacksaw being sighting bested purged keyboard upkeep punch until stick owner vastness aztec hockey jeers moat moment business wounded keyboard";
//   final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
//   final moneroAccount =
//       MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
//   return MoneroAccountKeys(
//       account: moneroAccount, network: MoneroNetwork.stagenet);
// }
// /// https://stagenet.xmrchain.net/search?value=cd20d700458b0cf199f630c270cc61f3b82f77dbe7ac01f2ba50c7341ace5363
// /// 
// ///   "933c121f9d7a22bdb9b33acc7b0ae5227b56163a5852009a4a100de474b8c132",
//     // "af7f209cfee193655ec0d1d865ffb52e09e3b46af7f49b4d4e447a2e01b5f2bc",
//     // "189409dcff6d7e748f9d3b7f0833683b8132e8e53d06455eeaa13040f3f43ab8",
//     // "3523ade696fe15b8eba06ca4f278835e5b81291e39046cae801a6aa71a2577b5",
//     // "b3347795099b554e47781ff94991665daa1ebd04582fec3bfc6e2ccbf7f46879",
//     // "fc3cdcb681989822d5418b60bce4e988702b7b35a3d70d66855255085b46daa7",
//     // "f8dedeb30ac98b9c4f18152c81a44dbad28e6c8871a2efcaaa4d20922b6b0aa7",
//     // "67b068dd54c9f131939262ea7f2df20b8b38986da6082e89b1a1d9bba872df12",
//     // "1e7b13a6687cff6bcbcbf39f43e611a59dde355bf5b19c2d36bbc7c1b092554d",
//     // "614911d5dcd62814f6ff3165da2b17bb082d7b17a29013b63ef419ffe2ad79b2",
//     // "d20ccc306ae3174c40d5048ab892758c2c21ccb786f3aafe11f57f3f5089908d",
//     // "88e650b79a1480fa528df1b5c81c25361f51f04fbe90e8c63b5aa0931e4f2be5",
//     // "38f76f09d7ab711827171f3f8d02f8f5422c56adf29611352d87b114fad136f7",
//     // "8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26",
//     // "8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a"