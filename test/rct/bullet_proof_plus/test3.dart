import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';
import '../../utils.dart';

void bulletproofsPlus3() {
  // NOTE: prove runs inside the test body (not at registration): eager
  // proving here stalled browser suite loading on dart2js. The seeded RNG
  // reset stays immediately before the prove, so golden streams are unchanged.
  test("bullet proofs plus 3", () {
    installSeededTestRng();
    final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(
      [
        BigInt.parse("1000000000000"),
        BigInt.parse("20000000000000"),
        BigInt.parse("11882122938912"),
        BigInt.zero,
        BigInt.one,
        BigInt.from(3),
      ],
      [
        RCT.skGen(),
        RCT.skGen(),
        RCT.skGen(),
        RCT.skGen(),
        RCT.skGen(),
        RCT.skGen(),
      ],
    );
    expect(
      BytesUtils.toHexString(prove.d1),
      "5f58809c92c4037e159689af9e6004db23b6abe3a09f6c75aac4965c68fb7303",
    );
    expect(
      BytesUtils.toHexString(prove.a),
      "a26a1c330057d34b47b886e94fd646ce3bd738aaa8f2aba0cf4f354135648188",
    );
    expect(
      BytesUtils.toHexString(prove.a1),
      "1d7e5d4350edc37b048bea43459ed87897e1041839ac6dd8f6650a60e344de03",
    );
    expect(
      BytesUtils.toHexString(prove.b),
      "4a1f39d2a0d8c0fba79754ca28fc23fa5da1d516e139cc948c180cbe4e5ef4b6",
    );
    expect(
      BytesUtils.toHexString(prove.s1),
      "9a63ed6de9c620151f8d173f473a567546b574e84934fcc09c1f50eb33bbdd0d",
    );
    expect(
      BytesUtils.toHexString(prove.d1),
      "5f58809c92c4037e159689af9e6004db23b6abe3a09f6c75aac4965c68fb7303",
    );
    expect(
      BytesUtils.toHexString(prove.l[0]),
      "7645e9a5ff4253aec3626420de5c6e5e4dd3e08f4100a72fae9c445af0457532",
    );
    expect(
      BytesUtils.toHexString(prove.l[1]),
      "594adcf5c2c9bebd1909f01bbd9c6b3ff2678adde3ff4d3445820d7f91c415ee",
    );
    expect(
      BytesUtils.toHexString(prove.l[2]),
      "9140ef3bfa26ae651410f3c4cdd395fdf8c1c18b8512a1ae611ac4f44f6bff35",
    );
    expect(
      BytesUtils.toHexString(prove.l[3]),
      "ab3093165a6f3c9bccafa7a8718f6efd57fda8188739f029fcb77779edc6c438",
    );
    expect(
      BytesUtils.toHexString(prove.l[4]),
      "877439474021e71e262797ebbc1cdf350277cbc2c29ba6b5ffce81b8c91b5886",
    );
    expect(
      BytesUtils.toHexString(prove.r[0]),
      "9eaf1a4a0752e96fc38190bc2d1921735bf60f50ec40b4e6ded77c2f5fcfc97c",
    );
    expect(
      BytesUtils.toHexString(prove.r[1]),
      "613b4d3f450ab8433aedfd70cbb050193ca2efedf848caac8aac109b55e0a053",
    );
    expect(
      BytesUtils.toHexString(prove.r[2]),
      "c83140b1acaccc2425f45780fe78ea5037e2ef47c88951066adfd8c3f6f7abcc",
    );
    expect(
      BytesUtils.toHexString(prove.r[3]),
      "87b9defbce3ad4545f772ffbc3a45551bdafbefc08b99a4f943a78a1db3c19a0",
    );
    expect(
      BytesUtils.toHexString(prove.v[0]),
      "f0756f9557a618a9d8a3734e33aa4a16b756514c7ba340f76e2ba2a51455adc8",
    );
    expect(
      BytesUtils.toHexString(prove.v[1]),
      "fb214def8d1c966bb34e1def55f666d77e56cf28834b37e2481ca4594a4487d5",
    );
    expect(
      BytesUtils.toHexString(prove.v[2]),
      "831bc360a87fd30a5da0478fe20bf61eba50596c1127baddacc16d0f90d71ab5",
    );
    expect(
      BytesUtils.toHexString(prove.v[3]),
      "ad370c629d7e3c204b0e400a7e86d411adef615a5e89f465d4d9aafcc4915128",
    );
    final verify = BulletproofsPlusGenerator.bulletproofPlusVerify([prove]);
    expect(verify, true);
  });
}
