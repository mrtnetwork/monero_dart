import 'package:monero_dart/src/provider/core/core.dart';

/// Calculate PoW hash for a block candidate.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#calc_pow
class DaemonRequestCalcPow extends MoneroDaemonRequestParam<String, String> {
  DaemonRequestCalcPow({
    required this.majorVersion,
    required this.height,
    required this.blockBlob,
    required this.seedHash,
  });

  /// The major version of the monero protocol at this block height.
  final int majorVersion;
  final BigInt height;
  final String blockBlob;
  final String seedHash;
  @override
  String get method => "calc_pow";
  @override
  Map<String, dynamic> get params => {
    "major_version": majorVersion,
    "height": height.toString(),
    "block_blob": blockBlob,
    "seed_hash": seedHash,
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
}
