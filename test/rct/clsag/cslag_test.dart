import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:test/test.dart';

void main() {
  _test();
}

void _test() {
  const List<String> rands = [
    "3973ddf889fc7e171d138ee520c756015093847e7b9f6db915a3012865c08306",
    "dc8aee7841cbe096569f59b30c12978ac20bfbf9f8079ac733216d35caffe801",
    "68068b7fef236b60a67ab47d74dcdedeefbaec00c7401b54b28fed30a0b30a03",
    "05acdb10cb63a89c7879faad495edd45ee7736d47d64e2bb0d32de31bd77f20a",
    "90385f6b20b821d1b56da60d0ff760961c8e25a74549e9c6ff81d89cd5c90200",
    "4fa1eb63b7e4ebdfc222c769a9120d0715c5bb88828e26c954dc54960fd0990e",
    "51cb1c8e27cb8c18c28fc280204a2f0c0049d32f91e134ce072c51d26dd4d10a",
    "b5afebb67465459fd210588e951fc72dee6bf812bf97f9db0290e4dabdfcc208",
    "80f29d55753d542b708f94f166d1952e1b7c5ff3f2ed17f344cbb3d4a3eb150c",
    "1ed149359fea58adc1ae79c50b2ccbddf62034c81f5a9175bc23c73a4530b305",
    "e180bb90e03f5bb16f970216ddb768d895eb8e03382b40d052b880b88cfda70c",
    "4949a16d48efa86a6cd6d8e62a85075fe4f738d0caa14cd07afeb63a2fad6e08",
    "cf3dccc0ceaf7b4bf3b948428bea5166d13f67129ceed0ef7052bc251530610d",
    "4ea774876adead0a6811d3121dfea42cb03eaebc238120b5cbfc84c37c20580e",
    "64d6efdcf490b854bf91d0c400cd29c932752d83d82d51d2b1c6d4dd30702609",
    "e2a923574244842d0eaf8fe2678e5c2f8fbd819e0cd5a5642f3ea6113f35230c",
    "eba31a60c05cb7227862b07c973db6ea716878a143cbfd16a945925ba62d6f04",
    "2c7308589de93b985f75cd2a305e9278162cde9cadc79197673c89e173c0670a",
    "4faccf64bdf5a3d9235ae6fd566e8e4e4e06cc1d92fe80c56349cb704861aa09",
    "44787e2e77a9f596924fc877135bca4614310637ef97d1911e4072136795a202",
    "937bfc0eab36f2c3fc0c25a325d952770c81f6bc18871ad3f4311bcd2d80540d",
    "d9a93243b3b1983e00b5b1b68827d5e5f357bf7aa261f97f0b280d3682529d03",
    "39b3e9320c1b22fe8b3eb32322dd9c11dda18647234d0e9956d9fc0c69fce401",
    "02c9f2e81b310db697b12bbac9ad90519b2477111585f76c6b9c932d2a0b4e09",
    "a27016f31e7a2c21d8f6d96a66a2b1ad9b8c01bdf5bf623684d2271e6abe710e",
    "fa4dbb9cee5f44d75595b96977ad7eb7170fcbfd69dd873ac66408b761e6cd03",
    "1b30df5a8b18dd8008a661161cbc0aee02bc26eceabbeb991ef4be9233f5580c",
    "d22839047bb7187920a0ad1c001e2d5cc38240af9acd4fa87034445aa24f0e08",
    "3e0954c0c268a06365a6802a746fa8b950a8529faea0cae4fc610253f816be07",
    "ded6bec2dbaf1add0d62365363ad084f160fada886b47d125a8125e4dcce0700",
    "d05d52c9a252ec175983728931e5c479f7e2bc9abcb0b6e278005e0a83361e0e",
    "1b0106fe6493b6b84a6f86f3d0c379aebf3f9f8c1713bd74e22f83443bcb8500",
    "c73e80b0d40024bb8eedfaac1a7d34c88421550c67c08de2971861dcfc8a930f",
    "d4d71b8fe9e27ed5e5733377ed6008321db709afeb4c055d69429395fbfb4a0b",
    "886facf167ee374cfd1e3a8e116e84bb314d5dc1a53625c8602a4188a5183108",
    "8868bc0ef3a40779bd560b9a3a1c390cf03531c0c058636af45b3a4329b0a102",
    "8c7b4d51a1f26f86fff2462508ba448a7450a196aba0fa1dbf9e2314173fa00f",
  ];
  int index = 0;
  QuickCrypto.setupRandom((length) {
    if (index >= rands.length) {
      index = 0;
    }
    return BytesUtils.fromHexString(rands[index++]);
  });
  const int N = 11;
  const int idx = 5;
  final CtKeyV pubs = [];
  RctKey p = RCT.zero(), t = RCT.zero(), t2 = RCT.zero(), u = RCT.zero();
  final RctKey message = RCT.identity();

  for (int i = 0; i < N; ++i) {
    final RctKey sk = RCT.zero();
    // CtKey tmp;
    final dst = RCT.zero();
    final mask = RCT.zero();

    RCT.skpkGen(sk, dst);
    RCT.skpkGen(sk, mask);

    pubs.add(CtKey(dest: dst, mask: mask));
  }
  final sI = pubs[idx].dest.clone();
  // Set P[idx]
  RCT.skpkGen(p, sI);

  // Set C[idx]
  t = RCT.skGen_();
  u = RCT.skGen_();
  // RctKey sp = pubs[idx].mask.clone();
  final RctKey sp = RCT.addKeys2_(t, u, RCTConst.h);
  pubs[idx] = CtKey(dest: sI, mask: sp);
  // Set commitment offset
  // final RctKey cout = RCT.zero();
  t2 = RCT.skGen_();
  final RctKey cout = RCT.addKeys2_(t2, u, RCTConst.h);

  // Prepare generation inputs
  final CtKey insk = CtKey(dest: p, mask: t);
  final Clsag prove = CLSAGUtils.prove(message, pubs, insk, t2, cout, idx);
  final bool vr = CLSAGUtils.verify(message, prove, pubs, cout);
  test("correct sig", () {
    expect(vr, true);
    expect(
      BytesUtils.toHexString(prove.i!),
      "f6dc8eb3c14c3a9572fe4ddbc1b8e6174e25d94339422357aed7046077337f46",
    );
    expect(
      BytesUtils.toHexString(prove.c1),
      "82df47e67caf1722c929adcd5260cd797195c706a1bf6bcc27a1d3ae33e78a00",
    );
    expect(
      BytesUtils.toHexString(prove.d),
      "2a17bc6bcc71a65ad70d7ff18d787067f5eedf0fea947c1905dd69c9940be10d",
    );
    expect(prove.s.length, 11);
    expect(
      BytesUtils.toHexString(prove.s[0]),
      "c73e80b0d40024bb8eedfaac1a7d34c88421550c67c08de2971861dcfc8a930f",
    );
    expect(
      BytesUtils.toHexString(prove.s[1]),
      "d4d71b8fe9e27ed5e5733377ed6008321db709afeb4c055d69429395fbfb4a0b",
    );
    expect(
      BytesUtils.toHexString(prove.s[2]),
      "886facf167ee374cfd1e3a8e116e84bb314d5dc1a53625c8602a4188a5183108",
    );
    expect(
      BytesUtils.toHexString(prove.s[3]),
      "8868bc0ef3a40779bd560b9a3a1c390cf03531c0c058636af45b3a4329b0a102",
    );
    expect(
      BytesUtils.toHexString(prove.s[4]),
      "8c7b4d51a1f26f86fff2462508ba448a7450a196aba0fa1dbf9e2314173fa00f",
    );
    expect(
      BytesUtils.toHexString(prove.s[5]),
      "10cfe97da5f1970414938e659e92eaf2c07ab33da00866a61899a8cf0fd3c404",
    );
    expect(
      BytesUtils.toHexString(prove.s[6]),
      "d22839047bb7187920a0ad1c001e2d5cc38240af9acd4fa87034445aa24f0e08",
    );
    expect(
      BytesUtils.toHexString(prove.s[7]),
      "3e0954c0c268a06365a6802a746fa8b950a8529faea0cae4fc610253f816be07",
    );
    expect(
      BytesUtils.toHexString(prove.s[8]),
      "ded6bec2dbaf1add0d62365363ad084f160fada886b47d125a8125e4dcce0700",
    );
    expect(
      BytesUtils.toHexString(prove.s[9]),
      "d05d52c9a252ec175983728931e5c479f7e2bc9abcb0b6e278005e0a83361e0e",
    );
    expect(
      BytesUtils.toHexString(prove.s[10]),
      "1b0106fe6493b6b84a6f86f3d0c379aebf3f9f8c1713bd74e22f83443bcb8500",
    );
  });

  test("bad message", () {
    final prove = CLSAGUtils.prove(RCT.zero(), pubs, insk, t2, cout, idx);
    final vr = CLSAGUtils.verify(message, prove, pubs, cout);
    expect(vr, false);
  });

  test("bad index", () {
    final prove = CLSAGUtils.prove(
      message,
      pubs,
      insk,
      t2,
      cout,
      (idx + 1) % N,
    );
    final vr = CLSAGUtils.verify(message, prove, pubs, cout);
    expect(vr, false);
  });

  test("bad C", () {
    pubs[idx] = CtKey(
      dest: RCT.scalarmultBase(RCT.skGen_()),
      mask: pubs[idx].mask,
    );
    final prove = CLSAGUtils.prove(
      message,
      pubs,
      insk,
      t2,
      cout,
      (idx + 1) % N,
    );
    final vr = CLSAGUtils.verify(message, prove, pubs, cout);
    expect(vr, false);
  });
}
