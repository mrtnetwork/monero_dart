import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/exp.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:test/test.dart';
import 'derive_public_key_test_vector.dart';

void main() async {
  _drivePublicKeyFast();
  _invalidKeys();
  _drivePublicKey();
}

void _drivePublicKeyFast() {
  test("derive public key", () {
    for (final i in derivePublicKeyTestVector) {
      final derivation = BytesUtils.fromHexString(i["derivation"]);
      final int outIndex = int.parse(i["output_index"]);
      final base = MoneroPublicKey.fromHex(i["base"]);
      final expected = BytesUtils.fromHexString(i["expected"]);
      final result = MoneroCrypto.derivePublicKeyFast(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
      expect(expected, result.key);
    }
  });
}

void _drivePublicKey() {
  test("derive public key", () {
    for (final i in derivePublicKeyTestVector) {
      final derivation = BytesUtils.fromHexString(i["derivation"]);
      final int outIndex = int.parse(i["output_index"]);
      final base = MoneroPublicKey.fromHex(i["base"]);
      final expected = BytesUtils.fromHexString(i["expected"]);
      final result = MoneroCrypto.derivePublicKey(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
      expect(expected, result.key);
    }
  });
}

void _invalidKeys() {
  test("derive public key. invalid key", () {
    expect(() {
      final derivation = BytesUtils.fromHexString(
          "d85725562544e1984048391413a6112eb221bd217db3baaa9843bee331000e8e");
      const int outIndex = 66;
      final base = MoneroPublicKey.fromHex(
          "f3148c3041e634d829e5df463ba3b1d64df282d620d63485e1f10024e003b939");
      return MoneroCrypto.derivePublicKey(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
    }, throwsA(isA<SquareRootError>()));
  });

  test("derive public key. invalid key 1", () {
    expect(() {
      final derivation = BytesUtils.fromHexString(
          "6fa161dd958022caf185faf873dd9adbc5578352cda505e84fff7cc99a8762a7");
      const int outIndex = 333934910;
      final base = MoneroPublicKey.fromHex(
          "c2b56e207862958751d49643f23079009092c32bf82179a1295e3b85a385c1c3");
      MoneroCrypto.derivePublicKey(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
    }, throwsA(isA<SquareRootError>()));
  });
  test("derive public key. invalid key 1", () {
    expect(() {
      final derivation = BytesUtils.fromHexString(
          "2c312ef971def53361274c37a90bfde86f959d877a636ea641a9c976ee80c7e3");
      const int outIndex = 121;
      final base = MoneroPublicKey.fromHex(
          "b611ebd2bcfefc81cb772e35e3dd0204575cb0da644f68d4f9828a2683861e6c");
      MoneroCrypto.derivePublicKey(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
    }, throwsA(isA<SquareRootError>()));
  });
  test("derive public key. invalid key 2", () {
    expect(() {
      final derivation = BytesUtils.fromHexString(
          "0fb9110558d1bf0d87284c9bcfd6043bd95022ca52674f06d55e5ea672642bfc");
      const int outIndex = 9;
      final base = MoneroPublicKey.fromHex(
          "431127b1e53e1fcfb299b9a9659fc38be894938306653ff3b218f1c98cf6cb13");
      MoneroCrypto.derivePublicKey(
          derivation: derivation, outIndex: outIndex, basePublicKey: base);
    }, throwsA(isA<SquareRootError>()));
  });
}
