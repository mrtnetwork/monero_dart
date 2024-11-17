import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/ringct/bulletproofs_plus/bulletproofs_plus.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:test/test.dart';

void main() {
  group("BulletproofsPlus 3", () {
    _test3();
  });
}

void _test3() {
  const List<String> debugRandomKeys = [
    "252bf2426bd05bb0e4342e7c8f3a8405bafe640af19a55e754b6a9327c1caa03",
    "bd0d099c81b6198cdd0757c2bd6c92b228cc3a7e45e9d77d90cf8f360e04cd0b",
    "23ea028a4bc9e868c29131314f1ac3fcc43eae2b9b0eac3fffebb6197af3ed09",
    "f8c78c30ea8937ecdf67c93bbd41d508fb530e83b9e2602e422534d827fb9703",
    "cb6379280219e8f32993098da435c689ebc38d0695cbbec3f2655e54ac540b0f",
    "9acf6ad91f606d8cf4fba4279fe05337321b6c3a74088385ef868cdb4ed3ff02",
    "7f1e2adf270394f30c543da9ba8b3296e3c7d83c04822fc785ea4a1616a1090a",
    "7afb2ce736071e11ab469b05763d36ba3e6ddcc17a36f85e86e5cc1f8a6b680e",
    "34f50cb394e0c10e5147e37b9eea8b2a085825c9583b2efd36721e053e15b500",
    "c3b1a898120361d3f539826199a39242cfecae30532f2f2304a780208067cf04",
    "c52748727e72a86f6e9351efc6051f99cd92e5980d00505cb49f09ab0596ab01",
    "238bfa97717c0e1f2b3795edaee7aee437ad9aa1a7ee2fa3d5df0eddb0fe6a0c",
    "7bcc5cdbf5c9c3e97839261ad28705160fb3590afbffeee95dd5fa53fe03d501",
    "52b2edce78c0b3cd2e25da5aca784ececc467fbcf210166504791a0eb96dc808",
    "f95ae304df7cdc078cf321791ac07a2d5cce9dc7418548545c0a7b6b376c100a",
    "1b89235a32b32056e987978b3c5c7586803c4dca071397ea31a9ed8d4ebcb400",
    "ca49c58b1d5cc00a47fd1c395c19a57d651312af8f386ebf06f8d3644ab6700a",
    "cffdf6570bed989e356ffbcd28d4b7758a155ee8728aee66075164ee43ee330d",
    "e2be35d28a472a3593e42281ff4d150a2a9ea3d283acf8aa7a950ad4f9cd020e",
    "04c4d867c385618a1a89e55c14ad21d085c72b740f17a34a065f7099df7da107",
    "7c04e68aa22193e6a64ac8eb437d6f6d6cb9147268db2d9933657448fc1afb0f",
    "872618039d2368e30b8111a8d04c51bc8c8512e037ebe5c9d3fc2068668beb07",
    "11c97747f3735c3a8de52cbb7269aa89b4a55cb4815a8649fa821e8349129606",
    "56fc3760206fb1f51d06d13e7467a1d5eb5b85098b70500e908bbd5ac18ece00",
    "9cdfa9d592eeda4384e0deccc3a5343eb606ceb6b1836667b45497c638929d07",
    "df3880545f8ed286b78bd8e4d49834b6ae3c53449f0afc12eacf662bde0b190e",
    "589c2a9a9b91ba7e1a147cbfbc910a01b4a1263b75e340f2b7a1ded415eccc07",
    "9f640acb128ccf43c86f5adfd1d05fd99206ea6d2dbe16d1f20bcedb8debfb04",
    "9cfcc621dd60073ff15c73d549d32a3a6322667168ee5981c6793cdc227c8108",
    "df3880545f8ed286b78bd8e4d49834b6ae3c53449f0afc12eacf662bde0b190e",
    "589c2a9a9b91ba7e1a147cbfbc910a01b4a1263b75e340f2b7a1ded415eccc07",
    "9f640acb128ccf43c86f5adfd1d05fd99206ea6d2dbe16d1f20bcedb8debfb04",
    "9cfcc621dd60073ff15c73d549d32a3a6322667168ee5981c6793cdc227c8108",
  ];
  int index = 0;
  QuickCrypto.setupRandom(
    (length) {
      if (index >= debugRandomKeys.length) {
        index = 0;
      }
      return BytesUtils.fromHexString(debugRandomKeys[index++]);
    },
  );
  final prove = BulletproofsPlusGenerator.bulletproofPlusPROVEAmouts([
    BigInt.parse("1000000000000"),
    BigInt.parse("20000000000000"),
    BigInt.parse("11882122938912"),
    BigInt.zero,
    BigInt.one,
    BigInt.from(3)
  ], [
    RCT.skGen_(),
    RCT.skGen_(),
    RCT.skGen_(),
    RCT.skGen_(),
    RCT.skGen_(),
    RCT.skGen_()
  ]);
  test("bullet proofs plus 3", () {
    expect(BytesUtils.toHexString(prove.d1),
        "e5a2c0c2ed47f466ab44fad343b4c3578fad17c3f792b319615e255cbfd5f504");
    expect(BytesUtils.toHexString(prove.a),
        "305a5a1d310502b1875844da3fd859db1c06d907bdf8ad6e2fa098eaf16693db");
    expect(BytesUtils.toHexString(prove.a1),
        "2f2640dcc9cd90162dc211b095b0a686870dd683e949e8b4823c5e9d8ca015a7");
    expect(BytesUtils.toHexString(prove.b),
        "b2539f9f820c7c8065417a274b838a86aff019e637a56a593bbb0770ee5fcf90");
    expect(BytesUtils.toHexString(prove.s1),
        "ae1de14e4cdd64f7500fdaf0615069d59b7c5c209fae0dba06344eaec7ae8a06");
    expect(BytesUtils.toHexString(prove.d1),
        "e5a2c0c2ed47f466ab44fad343b4c3578fad17c3f792b319615e255cbfd5f504");
    expect(BytesUtils.toHexString(prove.l[0]),
        "7c300ac7ffe63c419c6a59e8dc9a942e7357e7c9dd1716dbb3b860720d85610d");
    expect(BytesUtils.toHexString(prove.l[1]),
        "55563fb5c958e1b07dbffdcfaaa9837fe7c9f400216429db6244f581caad12e3");
    expect(BytesUtils.toHexString(prove.l[2]),
        "d78036f5d6c1ed3379033be52bb415f1230daa3db6462b7096dfa25c7a4243b0");
    expect(BytesUtils.toHexString(prove.l[3]),
        "a9543c7a7f0a63aa443c988d2c8be20439f7ef870ba73aad6ece1852bbe5d1f0");
    expect(BytesUtils.toHexString(prove.l[4]),
        "eb55b2d67f92fbdde34c51249abf1bc84fc4a1cd20f907a9384b7ee73fcb4946");
    expect(BytesUtils.toHexString(prove.r[0]),
        "107ccfa2e8d24adb5f7151b18cd58eced0515713a35f2dbbe783ebce1dbc103f");
    expect(BytesUtils.toHexString(prove.r[1]),
        "c4ec620f6fb2686fa0d9f31d8fae871c654d1f85b95c9975a2434cf28e2171ec");
    expect(BytesUtils.toHexString(prove.r[2]),
        "060f1d2651afa95350b2e9ec5415771cd08f5615cd11a65e972e1cc227da2beb");
    expect(BytesUtils.toHexString(prove.r[3]),
        "3f53a4c86e40caf318812dfdad8873372d8a3d8f0ab8997fe1ff38335e452a2f");
    expect(BytesUtils.toHexString(prove.v[0]),
        "9ec4a24fcdc70319ee4e541cf2580947c2e1dfae5d4e677efadc015b6fdf2ec4");
    expect(BytesUtils.toHexString(prove.v[1]),
        "7999e0ee4d7af926715023b68e63200c57decb8fcbb95b65e4be296d34ab704c");
    expect(BytesUtils.toHexString(prove.v[2]),
        "464682d6adaac8702df9331f769e6069f28a6827e2cf8acc5fb093461898729a");
    expect(BytesUtils.toHexString(prove.v[3]),
        "0c5acd48d8db6e0e830dabb9c5e50b262ed3fd7acf6f7d71e866936aa81c338f");
    final verify = BulletproofsPlusGenerator.bulletproofPlusVerify([prove]);
    expect(verify, true);
  });
}
