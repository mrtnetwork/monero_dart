import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:test/test.dart';

import 'signature_vector.dart';

void main() {
  _verifySignature();
  _generateSignature();
}

void _verifySignature() {
  test("verify signature", () {
    for (final i in checkSignatureVector) {
      final List<int> hash = BytesUtils.fromHexString(i["hash"]);
      final List<int> pub = BytesUtils.fromHexString(i["public_key"]);
      final sig = MECSignature(
          c: BytesUtils.fromHexString(i["c"]),
          r: BytesUtils.fromHexString(i["r"]));
      final verify = MoneroCrypto.checkSignature(
          hash: hash, publicKey: pub, signature: sig);
      expect(i["v"], verify);
    }
  });
}

void _generateSignature() {
  // QuickCrypto.setupRandom((e){
  //   return
  // });
  test("generate signature", () {
    for (final i in signatureVector) {
      final List<int> hash = BytesUtils.fromHexString(i["hash"]);
      final List<int> pub = BytesUtils.fromHexString(i["public_key"]);
      final List<int> sec = BytesUtils.fromHexString(i["secret_key"]);
      final signature = MoneroCrypto.generateSignature(
        hash: hash,
        publicKey: pub,
        secretKey: sec,
        k: BytesUtils.fromHexString(i["random_scalar"]),
      );
      final sigHex = BytesUtils.toHexString([...signature.c, ...signature.r]);
      expect(sigHex, i["excepted"]);
    }
  });
}
