import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/exp.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import 'test_vector.dart';
import 'package:test/test.dart';

void main() {
  test("generate key derivation", () {
    for (final i in testVector) {
      final expected = BytesUtils.tryFromHexString(i["expected"]);
      if (expected != null) {
        final keyOne =
            MoneroPublicKey.fromBytes(BytesUtils.fromHexString(i["keyOne"]));
        final keyTwo =
            MoneroPrivateKey.fromBytes(BytesUtils.fromHexString(i["keyTwo"]));
        final generateKey = MoneroCrypto.generateKeyDerivation(
            pubkey: keyOne, secretKey: keyTwo);
        expect(generateKey, expected);
      } else {
        expect(() {
          final keyOne =
              MoneroPublicKey.fromBytes(BytesUtils.fromHexString(i["keyOne"]));
          final keyTwo =
              MoneroPrivateKey.fromBytes(BytesUtils.fromHexString(i["keyTwo"]));
          return MoneroCrypto.generateKeyDerivation(
              pubkey: keyOne, secretKey: keyTwo);
        }, throwsA(isA<SquareRootError>()));
      }
    }
  });

  test("generate key derivation fast", () {
    for (final i in testVector) {
      final expected = BytesUtils.tryFromHexString(i["expected"]);
      if (expected != null) {
        final keyOne =
            MoneroPublicKey.fromBytes(BytesUtils.fromHexString(i["keyOne"]));
        final keyTwo =
            MoneroPrivateKey.fromBytes(BytesUtils.fromHexString(i["keyTwo"]));
        final generateKey = MoneroCrypto.generateKeyDerivationFast(
            pubkey: keyOne, secretKey: keyTwo);
        expect(generateKey, expected);
      } else {
        expect(() {
          final keyOne =
              MoneroPublicKey.fromBytes(BytesUtils.fromHexString(i["keyOne"]));
          final keyTwo =
              MoneroPrivateKey.fromBytes(BytesUtils.fromHexString(i["keyTwo"]));
          return MoneroCrypto.generateKeyDerivation(
              pubkey: keyOne, secretKey: keyTwo);
        }, throwsA(isA<SquareRootError>()));
      }
    }
  });
}
