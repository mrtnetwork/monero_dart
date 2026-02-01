import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Set daemon bandwidth limits.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_limit
class DaemonRequestSetLimit
    extends
        MoneroDaemonRequestParam<DaemonLimitResponse, Map<String, dynamic>> {
  const DaemonRequestSetLimit({required this.limitDown, required this.limitUp});
  final BigInt limitDown;
  final BigInt limitUp;

  @override
  String get method => "set_limit";
  @override
  Map<String, dynamic> get params => {
    "limit_up": limitUp.toString(),
    "limit_down": limitDown.toString(),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonLimitResponse onResonse(Map<String, dynamic> result) {
    return DaemonLimitResponse.fromJson(result);
  }
}
