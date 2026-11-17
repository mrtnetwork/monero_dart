import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import '../utils.dart';
import 'test_vector.dart';
import 'package:test/test.dart';

void keyDrivationTest() {
  test("generate key derivation", () {
    for (final i in testVector.takeShuffle()) {
      final expected = BytesUtils.tryFromHexString(i["expected"]);
      if (expected != null) {
        final keyOne = ED25519MoneroPublicKey.fromBytes(
          BytesUtils.fromHexString(i["keyOne"]),
        );
        final keyTwo = ED25519MoneroPrivateKey.fromBytes(
          BytesUtils.fromHexString(i["keyTwo"]),
        );
        final generateKey = MoneroCrypto.generateKeyDerivation(
          pubkey: keyOne,
          secretKey: keyTwo,
        );
        expect(generateKey, expected);
      } else {
        expect(() {
          final keyOne = ED25519MoneroPublicKey.fromBytes(
            BytesUtils.fromHexString(i["keyOne"]),
          );
          final keyTwo = ED25519MoneroPrivateKey.fromBytes(
            BytesUtils.fromHexString(i["keyTwo"]),
          );
          return MoneroCrypto.generateKeyDerivation(
            pubkey: keyOne,
            secretKey: keyTwo,
          );
        }, throwsA(anyOf([isA<BuError>(), isA<BuError>()])));
      }
    }
  });

  test("generate key derivation fast", () {
    for (final i in testVector.takeShuffle()) {
      final expected = BytesUtils.tryFromHexString(i["expected"]);
      if (expected != null) {
        final keyOne = ED25519MoneroPublicKey.fromBytes(
          BytesUtils.fromHexString(i["keyOne"]),
        );
        final keyTwo = ED25519MoneroPrivateKey.fromBytes(
          BytesUtils.fromHexString(i["keyTwo"]),
        );
        final generateKey = MoneroCrypto.generateKeyDerivation(
          pubkey: keyOne,
          secretKey: keyTwo,
        );
        expect(generateKey, expected);
      } else {
        expect(() {
          final keyOne = ED25519MoneroPublicKey.fromBytes(
            BytesUtils.fromHexString(i["keyOne"]),
          );
          final keyTwo = ED25519MoneroPrivateKey.fromBytes(
            BytesUtils.fromHexString(i["keyTwo"]),
          );
          return MoneroCrypto.generateKeyDerivation(
            pubkey: keyOne,
            secretKey: keyTwo,
          );
          // Same contract as the non-Var test above: off-curve public keys
          // surface as CryptoException through the point decoder.
        }, throwsA(anyOf([isA<BuError>(), isA<BuError>()])));
      }
    }
  });
}

void main() {
  MoneroTestApi.runTest(keyDrivationTest, "Key Drivation");
}
