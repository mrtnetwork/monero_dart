import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Full block information can be retrieved by either block height or hash,
/// like with the above block header calls. For full block information,
/// both lookups use the same method, but with different input parameters.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_block
class DaemonRequestGetBlock extends MoneroDaemonRequestParam<
    DaemonGetBlockResponse, Map<String, dynamic>> {
  const DaemonRequestGetBlock({
    this.height,
    this.hash,
    this.fillPowHash = false,
  }) : assert(height != null || hash != null,
            "Pick height or hash to retrive block informations.");

  /// The block's height.
  final BigInt? height;

  /// The block's hash.
  final String? hash;
  final bool fillPowHash;
  @override
  String get method => "get_block";
  @override
  Map<String, dynamic> get params => {
        if (height != null) "height": height.toString(),
        if (hash != null) "hash": hash,
        "fill_pow_hash": fillPowHash
      };
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetBlockResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetBlockResponse.fromJson(result);
  }
}
