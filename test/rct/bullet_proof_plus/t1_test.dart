import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

void main() {
  group("BulletproofsPlus", () {
    _test();
  });
}

void _test() {
  const List<String> debugRandomKeys = [
    "cdb4e246cba2e1ff9546b8fddfd1fba71788c7c56d3f44005c839556eb20900e",
    "b9d29ec8d428c708cc0fb12d1390849ecdf395b521f10589427e39d60f7b9209",
    "6301e9452c76204d0a2c5115dde5fa1bc2a5af4b038628dd48a0e867aea4c50b",
    "67f9cb1c22917ea33293eef718e6d7406a4941da8b996cdc9fcd0d787ba0a60f",
    "89432909c49c08bbbb5f583dae968f5b2f84107111eed15e7356792a77a21f0d",
    "5fe80fe3628b8ea06773cdf4209035cbcd390238432eb558a35e6980c7780505",
    "b062bb662f7451f65b86691caaf403301d55094bc43b4f6f9c8ac9969cb34703",
    "f5fc13cff8e9ab89b9cd6769e196df364823aed4377e654cdb6553456b93d409",
    "fad5edfeda94b38ceb78e27fee6ee76cf1852e26935d3264e7725ccf9cac5d04",
    "da15b0e1ffd3f03feb57cb90fbcf681d82450d18815de0ec2abffbd288ce840a",
    "57730fdc3097cd9156ba322e54d72660b70d6bd71a9993b13eda8aad05b28b04",
    "f74ebab858f39c2c569e2e9ec4a231fe4b26bbce56ec7e2f3fed963f35331606",
    "7ebace1399a193c3e6cdbb198bf969d5e6d388d3b19b34ee0a86cf29334fe002",
    "c6a03c5e67f5ac1fe2893b301eb34924cc219198de6bbc40b7dcd42ad62f0c07",
    "15a47fef97a4c3d603feade16af55196f3c48b48d7337fd0be9d26170a8abc09",
    "94e90cb52b1b995ef12b296e9f6647a91f44fe76e63cf0a49565958afe64420b",
    "5ffc2c1ac2aa547cc3a9b7763cd654839d254c3d8fa69ca32c8f096813dc390f",
    "947b75bac2d18e18132d588cd945c500cce6a4bf7d080a744dd22167ac3d5608",
  ];

  test("bullet proofs plus", () {
    int index = 0;
    QuickCrypto.setupRandom((length) {
      if (index >= debugRandomKeys.length) {
        index = 0;
      }
      return BytesUtils.fromHexString(debugRandomKeys[index++]);
    });

    final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(
      [BigInt.zero],
      [RCT.skGen_()],
    );

    expect(
      BytesUtils.toHexString(prove.d1),
      "085b44e0ff52802f5a19c77a5c3fce4826f1d85915ad05d69a72f3fbc6d2440e",
    );
    expect(
      BytesUtils.toHexString(prove.a),
      "d2a2b9a23a6b54965ca965beef61d049aa0ac27abb183cf0e1d01ae5398233c1",
    );
    expect(
      BytesUtils.toHexString(prove.a1),
      "e7390b8a1836b70ef8d1890a9e05f528363f1f3575f830a4290c5f1299e9a7c2",
    );
    expect(
      BytesUtils.toHexString(prove.s1),
      "930757aa2c6a2eab9c5ce23c9cea12b6c91c1eeef37a63cec479610f9d9af907",
    );
    expect(
      BytesUtils.toHexString(prove.l[0]),
      "cacf90eeeb522efd7534cdf72091f8a0120e1346fb7201d869a369222a5e14b5",
    );
    expect(
      BytesUtils.toHexString(prove.l[1]),
      "00721a8b466253cb43d11b20e2d39738eef69af0c76fc2d44e000e1bee11fbbc",
    );
    expect(
      BytesUtils.toHexString(prove.l[2]),
      "95147ad9c4a4fdf7d0aca8f3cf42ed84521f683c57b5a7b8e03ed6df29f03732",
    );
    expect(
      BytesUtils.toHexString(prove.l[3]),
      "5adb08e120cd4fc5c22d5e426b4c4a94cabe358a37010ef80c7b61e370623287",
    );
    expect(
      BytesUtils.toHexString(prove.l[4]),
      "666161a55014a9c8f707f8f106ffa90bfcb85033d64108b90f8d226c7869f098",
    );
    expect(
      BytesUtils.toHexString(prove.r[0]),
      "9a9323401b551f26e7ca6897606dd4219ccf11afeea95750ceed9380f64d2fa3",
    );
    expect(
      BytesUtils.toHexString(prove.r[1]),
      "a5a39f615c0b1385f6483ecbaac10cc196f1964b226d47b389b69aeb66369668",
    );
    expect(
      BytesUtils.toHexString(prove.r[2]),
      "c6da1fde62da34eeb7ab070066a5d5348fccb411b4acabe5db096657c1d73353",
    );
    expect(
      BytesUtils.toHexString(prove.r[3]),
      "179020dc4fec3ce785325b2f108c10623effba92ebd321862c3f019206d934a9",
    );
    expect(
      BytesUtils.toHexString(prove.r[4]),
      "82b2f35b3c98f54579dc5f2bf458e0c781777ad930c22e1fd85c30fc29e9b12d",
    );
    expect(
      BytesUtils.toHexString(prove.r[5]),
      "8b7c3add6611de54ab006c6af98c0b0480e4a8fe3c73d6d9b1575d1e05d155fa",
    );
    // final verify = BulletproofsPlusGenerator.bulletproofPlusVerify([prove]);
    // expect(verify, true);
  });
}
