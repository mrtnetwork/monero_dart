import 'package:blockchain_utils/blockchain_utils.dart';

class BpPlusProofData {
  final Ed25519Fr y;
  final Ed25519Fr z;
  final Ed25519Fr e;
  final List<Ed25519Fr> challenges;
  final int logM;
  final int invOffset;
  BpPlusProofData({
    required this.y,
    required this.z,
    required this.e,
    required this.challenges,
    required this.logM,
    required this.invOffset,
  });
}
