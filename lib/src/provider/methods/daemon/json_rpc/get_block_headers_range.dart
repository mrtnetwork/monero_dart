import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Similar to get_block_header_by_height above, but for a range of blocks.
/// This method includes a starting block height and an ending block
/// height as parameters to retrieve basic information about the range of blocks.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_block_headers_range
class DaemonRequestGetBlockHeaderByRange
    extends
        MoneroDaemonRequestParam<
          DaemonBlockHeadersByRangeResponse,
          Map<String, dynamic>
        > {
  DaemonRequestGetBlockHeaderByRange({
    required this.startHeight,
    required this.endHeight,
    this.fillPowHash = false,
  });

  /// Add PoW hash to block_header response.
  final bool fillPowHash;

  /// The starting block's height.
  final int startHeight;

  /// The ending block's height.
  final int endHeight;
  @override
  String get method => "get_block_headers_range";
  @override
  Map<String, dynamic> get params => {
    "fill_pow_hash": fillPowHash,
    "start_height": startHeight.toString(),
    "end_height": endHeight.toString(),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonBlockHeadersByRangeResponse onResonse(Map<String, dynamic> result) {
    return DaemonBlockHeadersByRangeResponse.fromJson(result);
  }
}
