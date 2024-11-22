// ignore_for_file: avoid_print

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/example/provider_example.dart';
import 'package:monero_dart/monero_dart.dart';

void main() async {
  final provider = createProvider();
  final myAccount = generateAccount();
  final List<String> unspentTxes = [
    "933c121f9d7a22bdb9b33acc7b0ae5227b56163a5852009a4a100de474b8c132",
    "af7f209cfee193655ec0d1d865ffb52e09e3b46af7f49b4d4e447a2e01b5f2bc",
    "189409dcff6d7e748f9d3b7f0833683b8132e8e53d06455eeaa13040f3f43ab8",
    "3523ade696fe15b8eba06ca4f278835e5b81291e39046cae801a6aa71a2577b5",
    "b3347795099b554e47781ff94991665daa1ebd04582fec3bfc6e2ccbf7f46879",
    "fc3cdcb681989822d5418b60bce4e988702b7b35a3d70d66855255085b46daa7",
    "f8dedeb30ac98b9c4f18152c81a44dbad28e6c8871a2efcaaa4d20922b6b0aa7",
    "67b068dd54c9f131939262ea7f2df20b8b38986da6082e89b1a1d9bba872df12",
    "1e7b13a6687cff6bcbcbf39f43e611a59dde355bf5b19c2d36bbc7c1b092554d",
    "614911d5dcd62814f6ff3165da2b17bb082d7b17a29013b63ef419ffe2ad79b2",
    "d20ccc306ae3174c40d5048ab892758c2c21ccb786f3aafe11f57f3f5089908d",
    "88e650b79a1480fa528df1b5c81c25361f51f04fbe90e8c63b5aa0931e4f2be5",
    "38f76f09d7ab711827171f3f8d02f8f5422c56adf29611352d87b114fad136f7",
    "8642c382fc29c5caf542d8bf9fb430a23189ca14cd53fc1019fb9b76b35a0d26",
    "8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a"
  ];

  final api = MoneroApi(provider);
  List<MoneroUnLockedPayment> outs = await api.unlockTxHashesPayments(
      txHashes: unspentTxes, account: myAccount, cleanUpSpent: true);
  final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
  if (total <= BigInt.zero) return;

  final builder = await api.createTransfer(
      account: myAccount,
      payments: outs,
      destinations: List.generate(10, (i) {
        final account = generateRandomAccount();
        return MoneroTxDestination(
            amount: MoneroTransactionHelper.toPiconero("0.001"),
            address: i.isEven
                ? account.subAddress(MoneroAccountIndex.minor1)
                : account.primaryAddress());
      }),
      changeAddress: myAccount.primaryAddress());
  print("tx fee: ${builder.feeAsXMR}");
  print("total input: ${builder.totalInputAsXMR}");
  print("total output: ${builder.totalOutputAsXMR}");
  print("change address: ${builder.change?.address}");
  print("change amount: ${builder.change?.amountAsXMR}");
  final tx = builder.getFinalTx();

  await api.provider.sendTx(tx);

  /// https://stagenet.xmrchain.net/search?value=cd20d700458b0cf199f630c270cc61f3b82f77dbe7ac01f2ba50c7341ace5363
}

MoneroAccountKeys generateRandomAccount() {
  final mnemonic =
      MoneroMnemonicGenerator().fromWordsNumber(MoneroWordsNum.wordsNum25);
  final seed = MoneroSeedGenerator(mnemonic).generate();
  final moneroAccount =
      MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
  return MoneroAccountKeys(
      account: moneroAccount, network: MoneroNetwork.stagenet);
}

MoneroAccountKeys generateAccount() {
  const mnemonic =
      "pause mobile lottery smidgen inflamed hacksaw being sighting bested purged keyboard upkeep punch until stick owner vastness aztec hockey jeers moat moment business wounded keyboard";
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
  final moneroAccount =
      MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
  return MoneroAccountKeys(
      account: moneroAccount, network: MoneroNetwork.stagenet);
}
