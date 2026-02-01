import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/methods/wallet/methods/get_info.dart';

/// Retrieve general information about the state of your node and the network.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_info
class DaemonRequestGetInfo
    extends
        MoneroDaemonRequestParam<DaemonGetInfoResponse, Map<String, dynamic>> {
  const DaemonRequestGetInfo();

  @override
  String get method => "get_info";
  @override
  Map<String, dynamic> get params => {};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonGetInfoResponse onResonse(Map<String, dynamic> result) {
    return DaemonGetInfoResponse.fromJson(result);
  }
}
