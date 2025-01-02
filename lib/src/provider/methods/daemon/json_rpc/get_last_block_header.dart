import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Block header information for the most recent block is easily retrieved with this method. No inputs are needed.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_last_block_header
class DaemonRequestGetLastBlockHeader extends MoneroDaemonRequestParam<
    DaemonGetLastBlockHeaderResponse, Map<String, dynamic>> {
  DaemonRequestGetLastBlockHeader({this.fillPowHash = false});

  /// Add PoW hash to block_header response.
  final bool fillPowHash;
  @override
  String get method => "get_last_block_header";
  @override
  Map<String, dynamic> get params => {"fill_pow_hash": fillPowHash};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonGetLastBlockHeaderResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetLastBlockHeaderResponse.fromJson(result);
  }
}
