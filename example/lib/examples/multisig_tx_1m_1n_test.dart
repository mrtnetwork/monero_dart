// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:monero_dart/src/account/account.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/models/models.dart';
// import 'package:monero_dart/src/api/tx_builder/tx_builder.dart';
// import 'package:monero_dart/src/crypto/multisig/account/account.dart';
// import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
// import 'package:monero_dart/src/helper/transaction.dart';
// import 'package:monero_dart/src/network/network.dart';
// import 'file/readrands_test.dart';
// import 'new_test.dart';

// void main() async {
//   final accounts = createMultisigAccountsM1N2();
//   final api = MoneroApi(QuickMoneroProvider(provider));
//   final MoneroMultisigAccountKeys myAccount = MoneroMultisigAccountKeys(
//       multisigAccount: accounts[0], network: MoneroNetwork.stagenet);
//   final List<MoneroUnLockedPayment> outs = await api.unlockOutputs(txHashes: [
//     "38f76f09d7ab711827171f3f8d02f8f5422c56adf29611352d87b114fad136f7"
//   ], account: myAccount);
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
//   final n = myAccount.multisigAccount.signers
//       .where((e) => e != myAccount.multisigAccount.multisigSignerPubKey)
//       .toList();
//   assert(n.length == 1);
//   print("n ${n.length}");
//   final tx = await api.createMultisigTransfer(
//       account: myAccount,
//       payments: multisigPayments,
//       destinations: [
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.01"),
//             address: receiver3().subAddress(MoneroAccountIndex.minor1)),
//         TxDestination(
//             amount: MoneroTransactionHelper.toXMR("0.01"),
//             address: myAccount.subAddress(const MoneroAccountIndex(minor: 1))),
//         // TxDestination(
//         //     amount: MoneroTransactionHelper.toXMR("0.1"),
//         //     address: receiver3().toSubAddress())
//       ],
//       changeAddress: myAccount.primaryAddress(),
//       signers: []);
//   final ser = tx.serialize();
//   // final decode = MoneroMultisigTxBuilder.deserialize(ser);
//   // print(tx.serializeHex());
//   // print(decode.serializeHex());
//   // // MoneroMultisigAccount another =
//   // //     accounts.firstWhere((e) => e.multisigSignerPubKey == n[0]);
//   // // tx.sign(another);
//   // // another = accounts.firstWhere((e) => e.multisigSignerPubKey == n[1]);
//   // // tx.sign(another);
//   // final finalTx = tx.getFinalTx();
//   // print(finalTx.getTxHash());
//   // final txId = await api.provider.sendTx(finalTx);
//   // print("done $txId");
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

// /// 5AoMqeai86EJh7YzQ9y9ZWHzSCR4QsbdtJidYq7PWxDjPWRKFoSdPXNQoK8r9Xo6PG33DScGPG4MiCrUtre6qMa8R9bSo8q
// List<MoneroMultisigAccount> createMultisigAccountsM1N2() {
//   /// 38f76f09d7ab711827171f3f8d02f8f5422c56adf29611352d87b114fad136f7
//   final List<MoneroAccount> w = [msig5(), msig4()];
//   final List<MultisigKexMessageSerializableRound1> kexMessage = [];
//   final List<MoneroMultisigAccount> accounts = [];
//   const int threshold = 1;
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

//   return accounts;
// }

