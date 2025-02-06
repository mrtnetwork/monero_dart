import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';

import 'package:test/test.dart';

import 'derive_public_key_test_vector.dart';

void main() async {
  test("hash to point", () {
    for (final i in hashToPoint) {
      final hash = BytesUtils.fromHexString(i["hash"]);
      final expected = BytesUtils.fromHexString(i["point"]);
      final point = MoneroCrypto.hashToPoint(hash);
      expect(expected, point);
    }
  });
}
