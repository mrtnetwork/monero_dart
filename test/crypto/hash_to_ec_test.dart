import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import 'package:test/test.dart';

import 'derive_public_key_test_vector.dart';

void main() async {
  List<int> hashToEc(List<int> pubKey) {
    final GroupElementP3 res = GroupElementP3();
    MoneroCrypto.hashToEcPoint(pubKey, res);
    return CryptoOps.geP3Tobytes_(res);
  }

  test("hash to ec", () {
    for (final i in hashToEcVector) {
      final hash = BytesUtils.fromHexString(i["hash"]);
      final expected = BytesUtils.fromHexString(i["point"]);
      final point = hashToEc(hash);
      expect(expected, point);
    }
  });
}
