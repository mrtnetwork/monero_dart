import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  test("commit", () {
    List<int> result = RCT.zeroCommit(BigInt.zero);
    expect(
        result,
        BytesUtils.fromHexString(
            "5866666666666666666666666666666666666666666666666666666666666666"));
    result = RCT.zeroCommit(BigInt.one);
    expect(
        result,
        BytesUtils.fromHexString(
            "1738eb7a677c6149228a2beaa21bea9e3370802d72a3eec790119580e02bd522"));
    result = RCT.zeroCommit(BigInt.from(10));
    expect(
        result,
        BytesUtils.fromHexString(
            "0380dc24cc97cce658c3a947c51025de1a69803bdb5005e3b7dda90d6859b01c"));
    result = RCT.zeroCommit(BigInt.parse("900000000000000"));
    expect(
        result,
        BytesUtils.fromHexString(
            "613aa12cc0a19bc8436350bbc0f616326e648583334a32651629e905c5206269"));
    result = RCT.zeroCommit(BigInt.parse("10000000000000000000"));
    expect(
        result,
        BytesUtils.fromHexString(
            "658d01376d1863e77b096f98e6e513c20410f5c7fb18a6e59a5266845cd9b1e3"));
  });
  test("description", () {
    final rct = RCT.scalarmultKey_(
        RCT.scalarmultKey_(RCTConst.h, RCTConst.invEight),
        RCTConst.eight);
    expect(rct, RCTConst.h);
  });
  test("scalarmult8/identity", () {
    final mult = RCT.scalarmult8_(RCT.identity());
    expect(mult, RCT.identity());
  });
  test("scalarmultKey/scalarmult8", () {
    final key = RCT.scalarmultKey_(RCTConst.h, RCTConst.eight);
    final r = RCT.scalarmult8_(RCTConst.h);
    expect(r, key);
  });
}
