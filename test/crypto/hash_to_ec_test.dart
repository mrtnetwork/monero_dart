import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';

import 'package:test/test.dart';

import 'derive_public_key_test_vector.dart';

void main() async {
  test("hash to ec", () {
    for (final i in hashToEcVector) {
      final hash = BytesUtils.fromHexString(i["hash"]);
      final expected = BytesUtils.fromHexString(i["point"]);
      final point = RCT.hashToP3Bytes(hash);
      expect(expected, point);
    }
  });
}
