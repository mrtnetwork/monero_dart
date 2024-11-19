import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';
import 'package:monero_dart/src/serialization/storage_format/types/binary_container.dart';

/// Get hashes. Binary request.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_hashesbin
class DaemonRequestGetHashesBin extends MoneroDaemonRequestParam<
    DaemonGetHashesBinResponse, Map<String, dynamic>> {
  DaemonRequestGetHashesBin(
      {required List<String> blockIds,
      required this.startHeight,
      this.client = ''})
      : blockIds = blockIds.immutable;

  /// first 10 blocks id goes sequential, next goes in pow(2,n) offset,
  /// like 2, 4, 8, 16, 32, 64 and so on, and the last one is always genesis block
  final List<String> blockIds;
  final BigInt startHeight;
  final String client;
  @override
  String get method => "get_hashes.bin";
  @override
  Map<String, dynamic> get params => {
        "block_ids": MoneroStorageBinary.fromListOfHex(blockIds),
        "client": client,
        "start_height": startHeight,
      };
  @override
  DemonRequestType get requestType => DemonRequestType.binary;
  @override
  DaemonGetHashesBinResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetHashesBinResponse.fromBinaryResponse(result);
  }
}
