import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import 'package:test/test.dart';

import '../utils.dart';
import 'derive_public_key_test_vector.dart';

void generateKeyImageTest() {
  test("generate key image", () {
    for (final i in keyImage.takeShuffle()) {
      final publicKey = ED25519MoneroPublicKey.fromBytes(
        BytesUtils.fromHexString(i["publicKey"]),
      );
      final secretKey = ED25519MoneroPrivateKey.fromBytes(
        BytesUtils.fromHexString(i["secretKey"]),
      );
      final expected = BytesUtils.fromHexString(i["keyImage"]);
      final keyImage = MoneroCrypto.generateKeyImageBytes(
        pubkey: publicKey.keyBytes,
        secretKey: secretKey.takeSecretKey(),
      );
      expect(expected, keyImage);
    }
  });
}

void main() {
  MoneroTestApi.runTest(generateKeyImageTest, "Generate Key Image");
}
