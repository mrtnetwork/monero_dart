import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  _multAdd();
  _scalar();
  _multBase();
}

List<int> scReduce(List<int> key) {
  final k = key.clone();
  CryptoOps.scReduce32(k);
  return k;
}

void _scalar() {
  test("scalar reduce", () {
    for (int i = 0; i < 10000; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = scReduce(rand);
      final scOld = Ed25519Utils.scalarReduceVar(rand);
      expect(sc, scOld);
    }
  });
}

void _multBase() {
  test("mult base", () {
    for (int i = 0; i < 100; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = scReduce(rand);
      final scBig = BigintUtils.fromBytes(sc, byteOrder: Endian.little);
      final mult = Curves.generatorED25519 * scBig;
      final p3 = GroupElementP3();
      CryptoOps.geScalarMultBase(p3, sc);
      final p2 = GroupElementP2();
      CryptoOps.geP3ToP2(p2, p3);
      final tb = CryptoOps.geTobytes_(p2);
      expect(tb, mult.toBytes());
    }
  });
}

void _multAdd() {
  final add = EDPoint.fromBytes(
    curve: Curves.curveEd25519,
    data: BytesUtils.fromHexString(
      "e604ed48048c124f8dd492deca78714c1296da13c63aa0e3a0124458602a0ac3",
    ),
  );
  test("mult base + p", () {
    for (int i = 0; i < 100; i++) {
      final rand = QuickCrypto.generateRandom();
      final sc = scReduce(rand);
      final scBig = BigintUtils.fromBytes(sc, byteOrder: Endian.little);
      EDPoint mult = Curves.generatorED25519 * scBig;
      final p3 = GroupElementP3();
      CryptoOps.geScalarMultBase(p3, sc);
      final r = GroupElementP1P1();
      final fefe = GroupElementP3();
      CryptoOps.geFromBytesVartime_(fefe, add.toBytes());
      final cached = GroupElementCached();
      CryptoOps.geP3ToCached(cached, fefe);
      CryptoOps.geAdd(r, p3, cached);
      final rr = GroupElementP2();
      CryptoOps.geP1P1ToP2(rr, r);
      final rrBytes = CryptoOps.geTobytes_(rr);
      mult = mult + add;
      expect(rrBytes, mult.toBytes());
    }
  });
}
