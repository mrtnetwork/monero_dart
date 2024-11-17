import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:test/test.dart';
import 'ring_signature_test_vector.dart';

void main() async {
  _generateRingSignature();
}
void _generateRingSignature() {
  test("generate ring signature", () {
    for (final i in ringSignatureTestVector) {
      final List<int> prefixHash = BytesUtils.fromHexString(i["prefix_hash"]);
      final List<int> keyImage = BytesUtils.fromHexString(i["key_image"]);
      final List<List<int>> pubs =
          (i["pubs"] as List).map((e) => BytesUtils.fromHexString(e)).toList();
      final List<int> secretKey = BytesUtils.fromHexString(i["secret_key"]);
      int index = -1;
      final List<List<int>> scalars = (i["random_scalar"] as List)
          .map((e) => BytesUtils.fromHexString(e))
          .toList();
      final int secIndex = i["secret_index"];
      final gn = MoneroCrypto.generateRingSignature(
        prefixHash: prefixHash,
        keyImage: keyImage,
        pubs: pubs,
        secretKey: secretKey,
        secIndex: secIndex,
        randScalar: (pubIndex) {
          if (pubIndex != index) {
            index = pubIndex;
            return scalars.elementAt(pubIndex).sublist(0, 32);
          }
          return scalars.elementAt(pubIndex).sublist(32);
        },
      );
      final signatures = gn.expand((e) => e.c + e.r).toList();

      expect(BytesUtils.toHexString(signatures), i["excepted"]);
    }
  });
}
