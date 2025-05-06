import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  test("description", () {
    final rct = RCT.scalarmultKey(
        RCT.scalarmultKey(RCTConst.h, RCTConst.invEight), RCTConst.eight);
    expect(rct, RCTConst.h);
  });
  test("scalarmult8/identity", () {
    final mult = RCT.scalarmult8_(RCT.identity());
    expect(mult, RCT.identity());
  });
  test("scalarmultKey/scalarmult8", () {
    final key = RCT.scalarmultKey(RCTConst.h, RCTConst.eight);
    final r = RCT.scalarmult8_(RCTConst.h);
    expect(r, key);
  });
}
