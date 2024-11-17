// import 'package:blockchain_utils/utils/utils.dart';
// import 'package:monero_dart/src/api/api.dart';
// import 'package:monero_dart/src/api/tracker/tracker.dart';
// import 'package:monero_dart/src/provider/methods/daemon/binary/get_transaction_pool_hashes_been.dart';
// import 'package:monero_dart/src/provider/provider.dart';
// import 'package:monero_dart/src/serialization/serialization.dart';

// import 'new_test.dart';

// // final r = await provider.request(WalletRequestTransfer(destinations: [
// //   WalletRPCTransferDestinationParam(
// //       address: receiver1().primaryAddress(), amount: BigInt.from(895550000))
// // ], accountIndex: 0, mixin: 15, ringSize: 16, unlockTime: 0));
// void main() async {
//   final provider = createProvider();
//   const unsignedTx =
//       "020001020010cfa0fb0386a539d58703960fec26a80dee40f0168a07c041ff0d8002b90390093d8305fc89e8fedc35920aff4b24c5dd8100dcca156f2de6c6b1f0ed1674c2a7d4ed1c020003bd42e7895a851ee34a175db5efb08bd653ba5c1c73459a7647a30f03c9af351fb100037a68b9c418a7ebcda01a6b34702ca7ba51c37911ffa6221c7a13bcc2ea547a2d3d2c01ffd8da395f63230227f07a0172f8d4a0a57ee5162af4c503b0e744f2a6098552020901327da86a59fa9e4906f0ebdc20b105f371f414bd792810f76ebc1f6054c982b042fc5c24e1842ac3407a2a34f593dd63ac1268177e39dc34c9f8aec13fd4238362f55e619f19acb628a13fcece0d3c92409209c44901a7644c058359360195d743e7f4742c5610dfbaaa81e85f20b705cee78ed7041ab48c1f0f9afe021f3343301249bcec4ccdb40d6587ebdab9ed888ec75b1b195471d1ca676b4769d9b0fd2e894c4fd08fb407da36a464aac298ade31b2ff7b76c1845daa1a035ad5c6b569553f010b3037235f8005be070df1a26fc27bf8b9733d739959c2221dc0c84ef76d10d8170956a31f60d660fde3e32f63c30b684ca64341da2e079965801220ec1ec3e5ac35b3dfa70226cd32050082c64003c0ed9b89e6e959ef78ad70407593975c83f787dfe8c29dd0ce2342a3de0fba6d9543804dadac86836f38cf68aee499e16978cb9016fc32b670cbbd46046682c08708fc718cee8e6543d88e5ee3f8239559f05a275ce4b87a8c864c9ee01e7c6ccebb43fa28a4a2d00f95244797ad876985bef82518cd533aa486bc41e36abd369ce2d10417d0256c8f4c91b8fd7c4bc5e87cbdb844a87b28401758bdff10cef1e3eff9bc506d6aed02735c13fe8b91a28bf7da6881b545eb3801f605f4ebaa330f790cf1713730d8daa5656899661a3194f4e3198cbd0968b88e8f4f41c695cef7c92a73f0985aacc68c3e4a20747a1226cc5cf13ff2b4b03001e3cb5b56778ec649b4e6c7f6dcb7e339f77016e660b33e2ebc8b64c5c31d17dac2e2bb1b5b520901fc3d2087e07c62385daa66985b9b7494ffa7c8de9297f0308dd2244e0cb42da31353867aba73c23dd18341eed993a16f24af659e2d90563fd6d386803c52e11053e262c89e036dd3c70a2dff80ddea18d75f21d096192e4468c581a011fccf0abd2afba97117f583f15eebf8c4f0d39db29df3bcbd032b3a70d6c78dedbc41fcee904bf22a1734149a5db971b347e553fb19dc21dcbfcda33aff4245678bc19d97d6cc912bf3cbe79aa7e3c2ba29f64d03e358c99c8cf551248b36b5c17b568630166a9b6be6ad38c71470ca38db31d8b37f115ac6a444e101f10796555c81843b698ee7984982ff0f480076b7b33b5853a382363ffee42d58b64716858bc2a5a99746055d7f89c4a93890e3824db5822ff0fbc92942054464efacd770333701ff3dbd430be501a25c960081f2f21aa1e16208396fa7ef54c24786623d96ce87fe46bd723e49f8c56faa10bdea7a80f09c58a638c543e28927423b4a410bb1a366476f62260e6f87ed41e04f62bbc518142fffec58c9b2f150ccd2e1d18796d09ade32eed7f1e6413f72f00c964aaac019144ffe2983cbaa7bc15617189c4dca5abae16b6d626599f76fc0a554d6b7f2c592442d01f39c89e09d269b6d93bc4d3b3b064a4e5ac3e28f1de0ffff00e9088d477161be060fd4bec937cd25d513f06c2a7eed581a85c361325042bc016f575ba893a0db45455973dda2cf05f0db519121b5eea0eaaacc5f7ac080e781ecfce1c1eb9c74cce93c4b7c9dcc6306d2d5a7baf72d535183fc9d0d30113086a4b0e933d87b2b5d6040b018f711f0659ad9cf560efb90cc922941119075c1666ed0baedfdb8e7f6abf701f708fc073effae6ac39c9ac88924282bbb10b9afb064f3454ee7d074cb06df1726688870eee61dfa3b1132b00676e51b92f02b716fe9abae435ce42fb5994669c5f0fe3b5ee3e8d4a66716f22b7a4cf853d02a98b55cbaf7d8d856ac565c217248c5721861c38a6cb6662ed87b50383985d02451044c7732ee5095302625f49feeda8111b824d1f70055bf8adb8a734c47841310ae865bc24ff27191cb52cfc23898b105f1df4498b99b6890910803deb67eb";

//   final r = await provider.request(WalletRequestTransferSplit(
//     destinations: [
//       WalletRPCTransferDestinationParam(
//           address: receiver1().primaryAddress(), amount: BigInt.from(895550000))
//     ],
//     accountIndex: 0,
//     ringSize: 16,
//     unlockTime: 0,
//     getTxHex: true,
//     doNotRelay: false,
//     getTxKeys: true,
//   ));
// }

// /// [7800926, 7800927, 7800928]
// void mains() async {
//   final chain = MoneroChainAccountTracker(
//       api: MoneroApi(QuickMoneroProvider(createProvider())),
//       account: receiver3(),
//       startHeight: 1730000);
//   await chain.updateLatestHeight();
//   chain.startFetchingHeight();
//   await Future.delayed(const Duration(hours: 1));
// }
