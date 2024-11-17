import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Block header information can be retrieved using either a block's hash or height. 
/// This method includes a block's hash as an input parameter to retrieve basic information about the block.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_block_header_by_hash
class DaemonRequestGetBlockHeaderByHash extends MoneroDaemonRequestParam<
    DaemonBlockHeadersResponse, Map<String, dynamic>> {
  DaemonRequestGetBlockHeaderByHash({
    this.hash,
    this.fillPowHash = false,
    List<String> hashes = const [],
  }) : hashes = hashes.immutable;

  /// Add PoW hash to block_header response.
  final bool fillPowHash;

  /// The block's sha256 hash.
  final String? hash;
  final List<String> hashes;
  @override
  String get method => "get_block_header_by_hash";
  @override
  Map<String, dynamic> get params => {
        "fill_pow_hash": fillPowHash,
        if (hash != null) "hash": hash,
        if (hashes.isNotEmpty) "hashes": hashes,
      };
  @override
  DemonRequestType get requestType => DemonRequestType.jsonRPC;
  @override
  DaemonBlockHeadersResponse onResonse(Map<String, dynamic> result) {
    return DaemonBlockHeadersResponse.fromJson(result);
  }
}
