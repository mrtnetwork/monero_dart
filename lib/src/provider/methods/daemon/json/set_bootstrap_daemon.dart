import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Give immediate usability to wallets while syncing by proxying RPC requests.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#set_bootstrap_daemon
class DaemonRequestSetBootstrapDaemon
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestSetBootstrapDaemon(
      {required this.address,
      required this.username,
      required this.password,
      required this.proxy});
  final String address;
  final String username;
  final String password;
  final String proxy;

  @override
  String get method => "set_bootstrap_daemon";
  @override
  Map<String, dynamic> get params => {
        "address": address,
        "username": username,
        "password": password,
        "proxy": proxy
      };
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
