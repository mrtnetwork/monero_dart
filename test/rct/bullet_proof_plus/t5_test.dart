import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/tuple/tuple.dart';
import 'package:monero_dart/src/crypto/models/ct_key.dart';
import 'package:monero_dart/src/crypto/ringct/utils/generator.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/models/transaction/signature/rct_prunable.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:test/test.dart';

void main() {
  _test();
}
void _test() {
  test("range proof padded bulletproof", () {
    const rands = [
      "39cc226af47412adc2c4e90c6602d03b7ecc9b40f90ed0a721bb91ccde289d0f",
      "f741abc99f88a745102205fedb6f74c1ee64d86a22a76eb0bf296b109b26e20b",
      "c41712d7d01e5f2817e38f1b3472da4bba4f2e342800d8f3d277f12ad996a30c",
      "bdf6171a1cb53971c8bf2a8ab5870032e388a9edd6caf19160f0b9c821c4b900",
      "221c136827a3ea2ba13f206248d1384912afaa6922195d002d28c3c13993a509",
      "c3f3c101944e854199d610999b3114617babf42cbb5b105390f86d891a76cf01",
      "86a05639da599882f8ca83a478ec480b635d28ad0581efc16de95f76c6763203",
      "2f53939457130fda57adbe63cf1ef42c19e93a3823a6c7f598685ef1253dd301",
      "16380b89d2da44ffbf3f96f3ecae0530d98b5ceac24fcb786be6feb96ed67f0b",
      "3b373ae827679f4f3cdc553539bc0a96900d91f6ecb989fe70775e0870905903",
      "dcfa4dcbc0740b0eae91fcaf646b4bc0a6a3b87fb1d882ce178eeb06901df908",
      "4cfe20e0d0e399a0057dc64d622e359ed9e4eba372573cb70cc5d93608d9c507",
      "c0f1b9acae9f346471a394a2f67b921ec0b329d6a50302df077b42b177e4c702",
      "28a66bfcc42baf075c3e86618b3734d90bfb6a63ed16fc694989edf477c6ce0b",
      "3264f38d82db548582ae8192d06474e9c0b8b273a71d13b1dc6d2c7327287d01",
      "974c7b1ac09acfcfe02e7536f546f4baa4f5e8ce80c51f200573d02c8698c103",
      "a5570d9e842ab2225734de2bc3860891752d90199cff7f8122c5e0adc6fdb00d",
      "be9aede30b9c49df74dd88f29aa60d935a62885aecb5887d8b0af47ca8b41806",
      "df64a7c789a0c4257c94dce59f08f7e5cfcd7ff038721e0a4bdd160d16905507",
      "2838f110edf7a3160ffff0dff0c3299fe3438390b71366bbfc1d6e2a015ff501",
      "9090cfbd8800d6f3fbc2aac1447471940f5443c0af2e7b51bf93c1ddd56c210b",
      "432ccf257c1070710b2efc76546964ce482f65856a883d7a87e414a593cef80e",
      "eb348f0e051e2adf061bc7ed28324b16a325537b60f1b9d2b79233121eb0ec05",
      "7e8afef275031d5a2af7fc1a09a9ec9259f2c2a94f5e1bcebb4d48a2cd796d00",
      "f8886892ec0a7f3821dbfd40561665773431418aadf8002a96f10e605fc85907",
      "fc1a1b307a9a3d4ac1551d08de2607677faea8cf7ebe6f75227ae65b81ab530f",
      "79aacbd2189606de28d6e4ee02700b113e1202f441f2266d6bb1b178e8f2800a",
      "2973a5b44fa9d9dbfd0b51114db2c20209defd3fb73aacaeaba360ef74dc900f",
      "9916bcd3ed0788ca9d5c2293ae08f5757372752a75a219968c9094b448f3ba00",
      "eed25df33f38a6a96f0d92e865ccab39395ef8a5135293adb94b0edae4ddab07",
      "4bcd3085fc5294c3560e819caf37cac2456e011cad6a0c9872e34ae268a1000e",
      "1682ef5f3a9de1286dc7b2efd6832f062deafe2801f58680b9b6d6ccd91b8602",
      "b3fdfc5883ec8e79dab43eaad99aed8fd1fbfef40d33e633194226090bad3d09",
      "6b0dd07be16308bbb20732cf37553f0d7c63d02fe9a2d8e8d004d469eabe3407",
      "16ac6b594b1a276b756ecab7df5126e9108d04b5f77fec90565ba23482c72d0d",
      "169632d916bbbcc247b15dd3c057e365c98c120eac11fcd97e0b37e02f6da607",
      "5cca49856cc049b3e894fe1e2981d51fa20bc6d60dc11a889cc8723cf895c70a",
      "89f4fb5c4d29a5deccfef89bc66f7d092fd2c3f59bafde60947d472fc3ab9009",
      "7496e1b36d7437003e7681efe611c789d44deb85ec38d3daf6ccb7bd29192108",
      "20b061dc0395b856c85b3af960c67fe42e5579ee4f60c4f93822ebf406098a00",
      "302336a4123e61abd65c01aca6e8d2ebcf1730a6eda5d4d7480f173b8b366c08",
      "090dddbc861a2b2316cd1d9cddd9feb6112835d30155736246e2df8af0c83c02",
      "7569b31c5a1f83a78b9de11345178380db4e7d622e950293f62833ec201ca602",
      "eaf6e15896e916bc8199cefb5a31386ac3ccdadfb4c38d67a7aa43d767178707",
      "37889c93be2228708bb0206e1618a7fb26c5d979231cae0ebab67d2a222b4c0d",
      "8edc17c4b9b905b01fe1925e0c44afda873dcfbb02b9cf54c8dac2bf51ebf509",
      "5b5d420f82910037a400535ee4d954ca52c1240eed7484de616374afddc91902",
      "c84bcaaae989dd0036f1d3804e8b5e9b846b8e586bfc3830d57491520444bf0a",
      "73e5ee8e07c67f1b737b037c0ac32bcc3588b06a10ad7f134ab2965874b32706",
      "1c0b74d015fa62eb842be560a3d8f907866e2b685fa9dec2c07cce0415726408",
      "28c9c7e36a6e515e4fdc3b1494eece49a9667cea8f5dd22dd833b1eee36faa03"
    ];
    int index = 0;

    QuickCrypto.setupRandom(
      (length) {
        if (index >= rands.length) {
          index = 0;
          assert(false, "should not be here!");
        }

        return BytesUtils.fromHexString(rands[index++]);
      },
    );
    final List<BigInt> inamounts = [];
    final CtKeyV sc = [], pc = [];
    // CtKey sctmp, pctmp;
    inamounts.add(BigInt.from(6000));
    Tuple<CtKey, CtKey> f = RCT.ctskpkGen(inamounts.last);
    sc.add(f.item1);
    pc.add(f.item2);
    inamounts.add(BigInt.from(8000));

    f = RCT.ctskpkGen(inamounts.last);
    sc.add(f.item1);
    pc.add(f.item2);
    final List<BigInt> amounts = [];
    final KeyV amountKeys = [];
    // add output 500
    amounts.add(BigInt.from(500));
    amountKeys.add(RCT.hashToScalar_(RCT.zero()));
    final KeyV destinations = [];
    final RctKey sk = RCT.zero(), pk = RCT.zero();
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());
    amounts.add(BigInt.from(12500));
    amountKeys.add(RCT.hashToScalar_(RCT.zero()));
    RCT.skpkGen(sk, pk);
    destinations.add(pk.clone());

    ///
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
            mixin: 3);

    final verify = RCTGeneratorUtils.verRctSimple(sig);
    expect(verify, false);
    expect(sig.signature.message, RCT.zero(clone: false));
    expect(sig.signature.mixRing?.length, 2);
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].first.mask),
        "72f4a110fcb45c3bfcb3f0411d1cfc4543e38aa3c665d9275a6ffdfb8cf55b9b");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].first.dest),
        "12d8bb509e8dc7442326d689f9c5afd5dc25412173eb683bf3004c2bfe171c0a");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].last.mask),
        "744db2e45a414030ab6d78c74775cae4f61bf4e0ffbb775c02bf48df705a7848");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].last.dest),
        "92217754975c4168ce6250122bd7be74d08f0344b7e2c3701b21851989ec0395");

    // // ///
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].first.mask),
        "fe71981b99b1cfcf55c919199179ca19a5755d449fd73c7ace4282b69a004ed4");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].first.dest),
        "b2b0d78d6f0b7cc7c99a6240d47898e6a3294bbc0f1bf4bcc0fce24fd7faea36");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].last.mask),
        "c12ecde2af4f91eb2081873f60331b71d5f8d0ed118bd097c9e2d21092851bad");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].last.dest),
        "20d483866b1b467c6090ea466d16ba7c6c7164ef106ecfa3940158fbe2ada2d4");
    expect(sig.signature.txnFee, BigInt.from(500));
    expect(sig.rctSigPrunable!.pseudoOuts.length, 2);
    expect(BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[0]),
        "3cb80bebcb6faf5d048dd297cbd1877de16bda6c863ebcadb1a904047448ad79");
    expect(BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
        "9a8fa542a16c7d3ae00a03a451180960f7c32fa8b52bf1e501748fcc7f031ba5");
    expect(sig.signature.outPk.length, 3);
    expect(BytesUtils.toHexString(sig.signature.outPk[0].mask),
        "21843920f19aaf8fef33717b3e190f13d5c10029ecb94d8ecd89cd8e1a3dec25");
    expect(BytesUtils.toHexString(sig.signature.outPk[0].dest),
        "568bc5d958e1b2f3d85ed4db62716c9386a5b48d8d5a5197ebde4308db7843ef");
    expect(BytesUtils.toHexString(sig.signature.outPk[1].mask),
        "28504fe8e30934fa2c401bf84ffc80b1f9738fdf833043e40d8c1a9dce45eedb");
    expect(BytesUtils.toHexString(sig.signature.outPk[1].dest),
        "98ff2eac3f11046cfc965f3365d0d978bcc4eead364b96bd59c0b2eb55716847");
    expect(BytesUtils.toHexString(sig.signature.outPk[2].mask),
        "1d43fc74457b9664f48e425ce69d991479b371bd30c89fad9da28644137333ec");
    expect(BytesUtils.toHexString(sig.signature.outPk[2].dest),
        "20e281bd9969f1674f383505633b3d934808d71a35fa733eba11a697ab84f4f9");
    expect(sig.signature.ecdhInfo.length, 3);
    final ecdhInfos = sig.signature.ecdhInfo.cast<EcdhInfoV2>();

    expect(
        BytesUtils.toHexString(ecdhInfos[0].amount),
        "33ad6ebab7c67708000000000000000000000000000000000000000000000000"
            .substring(0, 16));
    expect(
        BytesUtils.toHexString(ecdhInfos[1].amount),
        "139c6ebab7c67708000000000000000000000000000000000000000000000000"
            .substring(0, 16));
    expect(
        BytesUtils.toHexString(ecdhInfos[2].amount),
        "2faf6ebab7c67708000000000000000000000000000000000000000000000000"
            .substring(0, 16));
    expect(sig.rctSigPrunable!.bulletproofPlus.length, 1);
    expect(sig.rctSigPrunable!.bulletproofPlus[0].v.length, 3);
    final bulletProof = sig.rctSigPrunable!.bulletproofPlus[0];
    expect(BytesUtils.toHexString(bulletProof.v[0]),
        "7de665bfc6c98a0b4d8d69121646fa6e70d009455d67c6d98995a3fe0c72c8df");
    expect(BytesUtils.toHexString(bulletProof.v[1]),
        "f69799725178d91b2ece233b7ccf19d8f558c5970ec39427a1022098ae6e5ef5");
    expect(BytesUtils.toHexString(bulletProof.v[2]),
        "87afd52d1cadb5bba5e8417f8f024700b16b124b3d725e83e881f4399e82ecb4");

    expect(BytesUtils.toHexString(bulletProof.a),
        "9c7a477dfa758ac0c42de5afc6fae3e2a71e5bd098f05409a3f8bebf45a62e2c");
    expect(BytesUtils.toHexString(bulletProof.a1),
        "3b5a0302f8e1a15ff0f97de42466b1de59e0823bdf2909d09673b7f9fb594599");
    expect(BytesUtils.toHexString(bulletProof.b),
        "b54c03fbc95b38770c5550db2d35b88c27189fd346be7d33ebe39c293657786a");
    expect(BytesUtils.toHexString(bulletProof.r1),
        "d7f73374e70880494b3454161ebcf00b07af3cbb6b37f603ca5a4e21ed56b30f");
    expect(BytesUtils.toHexString(bulletProof.s1),
        "83a809e4b8aec34d264fc5cd1dc192569de3394980d98cac2dff8b7be669f70d");
    expect(BytesUtils.toHexString(bulletProof.d1),
        "003d3688dd86f3e8ce3fbf939af09b7209ab971a811565f8eeca556d50967601");

    expect(bulletProof.l.length, 8);
    expect(BytesUtils.toHexString(bulletProof.l.first),
        "944432498e7de94e3c9ab9d425fac26467e61cf3be0534fe5fd811227c85b608");
    expect(BytesUtils.toHexString(bulletProof.l.last),
        "2a74bb49d27425ddcccb996082277a18fa30f4fd532e240b7265757df4eef95e");

    expect(bulletProof.r.length, 8);
    expect(BytesUtils.toHexString(bulletProof.r.first),
        "b9cf2c3d829d1ea575f2ee6b379276ae8c3359af2d25d81c6ae1c410bd3a803a");
    expect(BytesUtils.toHexString(bulletProof.r.last),
        "600c05603931ee1c92f75fe2f76ac1b797eac78c6da742717349332caade24ab");
  });
}
