// ignore_for_file: avoid_print

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:example/example/provider_example.dart';
import 'package:monero_dart/monero_dart.dart';

void main() async {
  final provider = createProvider();
  final myAccount = generateAccount();
  final api = MoneroApi(provider);
  List<MoneroUnLockedPayment> outs =
      await api.unlockTxHashesPayments(txHashes: [
    "6ce8b0959ad004a80a9f26047642d5964a3a8219605036f2e3be9c597830715c",
    "8df0ce6199766a9873c17e4f85a6e78fe05e3e29527ed5fb15dfc0f0a15c3243",
    "f86efae0e13e92c8fbf29d4a1bd4222a8bf9884942e0ea1e026735d1cedd95f1",
    "acea52068f5f1cbc627d65a1a94f48b4ce219624d4aa8a59b15cb6c9f6aa3b18",
    "614911d5dcd62814f6ff3165da2b17bb082d7b17a29013b63ef419ffe2ad79b2",
    "d20ccc306ae3174c40d5048ab892758c2c21ccb786f3aafe11f57f3f5089908d",
    "8cabb92d2b79ae0b1b6079184651a518618140369756a86024a8e0f21d0c8e4a"
  ], account: myAccount, cleanUpSpent: true);
  if (outs.isEmpty) return;
  final total = outs.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
  if (total <= BigInt.zero) return;
  final builder = await api.createTransfer(
      account: myAccount,
      payments: outs,
      destinations: [
        MoneroTxDestination.fromXMR(
            amount: "0.1",
            address: MoneroAddress(
                "76dZbjNCQeVaQVeCq9y6H4dZ5wZqA9NY7WSnjjNUYzz5aht9rd3Qro57SSaN2eerE1aHkS9qvw5iscx3JrAT87bL8FiJ1Ye")),
        MoneroTxDestination.fromXMR(
            amount: "0.1",
            address: MoneroAddress(
                "51yw3EafPkXS6gwhJGGvNn7DzPEEGrgfeJZBvAFjzu8w252Zr1nx4PfVdXi4e6kiiQMBJ8k4JCFby2pANTAjofbo2rWBpbx")),
      ],
      changeAddress: myAccount.primaryAddress());
  print("tx fee: ${builder.feeAsXMR}");
  print("total input: ${builder.totalInputAsXMR}");
  print("total output: ${builder.totalOutputAsXMR}");
  print("change address: ${builder.change?.address}");
  print("change amount: ${builder.change?.amountAsXMR}");
  final tx = builder.getFinalTx();
  await api.provider.sendTx(tx);

  /// https://stagenet.xmrchain.net/search?value=35f8dc74c73263aa2f4af7ac66f09295733be7f68b1bf8ea60917484a1c41a7f
}

MoneroAccountKeys generateAccount() {
  const mnemonic =
      "flippant godfather toilet paper ruined mohawk waveform boss nodes coils maverick anxiety waveform fading keyboard bevel apart jeopardy iceberg sober leech exit cowl ailments waveform";
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();
  final moneroAccount =
      MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);
  return MoneroAccountKeys(
      account: moneroAccount, network: MoneroNetwork.stagenet);
}
