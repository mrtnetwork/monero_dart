import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

import 'tools.dart';
import 'package:blockchain_utils/helper/helper.dart';
import '../../utils.dart';

void bulletproofsPlus6() {
  test("range proof padded bulletproof plus RangeProofPaddedBulletproof", () {
    installSeededTestRng();
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
    amountKeys.add(RCT.hashToScalar(RCT.zero()));
    final KeyV destinations = [];
    final RctKey sk = RCT.zero(), pk = RCT.zero();
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());
    amounts.add(BigInt.from(13500));
    amountKeys.add(RCT.hashToScalar(RCT.zero()));
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());

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
    expect(verify, true);
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

    // // // ///
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
      "02287779caa358579ba590219624841c2fee759bf377cd6d9666bd81b545c7a6",
    );
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
      "62d3e8c339c39193f7838e8d6f5bc50da42d197e85c131e290bfd32d6e557ef4",
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
      "d8697a3858fbb639c3ca692c4cc81c72c0f45d99fabe46f2ca34067147cc98b1",
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
    expect(BytesUtils.toHexString(ecdhInfos[1].amount), "7b986ebab7c67708");
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
      "10f44612272545f0a17c3e00cb6659806743a9c6321befec72f0db7dd372d1f9",
    );
    expect(
      BytesUtils.toHexString(bulletProof.v[2]),
      "87afd52d1cadb5bba5e8417f8f024700b16b124b3d725e83e881f4399e82ecb4",
    );

    expect(
      BytesUtils.toHexString(bulletProof.a),
      "d0127dc6df6e6e039d8061dc019bd0029b4f05fd80601692e1820d42f8706644",
    );
    expect(
      BytesUtils.toHexString(bulletProof.a1),
      "f146219cff81b5b989cd6b073af643470a41fb73fc63b0fab80217b05524b7d7",
    );
    expect(
      BytesUtils.toHexString(bulletProof.b),
      "c1266a454097a97ee90c68aa4250d261534e6719e33e46c9fd07b9af11e24e0a",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r1),
      "defdf3efe07bfe4c67ff15530dd6ab10c33327f1491ccf184c3bd4629a6fa500",
    );
    expect(
      BytesUtils.toHexString(bulletProof.s1),
      "377abc66065491ed8168b944ed489cf29098d6b174d09989249b6c700187fd04",
    );
    expect(
      BytesUtils.toHexString(bulletProof.d1),
      "dbb9947a4f57ce8ce0eb08992031558786aa7ac547aee5f40d0249b8c83bf80e",
    );

    expect(bulletProof.l.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.l.first),
      "90092f0011b32679af37979544c8a703978bacc6f300c1cbadcb5e54ba399340",
    );
    expect(
      BytesUtils.toHexString(bulletProof.l.last),
      "19fd7468cfe21c32b3e23fcebc4018823bd3fd2fbd733963cf6bfa6231a4e7b4",
    );

    expect(bulletProof.r.length, 8);
    expect(
      BytesUtils.toHexString(bulletProof.r.first),
      "3b17ab66b87bf3fc549f78a3410e9f32a4fc8157225c8a7ea9828f3859db581b",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r.last),
      "2bd0c832844f039affd9611f6ec7212f507070ab9a1036e936ba15725e03cc2e",
    );
  });
}
