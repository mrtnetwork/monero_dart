import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

void debugTest() {
  _multAdd();
  _scalar();
  _multBase();
}

void main() {
  MoneroTestApi.runTest(debugTest, "Debug");
}

void _scalar() {
  test("scalar reduce", () {
    for (int i = 0; i < MoneroTestConst.iteration; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = EdwardsLimbOps.scReduce32(rand);
      // Idempotent and canonical.
      expect(EdwardsLimbOps.scReduce32(sc), sc);
      expect(Ed25519Fr.fromBytes(sc), isNotNull);
      // Matches wide reduction of the same input.
      expect(EdwardsLimbOps.scReduce64([...rand, ...List.filled(32, 0)]), sc);
    }
  });
}

void _multBase() {
  test("mult base", () {
    // RFC 8032 TEST 1 (clamped seed -> public key) through the limb stack.
    final h = QuickCrypto.sha512Hash(
      BytesUtils.fromHexString(
        '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
      ).toList(),
    ).sublist(0, 32);
    h[0] &= 248;
    h[31] &= 127;
    h[31] |= 64;
    expect(
      BytesUtils.toHexString(EdwardsLimbOps.reduceMultBase(h).toList()),
      'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
    );
    for (int i = 0; i < MoneroTestConst.iteration; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = EdwardsLimbOps.scReduce32(rand);
      final fr = Ed25519Fr.fromBytes(sc);
      // Ladder agrees with the double-and-add-always path on itself is
      // trivial; check homomorphism instead: (a+b)*G == a*G + b*G.
      final other = EdwardsLimbOps.scReduce32(QuickCrypto.generateRandom());
      final ofr = Ed25519Fr.fromBytes(other);
      final left = EdwardsLimbPoint.generator_ * (fr + ofr);
      final right =
          EdwardsLimbPoint.generator_ * fr + EdwardsLimbPoint.generator_ * ofr;
      expect(left == right, isTrue);
    }
  });
}

void _multAdd() {
  final add = EdwardsLimbPoint.fromBytes(
    BytesUtils.fromHexString(
      "e604ed48048c124f8dd492deca78714c1296da13c63aa0e3a0124458602a0ac3",
    ).toList(),
  );
  test("mult base + p", () {
    for (int i = 0; i < MoneroTestConst.iteration; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = EdwardsLimbOps.scReduce32(rand);
      final fr = Ed25519Fr.fromBytes(sc);
      final one = List<int>.filled(32, 0)..[0] = 1;
      final viaLadder = EdwardsLimbOps.doubleScalarMult(
        sc,
        EdwardsLimbPoint.generator_.toBytes().toList(),
        one,
        add.toBytes().toList(),
      );
      final manual = EdwardsLimbPoint.generator_ * fr + add * Ed25519Fr.one;
      expect(viaLadder, manual.toBytes());
    }
  });
}
