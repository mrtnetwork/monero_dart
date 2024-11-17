import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import 'package:test/test.dart';

import 'derive_public_key_test_vector.dart';

void main() async {
  test("generate key image", () {
    for (final i in keyImage) {
      final publicKey =
          MoneroPublicKey.fromBytes(BytesUtils.fromHexString(i["publicKey"]));
      final secretKey =
          MoneroPrivateKey.fromBytes(BytesUtils.fromHexString(i["secretKey"]));
      final excepted = BytesUtils.fromHexString(i["keyImage"]);
      final keyImage = MoneroCrypto.generateKeyImage(
          pubkey: publicKey, secretKey: secretKey);
      expect(excepted, keyImage);
    }
  });
}
