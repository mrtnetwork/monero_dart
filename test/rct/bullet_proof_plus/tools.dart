import 'package:blockchain_utils/utils/tuple/tuple.dart';
import 'package:monero_dart/monero_dart.dart';

Tuple<List<int>, List<int>> _skpkGen() {
  final secret = List<int>.filled(32, 0);
  final pk = List<int>.filled(32, 0);
  RCT.skpkGen(secret, pk);
  return Tuple(secret, pk);
}

Tuple<CtKey, CtKey> ctskpkGen(BigInt xmrAmount) {
  final am = RCT.d2h(xmrAmount);
  final bh = RCT.scalarmultH(am);
  final sk = _skpkGen();
  final pk = _skpkGen();
  final mask = RCT.addKeys_(pk.item2, bh);
  return Tuple(
      CtKey(dest: sk.item1, mask: pk.item1), CtKey(dest: sk.item2, mask: mask));
}
