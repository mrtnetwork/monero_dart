import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

void main() {
  group("BulletproofsPlus 2", () {
    _test2();
  });
}

void _test2() {
  const List<String> debugRandomKeys = [
    "32cce5746d2e1abe3fd426211a12ac0440593d061dd689923f94e1e59e67d009",
    "75e79e61fb0019295ce8ad05829cddcc96a23471f467a99268d95d531b95cf03",
    "349cfda228242ae10cffeb2a410d0d0789b21516dbaf75fbb6a0952ae62e6c00",
    "0562906b2608b10d7fde2d2eba921a8ff75b9d10c0591a7fa172792993fb9900",
    "d80d53f72957aa18616679f258427fbc7839cd327e9b42bf8051b22c0a80ec0a",
    "f0ac00efd98985e123c24fbfabd061f8fc75770c439629b3d8cd001ca8000304",
    "2bb21d8391f04a2abd6ef9d89152b0fb31848bc4686393c4e0d75067f9901302",
    "3af067d43bbef019812b52a2ec186d42e26742b010609368f7df41c076edc80c",
    "024d06eb986111eb25654268f6917740ff3f81f5064fcef87a04ea42d457ff0f",
    "93f499a2209b5aea9a356b297481353d8d27f1b0e3c6b816032266f7150f410c",
    "0769b9df587571d3c25fab7f22bdb5391142a57a0a78e8eb322a687cbf9b4202",
    "8e320fbed1b1bacc8cd66e84c0b68677fb7f832b1db9875efd727aa2b46b6a04",
    "3b59c7f9187d10398ab25b1306a6659ea458266aa409cd25ba442d061c6bc30f",
    "9cad037a9f6b524004aeb31e7538bc150527c13a9dade77f6ad3a5f28bcc6706",
    "d72857cfc2403740dc262cac5de0e295552e8ffec952270564155307e6420703",
    "553d73b6b37a0112d258ec173d92c55e0c1e4497212342ff039801fe4d85d700",
    "5dc40e16dd55543879329375456638d8ab906bfb68a985c62908c292dfd88808",
    "7f079d14c59a5f5c68b76efcae66e92391d757025b65d4a78c4324715cf96e07",
    "7d855937f6a0652f8fe541df1fd31dffc589eea0cd859c6229c4cd0e5c4c8a06",
    "76446007a5a1f2678d5d2d8b7ee706e15fbad97c2ee54e1b4befaba7fa849c03",
    "0dd571c316d512eb63028d45a594d82721bb887fc110b2c6076c83a051420008",
    "4a3cbf3c96a150b9882c0884bffca58233d68d45926251a1e15d1cc8e976dc07",
    "243707b9790c633f6f42e00cb7fe0f6ed675fb302b042e62dc9746d5bdd1cb00",
    "43969c370978fe05817f95237874de1aa7c411e8dd095aa25ba6560cd2d74808",
  ];
  int index = 0;
  QuickCrypto.setupRandom((length) {
    if (index >= debugRandomKeys.length) {
      index = 0;
    }
    return BytesUtils.fromHexString(debugRandomKeys[index++]);
  });
  final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts(
    [
      BigInt.parse("1000000000000"),
      BigInt.parse("20000000000000"),
      BigInt.parse("11882122938912"),
    ],
    [RCT.skGen_(), RCT.skGen_(), RCT.skGen_()],
  );
  test("bullet proofs plus 2", () {
    expect(
      BytesUtils.toHexString(prove.d1),
      "d2c84fe49762c541463a8b0818f8e10935462fce3d465fbfd559d04ed5a9a908",
    );
    expect(
      BytesUtils.toHexString(prove.a),
      "2915e02c8bc0f25eaec243853e86decd3e62e97f652f4a87c32b405ba5796d36",
    );
    expect(
      BytesUtils.toHexString(prove.a1),
      "7507d92ad4b5aa411b57d0a8b48a511a890d5124dc52c147b6ee4301c7156468",
    );
    expect(
      BytesUtils.toHexString(prove.b),
      "eb00643850e8c76193027ac6c0c27d26977000c149ad0cd10e43f7b78d19e377",
    );
    expect(
      BytesUtils.toHexString(prove.s1),
      "558316d079140bfecf8cf2a67826fbeb53b6754a825685645e872439c9b00e0e",
    );
    expect(
      BytesUtils.toHexString(prove.d1),
      "d2c84fe49762c541463a8b0818f8e10935462fce3d465fbfd559d04ed5a9a908",
    );
    expect(
      BytesUtils.toHexString(prove.l[0]),
      "4698981a708d135dee3fae7ec01fc030bceefc460bbb6b98cceef628090fd89e",
    );
    expect(
      BytesUtils.toHexString(prove.l[1]),
      "9b3834fd9803d68f31fee18df141f9c259edb16a132fa19cf5704125aa5142e5",
    );
    expect(
      BytesUtils.toHexString(prove.l[2]),
      "b3c774c1dd499b6f6b925bdf2152974f061cb2bc67c8cc82a42fc6343f65fb61",
    );
    expect(
      BytesUtils.toHexString(prove.l[3]),
      "dcb67779894db22ed8554133c62c677564610b7307e6e8c5ba647573c5bce2ad",
    );
    expect(
      BytesUtils.toHexString(prove.l[4]),
      "b663f0499bd6c51713de42cd405f8942c8c73d94bbcb5cb3a7d263c96efb4a05",
    );
    expect(
      BytesUtils.toHexString(prove.r[0]),
      "3afc51d61445dbc5b88e9115433fcc1c04c44a99a1e53991c35175a50d9fdaf9",
    );
    expect(
      BytesUtils.toHexString(prove.r[1]),
      "e0af0ad94fc69119f8eb89f1f67e084509e2cae21684baa0d0c5cbdbd3384f8d",
    );
    expect(
      BytesUtils.toHexString(prove.r[2]),
      "9e47f12e52c280a384093b3abd09554ca50be9359400580e5b127aaa9d89bf4f",
    );
    expect(
      BytesUtils.toHexString(prove.r[3]),
      "2a08c4be4b6f9adf2a410560aeee458a19c055eb11babe7ceae807eb505f4d21",
    );
    final verify = BulletproofsPlusGenerator.bulletproofPlusVerify([prove]);
    expect(verify, true);
  });
}
