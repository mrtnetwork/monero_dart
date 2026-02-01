import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

import 'tools.dart';

void main() {
  _test();
}

void _test() {
  test("range proof padded bulletproof plus RangeProofPaddedBulletproof", () {
    const rands = [
      "f5b5fe0eec3f68fc8b7db94fc673d1b2eb5f6aafb8d70b10f4c9dde99366f20a",
      "85eab017da6d3045845ba7229c0dd71000e277a1ec1f37cbd8fa0f4898386d02",
      "966df994d4d80614a397944fea1d944629f821749ac58cf657b4f69bf058a306",
      "363ff7146d65ca3a3ce20130ed4969ca44aa7275d3e24443050f46abf086b102",
      "ac550e70fdf4a2e5588fac987529aafac90a39cf66ba0710f21256fb35f98006",
      "683c43adc59ccae70816b9cd36b6bb0cdbfc0dcec5f59b12406e98b35f333c04",
      "21ff4e2d24eed6eeee833d28632ba54d648800ff3c61606ae5fca2795109500e",
      "41e3534253828823bec13a59185ad616e28319c9f16d85acc52360e00d4f5d08",
      "a0d9507a5ac34d5f09e6ace14a49270d81e94ded0984ac8a3658c5b875210e09",
      "76593129c8c97e6a80fe0fccaba374554e7fbae6fac47de5cfe6766d8b43e808",
      "eb65737a45eb15033c0ba133138fc1893fd808db1948b2c7266788b299dc1d0d",
      "41e60bc485adb08085ace8aeacf679fa6d3b34a201b62b270992004b5d3e9000",
      "1a4c48b0be53c92d0d2166b595b84c3313ee26672b38b000d1755ff32b520604",
      "96dcf07ed490af15135cce82d720d416c5e1d85d49ba706b34de55d66592480c",
      "87eed8de246bc0d8895f1efcedb788f9c8a58e7183ae60a182780705e9ca7c05",
      "a966f6ba931551c47ad1071204c30998094d9f28649d0365f12d7cd215bebd02",
      "a7710981e73e830e4f37ea9a68d5f95a3216ba872cf7c8bcea4f493ba47bc201",
      "f2496d301f442738c8ea76ebb164401c241c26a8ce85bad5e462fe721389a202",
      "4c0c203994dd836c9617cfd1f0cc539cbd1188a62de65d426bc34a6a2eb9910b",
      "ec75dcec71d9a72e674995d7f4e9fe47943b935ab34960bb4f2aeec8b6e36a08",
      "fdec9428d042d65d974d7715c387ce8a8afee2daa3dd6a01ab3c753ded93210a",
      "a772a12c1c275ca2c3c41df9e2ec52f86f04f49cfb558a55cfd5fe2bc30de201",
      "25d7c24a30e5abbac23a2d3a3a9d8b8f92a441742ed0c522e976ce8ee262d206",
      "2f72bbacd353a9d27747886b408ade9c2f2bfe8357cf9989d95b0a7f8b2f0d0e",
      "1a23b4fde9b1dd6d1105dc0eeeae34e0c7ccf1afb3d9a7294aef0935ab840309",
      "9bf01b28149223f8e4f00a947a2f66cfa77d9167682c0067be06938a70751b02",
      "98b5d314bd45dd0d0f0c8e1750c7996baab7a2faea2828c3a24deff9ddff2e04",
      "a1eda28b7cf1db683835416ba5a186ba1640290811111c436a0dc0ec6c375801",
      "a16b85ea56a8718c573c17c707ba6154e188150a48cdac21a5dd968f98ca090c",
      "05b2b5ddf5d494f213a9406f8a9fb3facb4398997e9987380e07b5614083d705",
      "2481b2b935d1616165274e0e1a28f74760a540f2ef848891f61b2c16ca7f5705",
      "402fe5f0890d5448456fec43dfc945923579b25e6a74c8120af9da25f94a260c",
      "be835549767225c635a979075b9e872372e644eeaf3f28afb22c27e3e85eb900",
      "c7c87f504aeeb117ed717ba6353023ce91c02836dcf4778629a3cb46de4ef607",
      "54d4555bf75fbb6f62ba9c9b7e701b453e629c163b2a7a160a3e54e4a0722a0f",
      "454fc8af23c014638d85d5e41c51b4e519b1f23f693bf2e5a7a410346e444503",
      "bd82d253bcd29c2f753acd7b2e0299cdc4353a0ff0168f63b1a03ec5093c2408",
      "55448e41ce7339ec17d485655050d8245432ae91faec0a6e64574467aebab00a",
      "f8cc4f06fdad89787c1032512e666e8e306fc1f6403b9e5bb80340aed3c64203",
      "52edce422095c44493f69d8791a0764c29ddac8608f06416482e33d77fa6380c",
      "5a0d444c514b458b770b70aa97f0d3cb70b41ed82850d0399a40cbf3f5adde0a",
      "3423652704b54d71212c73b4bd0d257e3d93e420e97de039d49a6bcf1e5f8f0d",
      "e7c1a1ea80d000b311355da65ddf4f1e9e6e1fad67bd95d4db0e92eb4c64ee08",
      "3e2b95460f0799b6b1a0e9b3b1c45022b0a409fecb04761c4ab62402eae7f505",
      "785fa0e042aa7194bea73019c0b1e94b5a621cf728cfe72c745cbe39697e2607",
      "a474a265af7e95fefe70c58bff9dfba33070756c49f7707ae6abff010a64f30e",
      "0e4e2583b3b8f1eccd77d8eae34974aabd80092ce765c893b71b9a971bece606",
      "1ca4ff385853cba08c60753c8e3169f1ffff064a7ff430a61d9f9c3b95be3102",
      "2e009b6be60bf5e24c3399a0d3f108bd8a38cbf6bfaac13b6c2b0000f807fd01",
      "f390686a2bd28fe4bbb2a5ed2c56e949735ed70aabc32de559ddb91d0939050d",
      "4c67a275c56ac225c2a5045bdcf8075976f0eed2b98dfd786d076b1ebffa7303",
      "b30216b6926c98b60893e26957f5c225c296240474ef87d808704a648728e406",
    ];
    int index = 0;

    QuickCrypto.setupRandom((length) {
      if (index >= rands.length) {
        index = 0;
        // assert(false, "should not be here!");
      }

      return BytesUtils.fromHexString(rands[index++]);
    });
    final List<BigInt> inamounts = [];
    final CtKeyV sc = [], pc = [];
    // CtKey sctmp, pctmp;
    inamounts.add(BigInt.from(6500));
    (CtKey, CtKey) f = ctskpkGen(inamounts.last);
    sc.add(f.$1);
    pc.add(f.$2);
    inamounts.add(BigInt.from(9000));

    f = ctskpkGen(inamounts.last);
    sc.add(f.$1);
    pc.add(f.$2);
    final List<BigInt> amounts = [];
    final KeyV amountKeys = [];
    // add output 500
    amounts.add(BigInt.from(500));
    amountKeys.add(RCT.hashToScalar_(RCT.zero()));
    final KeyV destinations = [];
    final RctKey sk = RCT.zero(), pk = RCT.zero();
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());
    amounts.add(BigInt.from(13500));
    amountKeys.add(RCT.hashToScalar_(RCT.zero()));
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());

    amounts.add(BigInt.from(1000));
    amountKeys.add(RCT.hashToScalar_(RCT.zero()));
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());
    final RCTSignature<RCTBulletproofPlus, RctSigPrunableBulletproofPlus> sig =
        RCTGeneratorUtils.genRctSimple_(
          message: RCT.zero(),
          inSk: sc,
          inPk: pc,
          destinations: destinations,
          inamounts: inamounts,
          outamounts: amounts,
          amountKeys: amountKeys,
          txnFee: BigInt.from(500),
          mixin: 3,
        );

    final verify = RCTGeneratorUtils.verRctSimple(sig);
    expect(verify, true);
    expect(sig.signature.message, RCT.zero(clone: false));
    expect(sig.signature.mixRing?.length, 2);
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.mask),
      "106d6e7c85fefce476f59339556af1b2a883859d8046c5b90f13c3dc69b5a2c6",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.dest),
      "64622bdc0317b22dd5481e4c892ce0a7a39cfec6132432af3f8c64f260c0457c",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.mask),
      "fed5b893e7d16ef2140e14d09b056e06249129702cd11b76477c11c011edbc0e",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.dest),
      "3e7aadc2bd8d1d765654b8fbe383ccfca13c0fa2bd86d8ec7512f0482718c359",
    );

    // // // ///
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.mask),
      "0fdbe32f6d2f95c5c5a8e61e644c9fd85e63c14f6d14d4e4ef09e9a58767ced6",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.dest),
      "78f61fd432f99e22b10a3b953c8e4886abcd6bdaf1d6fc410d76d51a02d908f1",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.mask),
      "cc7f240b7ba215f1a6b517f70c6084db9d81a317f8ce7eb7a2666880b2c3813c",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.dest),
      "4b5418d0e194d350d3704a3e1286af65bec50b849e0212267562bdaf6589cf56",
    );
    expect(sig.signature.txnFee, BigInt.from(500));
    expect(sig.rctSigPrunable!.pseudoOuts.length, 2);
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[0]),
      "45710544f43e36ead0a5106af4a1e40e345935315d33358ed57f729502ccecbb",
    );
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
      "a8748b4bd8c5a52f209901d4d15f45a1d3ec99653edea2cc0e5efbe909a1265f",
    );
    expect(sig.signature.outPk.length, 3);
    expect(
      BytesUtils.toHexString(sig.signature.outPk[0].mask),
      "21843920f19aaf8fef33717b3e190f13d5c10029ecb94d8ecd89cd8e1a3dec25",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[0].dest),
      "60f0ad6ed79edbfbcb1aafe6a3ac582562aee7ec18a1685bde7082e578de6e28",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[1].mask),
      "d8697a3858fbb639c3ca692c4cc81c72c0f45d99fabe46f2ca34067147cc98b1",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[1].dest),
      "7633d9380ad8d1a8cec3e96c6776c35a299fe7785b3356913413499070d1b8ef",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[2].mask),
      "1d43fc74457b9664f48e425ce69d991479b371bd30c89fad9da28644137333ec",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[2].dest),
      "eaa3effc82f63f6c5b233cbca2f1f6ffa1fe937573829d66bda843b728fefec4",
    );
    expect(sig.signature.ecdhInfo.length, 3);
    final ecdhInfos = sig.signature.ecdhInfo.cast<EcdhInfoV2>();

    expect(
      BytesUtils.toHexString(ecdhInfos[0].amount),
      "33ad6ebab7c67708000000000000000000000000000000000000000000000000"
          .substring(0, 16),
    );
    expect(
      BytesUtils.toHexString(ecdhInfos[1].amount),
      "7b986ebab7c67708000000000000000000000000000000000000000000000000"
          .substring(0, 16),
    );
    expect(
      BytesUtils.toHexString(ecdhInfos[2].amount),
      "2faf6ebab7c67708000000000000000000000000000000000000000000000000"
          .substring(0, 16),
    );
    expect(sig.rctSigPrunable!.bulletproofPlus.length, 1);
    expect(sig.rctSigPrunable!.bulletproofPlus[0].v.length, 3);
    final bulletProof = sig.rctSigPrunable!.bulletproofPlus[0];
    expect(
      BytesUtils.toHexString(bulletProof.v[0]),
      "7de665bfc6c98a0b4d8d69121646fa6e70d009455d67c6d98995a3fe0c72c8df",
    );
    expect(
      BytesUtils.toHexString(bulletProof.v[1]),
      "10f44612272545f0a17c3e00cb6659806743a9c6321befec72f0db7dd372d1f9",
    );
    expect(
      BytesUtils.toHexString(bulletProof.v[2]),
      "87afd52d1cadb5bba5e8417f8f024700b16b124b3d725e83e881f4399e82ecb4",
    );

    expect(
      BytesUtils.toHexString(bulletProof.a),
      "a09a9693fd3f9e94bcf78e082c6126d44da8ae892cb31dd3a79c71be7f1bb845",
    );
    expect(
      BytesUtils.toHexString(bulletProof.a1),
      "defae0381982a980821838ead36d84500f225001912ad594be5104d67c0743e0",
    );
    expect(
      BytesUtils.toHexString(bulletProof.b),
      "95720e96af6ee051b65a51de0630845a4b281dd186f93e92bd8a3d7ab400a616",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r1),
      "3afd885d0df9464ab42e199b451a0ab9f891b02b975c960089f50b9d0828a200",
    );
    expect(
      BytesUtils.toHexString(bulletProof.s1),
      "a707d865411ff0455ae5d6fcbbdb7f5c55fa55f1c38a56773dbfbdba26251f0f",
    );
    expect(
      BytesUtils.toHexString(bulletProof.d1),
      "150f347ac4c4efd9e4dbca255774a2ff79edf8b2e7537280e67f239350310509",
    );

    expect(bulletProof.l.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.l.first),
      "4e48b5798082ccaafb5d1506d846a6dc909e6eab94811b59b3d31415f2703c35",
    );
    expect(
      BytesUtils.toHexString(bulletProof.l.last),
      "b50def7c3b8018170cafa41832012464a1b7baa1545f329807e0ea9496f0f085",
    );

    expect(bulletProof.r.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.r.first),
      "bf68b211af472ce847ae5ca605b9355b3110e851a99786d5713e82123f735cee",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r.last),
      "479704b117b6b3e2cec361faf75b896f9215d711d0584ce09dd3c36e9dd5e772",
    );
  });
}
