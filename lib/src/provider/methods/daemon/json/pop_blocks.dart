import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#pop_blocks
class DaemonRequestPopBlocks extends MoneroDaemonRequestParam<
    DaemonPopBlocksResponse, Map<String, dynamic>> {
  const DaemonRequestPopBlocks(this.nBlocks);
  final BigInt nBlocks;
  @override
  String get method => "pop_blocks";
  @override
  Map<String, dynamic> get params => {"nblocks": nBlocks.toString()};
  @override
  DemonRequestType get requestType => DemonRequestType.json;

  @override
  DaemonPopBlocksResponse onResonse(Map<String, dynamic> result) {
    return DaemonPopBlocksResponse.fromJson(result);
  }
}
