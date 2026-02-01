import 'package:monero_dart/monero_dart.dart';

(List<int>, List<int>) _skpkGen() {
  final secret = List<int>.filled(32, 0);
  final pk = List<int>.filled(32, 0);
  RCT.skpkGen(secret, pk);
  return (secret, pk);
}

(CtKey, CtKey) ctskpkGen(BigInt xmrAmount) {
  final am = RCT.d2h(xmrAmount);
  final bh = RCT.scalarmultH(am);
  final sk = _skpkGen();
  final pk = _skpkGen();
  final mask = RCT.addKeys_(pk.$2, bh);
  return (CtKey(dest: sk.$1, mask: pk.$1), CtKey(dest: sk.$2, mask: mask));
}
