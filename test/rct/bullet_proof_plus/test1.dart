import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void bulletproofsPlus1() {
  test("bullet proofs plus", () {
    installSeededTestRng();
    final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(
      [BigInt.zero],
      [RCT.skGen()],
    );

    expect(
      BytesUtils.toHexString(prove.d1),
      "e9a52e6d6af9fd8c1746cc2658a3d19718f5652264469650b43bb6e48a24800c",
    );
    expect(
      BytesUtils.toHexString(prove.a),
      "6bd069eefab2f072031d4a29411875c419d60b30c5e0268472f501fa646c34c1",
    );
    expect(
      BytesUtils.toHexString(prove.a1),
      "c386161dc3b4183cbc35de761024b99de350e2b30fba25e10ad0a1a80a8b3f47",
    );
    expect(
      BytesUtils.toHexString(prove.s1),
      "e5ca72d1e9556fd362f6ea763d61941fc3a99c9314c0f181c518e1ec638a5003",
    );
    expect(
      BytesUtils.toHexString(prove.l[0]),
      "4f294ee5cc554922612a5035d9c252d5c1f598c55cb7a9e99a846a50221baab3",
    );
    expect(
      BytesUtils.toHexString(prove.l[1]),
      "e23c062cc7ce7da19d28d8fc5ddc49de31320e54b32360c3571099add7ed858a",
    );
    expect(
      BytesUtils.toHexString(prove.l[2]),
      "b74905e529bf27578fd639db800e3880ae0c3fa19d2a9825e52e6a2ee5eaf9d0",
    );
    expect(
      BytesUtils.toHexString(prove.l[3]),
      "cec015015ce16602c9e7db9b6edafcb8af938b766f9b5846b56fc74d072d78c3",
    );
    expect(
      BytesUtils.toHexString(prove.l[4]),
      "b88db245da047acf06bcdf9eb2e50cdc9e33e6dee0a046720cf41b62aec78a16",
    );
    expect(
      BytesUtils.toHexString(prove.r[0]),
      "42296b88dd4ee7dde18e15cec03a9c6dee457295784a00901e629b8a78547d1b",
    );
    expect(
      BytesUtils.toHexString(prove.r[1]),
      "5ba1fe483daab28d0d2221fdd70dd9220e96e90dc61112bd19b1065c62512a7e",
    );
    expect(
      BytesUtils.toHexString(prove.r[2]),
      "8e3e5ef956e42d04ac64edc94931f3700c3acce36684393a8f54c31d0bf3ed6e",
    );
    expect(
      BytesUtils.toHexString(prove.r[3]),
      "7a1afeb927fd73c2703a639b596211abb062e6001607d5313c3f23e12eea826c",
    );
    expect(
      BytesUtils.toHexString(prove.r[4]),
      "a3070621799fad27a018182b415b4822e80068cd8766946c404242da64296588",
    );
    expect(
      BytesUtils.toHexString(prove.r[5]),
      "af3b66592d8b314b80c95e9c749c1aa2925450bab2b1e65f8bdf2e0ba4b9708c",
    );
  });
}
