import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';
import '../../utils.dart';

void bulletproofsPlus2() {
  // NOTE: prove runs inside the test body (not at registration): eager
  // proving here stalled browser suite loading on dart2js. The seeded RNG
  // reset stays immediately before the prove, so golden streams are unchanged.
  test("bullet proofs plus 2", () {
    installSeededTestRng();
    final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(
      [
        BigInt.parse("1000000000000"),
        BigInt.parse("20000000000000"),
        BigInt.parse("11882122938912"),
      ],
      [RCT.skGen(), RCT.skGen(), RCT.skGen()],
    );
    expect(
      BytesUtils.toHexString(prove.d1),
      "0ae5b42ca6d53ebff06992cb05aa66c0ee4f89d8bf6be0f18c972618ec1de10f",
    );
    expect(
      BytesUtils.toHexString(prove.a),
      "01c44d9347ff5d92bead15b1a11ac2b421b4e52b6cc33366ee76175ee6a308ad",
    );
    expect(
      BytesUtils.toHexString(prove.a1),
      "9719fefa3d0d476e364667fa34b1bf876a89ef839937405cd3a056111d3fd93b",
    );
    expect(
      BytesUtils.toHexString(prove.b),
      "5463ba662850247eaf88f63a53303bf4569f66aae75b6337804af12148781c86",
    );
    expect(
      BytesUtils.toHexString(prove.s1),
      "b87b4898bde6ecaeab7ec812c9993edc35a84a95611ccc19c3b816d91f6b7200",
    );
    expect(
      BytesUtils.toHexString(prove.d1),
      "0ae5b42ca6d53ebff06992cb05aa66c0ee4f89d8bf6be0f18c972618ec1de10f",
    );
    expect(
      BytesUtils.toHexString(prove.l[0]),
      "e3ac4b08e59f62a2139afacec377a8a0253d3e6e57154b6485f60b3bff9503d0",
    );
    expect(
      BytesUtils.toHexString(prove.l[1]),
      "7302df396abd973110e86198d2c2ac32f54324fbae101cce33e7ed5d9bd03d35",
    );
    expect(
      BytesUtils.toHexString(prove.l[2]),
      "fa94b7a4c0e2336c99f350dbc86a9264867c48d3c0c818236e54b1ad4f989c0c",
    );
    expect(
      BytesUtils.toHexString(prove.l[3]),
      "ec76eb68b379e4edecd72a837437ff9b3304a2359af131d3fb70943546e85d47",
    );
    expect(
      BytesUtils.toHexString(prove.l[4]),
      "e065bcf3550c529eeb0368aac833220bdd2cdf69ad06c16479ea1d1df3c61455",
    );
    expect(
      BytesUtils.toHexString(prove.r[0]),
      "ed1faed90fe1a535b5534d82555b2618a3121c1b316db08d1853437e9a7fcf2d",
    );
    expect(
      BytesUtils.toHexString(prove.r[1]),
      "a14aa066078906514f2e116ba8708c23e3712349213fc0839c50b8fd52894c13",
    );
    expect(
      BytesUtils.toHexString(prove.r[2]),
      "b38899c6e6d74f3af7883434a954f555697ca9f39ffb8237bfa9d001469c7086",
    );
    expect(
      BytesUtils.toHexString(prove.r[3]),
      "8047c0e38bf04d540580f8718ee0fc9dd787dc60abee7faeb2f1a01104bab4e0",
    );
    final verify = BulletproofsPlusGenerator.bulletproofPlusVerify([prove]);
    expect(verify, true);
  });
}
