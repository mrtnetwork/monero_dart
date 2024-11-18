import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class BpPlusProofData {
  final RctKey y;
  final RctKey z;
  final RctKey e;
  final List<RctKey> challenges;
  final int logM;
  final int invOffset;
  BpPlusProofData(
      {required RctKey y,
      required RctKey z,
      required RctKey e,
      required List<RctKey> challenges,
      required this.logM,
      required this.invOffset})
      : y = y.asImmutableBytes,
        z = z.asImmutableBytes,
        e = e.asImmutableBytes,
        challenges =
            challenges.map((e) => e.asImmutableBytes).toList().immutable;
}
