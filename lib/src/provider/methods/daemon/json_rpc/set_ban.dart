import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Ban another node by IP.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_bans
class DaemonRequestSetBans
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  DaemonRequestSetBans(List<DaemonBanParams> bans) : bans = bans.immutable;
  final List<DaemonBanParams> bans;
  @override
  String get method => "set_bans";
  @override
  Map<String, dynamic> get params =>
      {"bans": bans.map((e) => e.toJson()).toList()};
  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
