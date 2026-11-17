// ignore_for_file: unused_element

import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/generator.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:test/test.dart';

import 'tools.dart';
import 'package:blockchain_utils/helper/helper.dart';
import '../../utils.dart';

void bulletproofsPlus4() {
  test("range proof padded bulletproof", () {
    installSeededTestRng();
    final List<BigInt> inamounts = [];
    final CtKeyV sc = [], pc = [];
    // CtKey sctmp, pctmp;
    inamounts.add(BigInt.from(6000));
    (CtKey, CtKey) f = ctskpkGen(inamounts.last);
    sc.add(f.$1);
    pc.add(f.$2);
    inamounts.add(BigInt.from(7000));

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
    final RCTSignature<RCTBulletproofPlus, RctSigPrunableBulletproofPlus> sig =
        RCTGeneratorUtils.genRctSimple_(
          message: RCT.zero(),
          inSk: sc,
          inPk: pc,
          destinations: destinations,
          inamounts: inamounts,
          outamounts: amounts,
          amountKeys: amountKeys,
          txnFee: BigInt.zero,
          mixin: 3,
          nativeBacked: false,
        );

    final verify = RCTGeneratorUtils.verRctSimple(sig);
    expect(verify, true);
    expect(sig.signature.message, RCT.zero(clone: false));
    expect(sig.signature.mixRing?.length, 2);
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.mask),
      "2cd7e5e2f467ef792f4228bac118720dcad27e8e89cbbde8a77ec17b4557cfa5",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].first.dest),
      "006421ae4448a8e6d5efd00cc8f7bd878105a81da75db1e1e35e81c53d30fde8",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.mask),
      "fd78ebc813dda59cb09d13bb3f05075d6bffa224e9160ef8c1fb4bbf92a8bda1",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![0].last.dest),
      "0f6bbea3afa1782ad6007e3f4cacd3272a51c989eee959fc29b6bf84cfb8733e",
    );

    // // ///
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.mask),
      "7d7d189e83082ef2cb1bb1088c0c9ec6f115e7a81b1e5faedae5f38037eb0f1b",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].first.dest),
      "93bc32fd29f09e2223d98056489d9300b6acbed42fb50f27d8f2203a0e0ed433",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.mask),
      "997565212c15ba3e970fdaa76236f364267ef43eadf1af58712406f7900843f2",
    );
    expect(
      BytesUtils.toHexString(sig.signature.mixRing![1].last.dest),
      "c33885cd455cafdca3d811764cf337d29ebebcdd6aa4f773e9bf6a0be382fe6b",
    );
    expect(sig.signature.txnFee, BigInt.zero);
    expect(sig.rctSigPrunable!.pseudoOuts.length, 2);
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[0]),
      "43cde181ec1939788769963a51a2d7c3f82179a57bfdaf270c1578192080c673",
    );
    expect(
      BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
      "5c173a5d8d5da5ed4bd3ccbc4b6944676cb323c49e68238b2fd2cbd92e1ba985",
    );
    expect(sig.signature.outPk.length, 2);
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
    expect(sig.signature.ecdhInfo.length, 2);
    final ecdhInfos = sig.signature.ecdhInfo.cast<EcdhInfoV2>();

    expect(BytesUtils.toHexString(ecdhInfos[0].amount), "33ad6ebab7c67708");
    expect(BytesUtils.toHexString(ecdhInfos[1].amount), "139c6ebab7c67708");
    expect(sig.rctSigPrunable!.bulletproofPlus.length, 1);
    expect(sig.rctSigPrunable!.bulletproofPlus[0].v.length, 2);
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
      BytesUtils.toHexString(bulletProof.a),
      "e515215e61ca421e5b63de2a2be56e4b6e21ce2384f218cf2c895812ba828e7d",
    );
    expect(
      BytesUtils.toHexString(bulletProof.a1),
      "274a9b90248c2356843176e86b171cc1f98ce71f4e3e25d4bd02b4227f93d515",
    );
    expect(
      BytesUtils.toHexString(bulletProof.b),
      "de70412c1260c4ca70d038034898aa7c3f149f2cf7e8cf611380dee4d696aeb8",
    );
    expect(
      BytesUtils.toHexString(bulletProof.r1),
      "39b4d0032afd1b42434429b18cf8af2187e6b1d2c72b3e48081fca17a6280300",
    );
    expect(
      BytesUtils.toHexString(bulletProof.s1),
      "89a3288a48cff7054779ea9ee35bae15c567fb9a17b75e975c6e4dc28095ee05",
    );
    expect(
      BytesUtils.toHexString(bulletProof.d1),
      "1a8c7023652ac3e971b2bccf95b545dafeaef0ae00328058f232330362e8ec0b",
    );

    expect(bulletProof.l.length, 7);
    expect(
      BytesUtils.toHexString(bulletProof.l.first),
      "0677689f5c606cc42f7f69476007604a97615d8d1cb582df3d882963eaa81720",
    );
    expect(
      BytesUtils.toHexString(bulletProof.l.last),
      "f3fa26eb95522c76fd321e882622c5174a77aa4d485eb7b93c7ad131ebb27d0f",
    );
  });
}
