import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Similar to get_block_header_by_hash above, this method includes a block's height as
/// an input parameter to retrieve basic information about the block.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_block_header_by_height
class DaemonRequestGeBlockHeaderByHeight extends MoneroDaemonRequestParam<
    DaemonGetLastBlockHeaderResponse, Map<String, dynamic>> {
  DaemonRequestGeBlockHeaderByHeight(this.height, {this.fillPowHash = false});

  /// Add PoW hash to block_header response.
  final bool fillPowHash;

  /// The block's height.
  final BigInt height;
  @override
  String get method => "get_block_header_by_height";
  @override
  Map<String, dynamic> get params =>
      {"fill_pow_hash": fillPowHash, "height": height.toString()};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonGetLastBlockHeaderResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetLastBlockHeaderResponse.fromJson(result);
  }
}
