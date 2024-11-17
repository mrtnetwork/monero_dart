import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/block.dart';

/// Get blocks by height. Binary request.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_blocks_by_heightbin
class DaemonRequestGetBlocksByHeightBin extends MoneroDaemonRequestParam<
    DaemonGetBlocksByHeightResponse, Map<String, dynamic>> {
  DaemonRequestGetBlocksByHeightBin(this.heights);

  /// array of unsigned int; list of block heights
  final List<int> heights;
  @override
  String get method => "get_blocks_by_height.bin";
  @override
  Map<String, dynamic> get params => {"heights": heights};
  @override
  DemonRequestType get requestType => DemonRequestType.binary;
  @override
  DaemonGetBlocksByHeightResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetBlocksByHeightResponse.fromJson(result);
  }
}
