import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/layout/layout.dart';

abstract class MoneroBlockheader extends MoneroSerialization {
  final int majorVersion;
  final int minorVersion;
  final BigInt timestamp;
  final List<int> hash;
  final int nonce;
  MoneroBlockheader({
    required this.majorVersion,
    required this.minorVersion,
    required BigInt timestamp,
    required List<int> hash,
    required int nonce,
  }) : timestamp = timestamp.asU64,
       hash = hash.asImmutableBytes,
       nonce = nonce.asU32;
}
