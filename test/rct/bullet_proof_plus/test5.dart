import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/generator.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:test/test.dart';

import 'package:blockchain_utils/helper/helper.dart';
import 'tools.dart';
import '../../utils.dart';

void bulletproofsPlus5() {
  test("range proof padded bulletproof", () {
    installSeededTestRng();
    final List<BigInt> inamounts = [];
    final CtKeyV sc = [], pc = [];
    // CtKey sctmp, pctmp;
    inamounts.add(BigInt.from(6000));
    (CtKey, CtKey) f = ctskpkGen(inamounts.last);
    sc.add(f.$1);
    pc.add(f.$2);
    inamounts.add(BigInt.from(8000));

    f = ctskpkGen(inamounts.last);
    sc.add(f.$1);
    pc.add(f.$2);
    final List<BigInt> amounts = [];
    final KeyV amountKeys = [];
    // add output 500
    amounts.add(BigInt.from(500));
    amountKeys.add(RCT.hashToScalar(RCT.zero()));
    final KeyV destinations = [];
    final RctKey sk = RCT.zero(), pk = RCT.zero();
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());
    amounts.add(BigInt.from(12500));
    amountKeys.add(RCT.hashToScalar(RCT.zero()));
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());

    ///
    amounts.add(BigInt.from(1000));
    amountKeys.add(RCT.hashToScalar(RCT.zero()));
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
          nativeBacked: false,
        );

    final verify = RCTGeneratorUtils.verRctSimple(sig);
    expect(verify, false);
    expect(sig.signature.message, RCT.zero(clone: false));
    expect(sig.signature.mixRing?.length, 2);
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.mask),
      "006421ae4448a8e6d5efd00cc8f7bd878105a81da75db1e1e35e81c53d30fde8",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.dest),
      "24739fc8049cc1fbeb2e4adcd2ee161a2ea896fea841a876d8a018c30ad46817",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.mask),
      "0f6bbea3afa1782ad6007e3f4cacd3272a51c989eee959fc29b6bf84cfb8733e",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.dest),
      "7522bd0aeb206fb14cc6b3205c63e44df106901c6a6b89fdd48ec9347a6776aa",
    );

    // // ///
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.mask),
      "93bc32fd29f09e2223d98056489d9300b6acbed42fb50f27d8f2203a0e0ed433",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.dest),
      "00749fd572bccde9dad5ab67f0b091825b6c8965cb3e9af8e1a0da9fe23247d1",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.mask),
      "c33885cd455cafdca3d811764cf337d29ebebcdd6aa4f773e9bf6a0be382fe6b",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.dest),
      "abd8095448deb8a56ae2d0b3e66166d9e129138121089d60246cb2f7f8ef52b2",
    );
    expect(sig.signature.txnFee, BigInt.from(500));
    expect(sig.rctSigPrunable!.pseudoOuts.length, 2);
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[0]),
      "34d2b3e6e71f14fefcb24e29255ea953515ce4a5301f37a0740d2f08188bd869",
    );
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
      "dfd9cdf1ea9b6cb8e56634c06bacd5d60d2f529f66446586243cedfecdb5ad5c",
    );
    expect(sig.signature.outPk.length, 3);
    expect(
      BytesUtils.toHexString(sig.signature.outPk[0].mask),
      "21843920f19aaf8fef33717b3e190f13d5c10029ecb94d8ecd89cd8e1a3dec25",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[0].dest),
      "11e4445c7ddc5ec668ef2b5da4fa021dc0945576de6f559e81b4be4295f9e877",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[1].mask),
      "28504fe8e30934fa2c401bf84ffc80b1f9738fdf833043e40d8c1a9dce45eedb",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[1].dest),
      "f3cd2eb58cb0f1f43128eeb948e58735faa848ede026724559381655e166dde4",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[2].mask),
      "1d43fc74457b9664f48e425ce69d991479b371bd30c89fad9da28644137333ec",
    );
    expect(
      BytesUtils.toHexString(sig.signature.outPk[2].dest),
      "6d8bbec54be8724f446797254a13e39283b6a16e1974c1da3d88791309c9da32",
    );
    expect(sig.signature.ecdhInfo.length, 3);
    final ecdhInfos = sig.signature.ecdhInfo.cast<EcdhInfoV2>();

    expect(BytesUtils.toHexString(ecdhInfos[0].amount), "33ad6ebab7c67708");
    expect(BytesUtils.toHexString(ecdhInfos[1].amount), "139c6ebab7c67708");
    expect(BytesUtils.toHexString(ecdhInfos[2].amount), "2faf6ebab7c67708");
    expect(sig.rctSigPrunable!.bulletproofPlus.length, 1);
    expect(sig.rctSigPrunable!.bulletproofPlus[0].v.length, 3);
    final bulletProof = sig.rctSigPrunable!.bulletproofPlus[0];
    expect(
      BytesUtils.toHexString(bulletProof.v[0]),
      "7de665bfc6c98a0b4d8d69121646fa6e70d009455d67c6d98995a3fe0c72c8df",
    );
    expect(
      BytesUtils.toHexString(bulletProof.v[1]),
      "f69799725178d91b2ece233b7ccf19d8f558c5970ec39427a1022098ae6e5ef5",
    );
    expect(
      BytesUtils.toHexString(bulletProof.v[2]),
      "87afd52d1cadb5bba5e8417f8f024700b16b124b3d725e83e881f4399e82ecb4",
    );

    expect(
      BytesUtils.toHexString(bulletProof.a),
      "90a95b8ad4332411e0ac4ea6cbd82b1e2d77b95bb2e83539efc233911c5a2607",
    );
    expect(
      BytesUtils.toHexString(bulletProof.a1),
      "4342d88338a6ca43fc09057eb42c6cb3871f89ea4a9b5d8c3fd9b2a37c8f535b",
    );
    expect(
      BytesUtils.toHexString(bulletProof.b),
      "165d8eba9ee887bca19c353db2bc51462bb8c50f14012e031abe0e0980a71d07",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r1),
      "efd4d748d0b5e8f69a0be25b9b616557d7babdc88594a2d0f9c18ee94e5c5408",
    );
    expect(
      BytesUtils.toHexString(bulletProof.s1),
      "54c6e3c6589c7a04dbf65a166728ee668b49f625e9116b34bd3dbdd273a1a105",
    );
    expect(
      BytesUtils.toHexString(bulletProof.d1),
      "b3e651a16b7fee125378fa0f67b7e80efb8f99931150af208d2939a20e3b4105",
    );

    expect(bulletProof.l.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.l.first),
      "6f3a6ba419a40a2a3ceabcc3c38dbb3b949c98f5a4dd777a2e754be24667e139",
    );
    expect(
      BytesUtils.toHexString(bulletProof.l.last),
      "e33171ef7e64ef4fa206850142b26021cc925871cefe56fc5cb515435258aaf0",
    );

    expect(bulletProof.r.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.r.first),
      "e72dc2b863a912243be4c0e4d8ddec9e6623cd2c0a910bdb804f08c2aab52e91",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r.last),
      "1a61fd9674088a5bc9d48f3303e6ed15b8e5843032cc76011dafb962ae460e28",
    );
  });
}
