// ignore_for_file: unused_element

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
  _testOne();
}

void _testOne() {
  test("range proof padded bulletproof", () {
    const rands = [
      "6d11a86d45f515d1083986429301e40b42210acb7790857f15e7affef1cfdc0d",
      "3fd38246f2d90fe582db8094a4f837fcefb78ddbde1bae8b303123718d049b06",
      "b49a57619c362fa10ea5ce899d7b84f88a2024f19bfd487f43b636f6eed22004",
      "b8729f6b0d827face9221d023e02d69c8be17dd81d203fd4f62f18de1f43cb00",
      "1cd6e683c2f9c55a29ff8dfebfa9a0f42e625acf2777bdb3938175e54ad68b06",
      "baf93f66c9446d0a580fb062d6bcdda648c9a50961d690fb43abe2825adb9304",
      "1bec0d5ee729307cc360370679588778827081c89b73f85893b17dfcecc64a06",
      "bbb387e03a3145f70db63a030aae0aca2a10964d5dea5c82b6c8bfc275bf790d",
      "37cf36aeecb601b2459653e98e953da644aedd718a26bcdb0f6580d437961505",
      "bc26183ea9a85e27a92338b9bd1ef24fb7afd89ac7b3acf214e7219365350d09",
      "f69f9722631996a8f5e9a12fed9e8fcc610f75fd44a24e7c3e9b03252b3dd30e",
      "6c651e49cacdbf05487beae5007e2d2e04a18dc4126698dc637b8563056fab0a",
      "11a15bcc2f96534c403f74393a64a02c48264b48e8d25eba30bdeea0e5d8580a",
      "b7ee019dbde3f1393b26f4e7abee147884120abf5576abfc124deb36f1158b0c",
      "b85473c085df757877fa8509d0868b243800008c9f7a01b5824b296f72f2fd05",
      "8c1b22dcdf05169f6d85db07c4af8e4661abe52185c62b653033a8c8c4e11504",
      "442e77d315b38402acc6527c92b2950470945dd08646d56a881fa3a75f25a601",
      "e4a8e30fbb37810a7518cd6f34cfeb27811af252c1646c2bfbf97bce0288aa0b",
      "c1887acc67e034ce4f8b1511382475373288e7c830b33e28b77175c8ce727e07",
      "698fb19e1138be6dbd50592227097d14bd942956b6bed5eb71135930d8d99809",
      "ef205f16f6d92537164b61aa4f6b9db3d033780b5900f44e9aab60cdb3ceda09",
      "e2601447905f7842925edf8f1b947f81920a88482363898f170566c2d055d30e",
      "a692a271ef23f63bffd18a6e3feb15856eb314be98291d2a9e0ad0b4b7179706",
      "1a18339ceebd2eba3a9ebeb845c1de64c238b6cdb2eef7a122b655068cda830a",
      "8afb29f178def62773036223943ae2dd282e28706c9426155eb9256c88565b08",
      "825fbadca58d956a03a8d87eebb6092ec0fc8727acb200b824c95ed313d9420d",
      "4b75b488f6777382a8525d5cef3895c076b7543e2160d26a34aa846d8a4d140c",
      "bcc99f6362af71f89a02aabbbfae649be18a444193188b15f5d01dc48935f902",
      "ee999496ad8de8f4896c368d9d89586d2e14ea8e3883d920e03e5675fb94a109",
      "d79ac8eb3d70f563fd9888224346f904367e78db8eafa8b7032a24494460780e",
      "552127f50ed94d35c4b016b68c00d7cd350e19a19858468c4986dc152d8d2c03",
      "a7557833d456606fcf3bbf06fc5fbf6f47d696b81ef4ea74f77e4ba1e3990603",
      "fe5bab378ab78b04d1886e2dc25d287a04b3a8eb1467e46ff075f27f0fe48705",
      "61666797aef58bbe43ca481af044dd447098495cea23d8d63d056da32603d70b",
      "2a5b67a832fde3f36e1817e38aeea69ca55289f86235f1507ef09a60eb49e700",
      "3f84cb53c0404f6eef18f58d85aa9a0d0caf0e99b4e6b9062dd8775c52a2c301",
      "a84eeac3584c52de0d2dd2063faffc6b54cab0ec4f72018bf725f55f8254aa0e",
      "55be476db2cff166f027e0a95278ce501fdbd4271c38b36fc5361530f758510e",
      "70437a8ca3625f8f0e11686ca41575892a1345d5c506a0c7ec40e37313216508",
      "3bae7f7df2848e0a29868908c5c7522421e064341ca5dc648f35926378ab2a04",
      "7437cf385bf11bee53ad0bb3996e08f6816d0836325c4da4de5df47a5b224c00",
      "eaae6940c54faf90816b88d9887a1038fc46a168afa2405c0f9f4c2796db8a00",
      "60cf19dda104371a6412d6c30087ff2c899d32df522c8903a3fd2ee484adbd00",
      "8e46a8c4bda13475b5aa002da8f08b63ec978eca85daba746b3480b2621cde0a",
      "381cbd6c671e13836df62628366b8c6e331d160da0695d495db842f3b16a4f0b",
      "dd0a438d652e7ab936c1155accfc8774fef439b647022c3ddb3350e70395f50d",
      "e1a74194f751ab154859ee1952d9a1b4972c382fe0ae68edb02b7acbbd81f805",
      "b8844bebc2d1e0fa25bab53e0ea0e03216eadcaa4a4317006d6103790a878e04",
      "65977e1881ff254d0c017525984f12b7ce60daebba58bed1ed907a2eb1da870a"
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
    inamounts.add(BigInt.from(7000));

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
    );

    final verify = RCTGeneratorUtils.verRctSimple(sig);
    expect(verify, true);
    expect(sig.signature.message, RCT.zero(clone: false));
    expect(sig.signature.mixRing?.length, 2);
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].first.mask),
        "4ef28b572bf778530c02988864f1b547a28b29aeb4f2c986e0e32f5ea7ccc0f9");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].first.dest),
        "540e6fc0cab0e3a610f1da976ddea9998cfc9d2dd8e1361668b7705c19f790ec");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].last.mask),
        "a820b048c58d33970389f3df5cd184c75f37bc058b793b6fcc76ae2b140bd167");
    expect(BytesUtils.toHexString(sig.signature.mixRing![0].last.dest),
        "86f05e82dc687ace15de4f6ab64d43ded9197fa2e90fd99cc117f2199c34ca3e");

    // // ///
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].first.mask),
        "7ff437613e0cc229e50796c7acb254707133dd998db1f427bdc855621b7eb2fd");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].first.dest),
        "198414ea61cdb7cf1321fbf4584797690352143064a461202432ff6be28d0451");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].last.mask),
        "77c568ea2bbea116952ce3999bbd99b31ab4564826e1df40c52458429f9f7086");
    expect(BytesUtils.toHexString(sig.signature.mixRing![1].last.dest),
        "dea511a7d7d3605d7b02ff6049038f81f108440623756c71615664fe2c23b5d5");
    expect(sig.signature.txnFee, BigInt.zero);
    expect(sig.rctSigPrunable!.pseudoOuts.length, 2);
    expect(BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[0]),
        "ff6a3868318415d80d58481108a0698338654cf40c3b65b62bc2ecdb7db253e5");
    expect(BytesUtils.toHexString(sig.rctSigPrunable!.pseudoOuts[1]),
        "40e612af2893861d24f5812eba8454e9f0658fd9e068d7a1746a7e057de063c7");
    expect(sig.signature.outPk.length, 2);
    expect(BytesUtils.toHexString(sig.signature.outPk[0].mask),
        "21843920f19aaf8fef33717b3e190f13d5c10029ecb94d8ecd89cd8e1a3dec25");
    expect(BytesUtils.toHexString(sig.signature.outPk[0].dest),
        "7574564e93668dd3df187abcd1607c02d0e80358f3fb4837a7a3cdef884fae6d");
    expect(BytesUtils.toHexString(sig.signature.outPk[1].mask),
        "28504fe8e30934fa2c401bf84ffc80b1f9738fdf833043e40d8c1a9dce45eedb");
    expect(BytesUtils.toHexString(sig.signature.outPk[1].dest),
        "81642659730ef8d10f4fa9b18c9dbf45c99ede6ef20f8d3b40ca1305006ca550");
    expect(sig.signature.ecdhInfo.length, 2);
    final ecdhInfos = sig.signature.ecdhInfo.cast<EcdhInfoV2>();

    expect(
        BytesUtils.toHexString(ecdhInfos[0].amount),
        "33ad6ebab7c67708000000000000000000000000000000000000000000000000"
            .substring(0, 16));
    expect(
        BytesUtils.toHexString(ecdhInfos[1].amount),
        "139c6ebab7c67708000000000000000000000000000000000000000000000000"
            .substring(0, 16));
    expect(sig.rctSigPrunable!.bulletproofPlus.length, 1);
    expect(sig.rctSigPrunable!.bulletproofPlus[0].v.length, 2);
    final bulletProof = sig.rctSigPrunable!.bulletproofPlus[0];
    expect(BytesUtils.toHexString(bulletProof.v[0]),
        "7de665bfc6c98a0b4d8d69121646fa6e70d009455d67c6d98995a3fe0c72c8df");
    expect(BytesUtils.toHexString(bulletProof.v[1]),
        "f69799725178d91b2ece233b7ccf19d8f558c5970ec39427a1022098ae6e5ef5");
    expect(BytesUtils.toHexString(bulletProof.a),
        "d7e4baef566673ef08e10f8889a5da7d2c795339019cc61fd2725995435b6b9c");
    expect(BytesUtils.toHexString(bulletProof.a1),
        "8e9c182924bec61d1b0f9a34925266550f0e5d3cae306389daf88cbb7dfbf59a");
    expect(BytesUtils.toHexString(bulletProof.b),
        "03e3350db94d7295f3e35aa96b080341464cc20bc872f217b641997826935bb0");
    expect(BytesUtils.toHexString(bulletProof.r1),
        "3815596d0707a3f92dfc38ae68b3de68bf8dda965e6e78084f356e4afee9f80b");
    expect(BytesUtils.toHexString(bulletProof.s1),
        "75efd30cf2b147633969cfc3d9ab4bb72dc819aa25a417ea0f14da156325b702");
    expect(BytesUtils.toHexString(bulletProof.d1),
        "1019556a696ab738948157bf5cbda5f23155fbf79d86ff41619a3e786370360e");

    expect(bulletProof.l.length, 7);
    expect(BytesUtils.toHexString(bulletProof.l.first),
        "bc3ae0b1f7f767baf928ac4205511cfd579a2b1dd129d1719d59f91f522bbcf9");
    expect(BytesUtils.toHexString(bulletProof.l.last),
        "1a5feff4ee83825426c758a6242363bc39fa3fda20ee5376304f04959e1984ae");
  });
}
