import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

import '../utils.dart';

void opTest() {
  _test();
}

void main() {
  MoneroTestApi.runTest(opTest, "Op");
}

void _test() {
  test("description", () {
    final rct = RCT.scalarmultKey(
      RCT.scalarmultKey(RCTConst.h, RCTConst.invEight),
      RCTConst.eight,
    );
    expect(rct, RCTConst.h);
  });
  test("scalarmult8/identity", () {
    final mult = RCT.scalarmult8(RCT.identity());
    expect(mult, RCT.identity());
  });
  test("scalarmultKey/scalarmult8", () {
    final key = RCT.scalarmultKey(RCTConst.h, RCTConst.eight);
    final r = RCT.scalarmult8(RCTConst.h);
    expect(r, key);
  });
}