// MoneroMultisigAccount getUninitializedMultisigAccount(MoneroAccount monero) {
//   return MoneroMultisigAccount.initialize(
//       privateSpendKey: monero.privateSpendKey, privateViewKey: monero.privVkey);
// }
// /// 014638578a649b176829df1cc805733ba72ce4a98535000bf4863ba2cbfd24310f01f0bae9eab61f10a8f0ac03f3f68301ab8805a968983caa8c01e642ea04cb32b9159d07df0aed02b4031905f6abeecd09625d142a2dd0bca7b23c1becc8324675b5fded76a471d3c537f12603f56c9f21705936ce82ab031e715f44be617f25a2a42c1e8496c3a9135b800a02a8011e0b7c897ead34a536ebe0a767e7650ed0ea029213c2b475888a44f44b090c4644b8eed3f29d8b4af2ca8725cef061ad24ecbf4bc3f0f0a4835be0398601020104d95cb0ea10df7f73140a0c748b505d959471ff7ea75abbabf96032f140afb8040303e845b56bcd9c01d0a87781ad6ce779043af6f2b1e43d2675fa565daff514136b2a29cfe4f794490f36944d5fae87feeada7ba9f65334fc4786529e04f6ee612d121be069666ff4f8c1760ac528dd9a598968f781f6ae3cdc3fd3c0a1b6c64204d95cb0ea10df7f73140a0c748b505d959471ff7ea75abbabf96032f140afb80303e845b56bcd9c01d0a87781ad6ce779043af6f2b1e43d2675fa565daff514136b2a29cfe4f794490f36944d5fae87feeada7ba9f65334fc4786529e04f6ee612d121be069666ff4f8c1760ac528dd9a598968f781f6ae3cdc3fd3c0a1b6c6420432e6b62ef07b50b1b52e08ea32fc9ffbc081b9294779afd39a9a1faa0f33f507bb7e472fbf34ac8564daba82dec72804a7f6cde0ad713cd1eb0ca8dd72ba2d0d95d5b796c1303cf8a01099332e71c6eb4df2b7cd516a69893507df53b8c3020efabc886b211e10546d7f5b6673544796995b18eb80a4d195553bebeb34e48d080380c8afa02503b9970289b9fd18b3f2ed7f8545e118ce62e21ac2284e0de6c9eaa5d102678359eb80c8afa02503a596a7b16967806fe2b446ec79d3da00a1ed887aab071ebc216c1d145dd5137d6f90a4fdfaeb1e036ed5bb298da80ff91a1a7f9d6e05653b3b91b250eaf336695c12c27f2631a040ab020001020010a8f0ac03f3f68301ab8805a968983caa8c01e642ea04cb32b9159d07df0aed02b4031905f6abeecd09625d142a2dd0bca7b23c1becc8324675b5fded76a471d3c537f126030003b9970289b9fd18b3f2ed7f8545e118ce62e21ac2284e0de6c9eaa5d102678359eb0003a596a7b16967806fe2b446ec79d3da00a1ed887aab071ebc216c1d145dd5137d6f00036ed5bb298da80ff91a1a7f9d6e05653b3b91b250eaf336695c12c27f2631a040ab83010104d95cb0ea10df7f73140a0c748b505d959471ff7ea75abbabf96032f140afb8040303e845b56bcd9c01d0a87781ad6ce779043af6f2b1e43d2675fa565daff514136b2a29cfe4f794490f36944d5fae87feeada7ba9f65334fc4786529e04f6ee612d121be069666ff4f8c1760ac528dd9a598968f781f6ae3cdc3fd3c0a1b6c64206e0868d2f48564ae95d76c9c0382b13c4f83f687066ab8af0752004fee7233f0d271e787a454ce9f79ebece26a1c9e49a38fd7acd7596eb2281188ebeaa224bb336d205d8a8f19b3fea2ead1aa2864edacb5f8b01ed56f704bf18fb78fcca3b65e8bdf9b00bf264a1de2a60741469ffa086b601f94d509809bb01c492019f5d43f5d65688978114a00128771452f5860e714b3b905590ea154c519893bc497c8303bedcc036bf0aaffe72c570ed0d5a4cfd5ea4843b7fd50eb8557ef899fc5bd1e8c17f696185c076673dc750dac8c23c18725d664b0011e86981c761ff60a0f1777113e44e63e57cb67dfac5db462c515130f466dd492316b1286c0104fd864800b015f95c750792a0e246f8082800276416eaeafcfcb55072a50c84008fa549f28382d9f0c4899144368c072640b344956c770405484553bf6b7e130b08b7845b937b1026ccb7f2e07f886aea19a1968b1c690608f2cfc1d7ee0aada0eff829bfcb45d0df3fb1b1318ba78ab38a37eedec38025e36ea718b63ef7837f6b0615322a84b362a9ba0c4bcf1b045302ee57c590604443d97f10c9be253d74e2701d0eb6a5d45e5790e1a49782e4bcaa37d8bc86e51eeb37b63d690847d2eb8f2333d3827b015ba5dd68ab7aa579ae0ff43b035277782aa0922a3fb9c836608946347325d865fc3b054638b1f7c060c0b89cce8176842454dea58399b44832b492953dbfe7e660cc0665ada8c4aa93302c8e65d051017384f33335b6fb30e7d49a5911b4e081b0c25622c683de46f8229d046245b08abd5d79342af9f7b14ae3080a0bba5975e71a48e45560019b6f303507c5a3bc09e70a4ba54522e11f1465dd67182745042ed38e0d2b2dd43f27330a7c6d3f9ed3af2918fff7e062c347bcf1c71166106229097e6e4df2248aeefb8d153e065a2f18534b90dbffc4227992793b15f6de386c38687be0c59654d8d4549960edecf30725619344e0f2ed5c6f8f671ebcee4f80ad397c80409e3b968270e51a160f6d89208b0d7ca71387d783fbc0cf2fd952a83811eb182a36ad3284b1c8723f3b419ae28132c793ef6699bf28cc20142b61a82b70ccdb1f0c09d1e589aad6fdc404f4638e82ccf4738bf84f6a9ffbc8ff643a5043084c40720037e46edc3c368e2fc370a0b75a985181dd818c76a9a65f5c291afa581ece4de028b06c90dff508a2556fd55365444b2ba53b0ca48de4db7d9bd4836e8f22d92a1275bf2e2b3d53713a9de6db7f7390183afd0f7f7510ff23d6c4c721377cfbaed3a0b99d63748d09a9bc910c7b03fb51ab990517b93a4a4cdf35f838ccd7a75ef3042c4f2573a2d449d4e7c56777a641326f0264baa816164ae97f9bbb30c713c78e5e0f6289531499d2f089f8476fd40ef006cbe26b5ecb4800b55a5621dc0c9888e2b3ccd6759ad569714d1d146f62c2660cf251f73600140395e31cb94d9e1d302bf359ef5290972945d8a1a81acb48050278faeaabe45daacfba585fd8e423991649e10430533a7ee56645d25a50efce0fe1bc03f89287ff38d2680cafb3b37f150aedd7f3071c1645f9acbbe850864e06ac37a0802490498f9248b0ac865399f99cabcf92df63f33149afcaf68ba1e2094aef7deec28d8119c25d18c0e5d039db9788e64e694133818508bfc0e305730e0000000000000000000000000000000000000000000000000000000000000000be7b76d38a32460aee356b77bccd540eb572b1532bf74b19fd4fb72b82bfa60f4bbd71602a0d32731705f701dfb34949f728b831ebb9186de8313efd9ad8300e321a66a768f058f134b196fd8a1f6d2aaa2486e41f34467945431d92aa16c30095665802f83c5b062413af1df0ebea25b60dd35405d131aef33c599d69818d0700000000000000000000000000000000000000000000000000000000000000009aab444355213f577a33b75f2082ce05629981c596a2315a3708ea929b8b7887972ca3aa5808283cde91caecff1cd2652efb70cc37453932d72bd9ae57e6f0e30280c8afa0255f37327750467957627067785374544c4b793865655873617755754437534158424d543532367053627a726e3931766e3335714667426e676973643473436637584d6853664b7637346b63566953374a6565753754453436344b69785654486f80c8afa0255f37335165754a6d714a704e32546d6f6f464132473934695157744a46646a56764d426975634a31376668595367694e55624b6d50436274634c786a4e62394c666f3951486f4b654850387074756168644c75554469385a70316633384547760102f0bae9eab61ff984899d4e476198c983017ac48f56f5ad1663ecf7685f63b88b4a202c9d2a0eb537a9dbe966e21c7315822add777b200017e82102be6c99b0eca3c65e845a23fb08a872ba6c4b98aba666e2f4cef94114995887cf81a7849bc36b5f69d834520181c2b9044638578a649b176829df1cc805733ba72ce4a98535000bf4863ba2cbfd24310ffb08a872ba6c4b98aba666e2f4cef94114995887cf81a7849bc36b5f69d83452f6abeecd09625d142a2dd0bca7b23c1becc8324675b5fded76a471d3c537f126f6abeecd09625d142a2dd0bca7b23c1becc8324675b5fded76a471d3c537f1260000000000000000a01a24bab72750bc91c9b65754232ae00b3cc0e89c106752823e35fe7944d3be00000201855623baf4de1df9bb1fcc685c541946ac2a5851a9e7a23a8b43e2b62f8ffa72021bb26965f0e2f536edb42392ae6d241a95f4606d1c0efecb6c47af1981aac587ba8340f8cfe61e9b9b78d1236936420379611242cf29b455712f33b838a7235d2ab00cb36f7229062eee2b3c4150753d933c09450196cbeb92d7002eda2a0a08e49c55ee3b7e1930d542e8326a32a2f34d5b7930ae64222155e0c354d0dd1feece731cbfcadc5af16f36eb150133407a527b660d2a8510cc8c3a33559e6c3fb48285584d562d24372e536692d190837702781673d27ed4a07ad47418961adc0301a6b975d03e7fd5aebfd913a472c4045decb3292a70fc7fd1b2f662c022adc1ff10a8f0ac032d9e940783bf5822595c94eaa85f2bd0ede23f6f0af96ab8e3e3d00afa014700749617ef3392880cc4316eb404cbb6e28752341ce9add4f6967c3bbb842c03459be7b004ee61eb1c5bc29256176e03d7c1a207ff18c1c02cdbe5b7a74293fb401aa6c61945fce7cc64c315213bcfc612bfa484c612e7d2f9073e22fbe358d31d24f4f3dec6efb5042e20d36d5fca51ff08b7453ebb2a4cca5ab7585d3311b6a61924b65ff117b84c4956df206cd929affa9d12efaad8371c72dfd7bcd75cc76acd29edbbfa15bb89efd7b6049ca64739bb932c8e26f561ba4adac7841c07a9b11288717f8bdef7f84a638590b6545fe640fc4f47dc814fc9ba145a2c33acc2684647a29abc98c2e907a281a58794b7046e11da1ac57fc68f78512f919fef5769c794c334c588d1e52bda0fbad2f19c57cf472903e2dc66b033e044c5717287517b37dbc87073baa7be5aa7b21e7aaa76b1a0b804c1df8fe3efe9b3994a919f6ebd6036508441fb3b6a777ebc3f9cf20acc4f4c718f66d0fccf9c7084a54f63f72a7572ab0f2403a8965f83ad6ff86f3b7d753b4297e3b80419b8bbaaffd80244d090dce5b57429a60e1daeec98df5b61cf90d672e4fe3e8e69652ea504b3e09a58184679557f0714cc0fcdc0df4af29bb1ba200c6b137bd081e8b804169a4a37873bdaf7e119ce6f7be921c92049603c3c4b92591c708a5cd760e455baf9bf6b9ab2e171fa0fcd42891dedb839b230d4a9526197cfc41bf98d5343d9cc9ab904acd9161507eaa861c6773660cd0a17847c32c4bcc7a318440751e5f89ba4988645471fa0999033dfdaf33665f1ed1703127bc0bccefd1c7ad0cc0efac5f0aedd85b0b904ede3dd920ab45ff07d2a3cd7f4e0458a61efc4701b18a5a468978f4b6fd7cb74ec9d3c9ac7b40afee75ea299b6a5c6f76336a91db73a4317cd22e4cd4b2cf865a2b7b904cfdd5156d8eaaad33cd714e20bbaa885aed4fb522371fd4dde69d7d5e55545db29d2dbb9a3cba1c6bb666adfe75dee2e463822b1b7bbd6115f718e54baf7090081c2b904fb08a872ba6c4b98aba666e2f4cef94114995887cf81a7849bc36b5f69d83452ed2445dda5399ee771a1799feba24750898e85a3acf04e0d5319b941832fdc29eec4b904c9f9bd9f8f4b400579b5cde146618c0a43e31fcee93c8e0b4998d38da289f547b7e3a92a6c932fd188425593aefb3e07856429bd274c291e480c2c77b30b33a2a2c8b90489b50fd945c2f7b389b78e768fa0269179275f1a9aee91eb4875649de947eed76b5640a9b8312ee894a1a612bc3b636c0a4d9fff3349e7497599adddb5cdb943bbc8b9043249696a6bd8ef6430a6136cd0ac6897c552e0343d7da093c3bac13a69ed87506018eca6f60128cc62f703c09ca2ab02cc387d8c6a6272e12160fed00e22a65fc0c8b9040dca811796ec2a1f0bfed6805d5a20d4f0b0e9a6b2d87891243a77173379a6fa25e4ba12f109596af19b7043d9ea7fea0e490394fc0c1c1841d23c3326fcaf8b0b0190a4fdfaeb1e5f35416f4d716561693836454a6837597a513979395a57487a5343523451736264744a6964597137505778446a5057524b466f536450584e516f4b387239586f3650473333445363475047344d6943725574726536714d613852
// /// e4ba12f109596af19b7043d9ea7fea0e490394fc0c1c1841d23c3326fcaf8b0b00012b8400a437f21d94eb6af00d21e997dc05c8c8b98e3f632baf7951ad1d64f408000186c07c0ae58fe762532e1b3ccd8707ccb529a4c104a0bf284121f8f0e3e4e88b010001ecaee994c7c2c369c56c2b629e46dd6593fbc427c9dcc369ed75
// ///                                                           3962536f3871012b8400a437f21d94eb6af00d21e997dc05c8c8b98e3f632baf7951ad1d64f408000186c07c0ae58fe762532e1b3ccd8707ccb529a4c104a0bf284121f8f0e3e4e88b010001ecaee994c7c2c369c56c2b629e46dd6593fbc427c9dcc369ed75
// ///                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         