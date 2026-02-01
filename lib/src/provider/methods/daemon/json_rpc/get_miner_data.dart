import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Provide the necessary data to create a custom block template. They are used by p2pool.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_miner_data
class DaemonRequestGetMinerData
    extends
        MoneroDaemonRequestParam<
          DaemonGetMinerDataResponse,
          Map<String, dynamic>
        > {
  DaemonRequestGetMinerData();

  @override
  String get method => "get_miner_data";

  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
  @override
  DaemonGetMinerDataResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetMinerDataResponse.fromJson(result);
  }
}
