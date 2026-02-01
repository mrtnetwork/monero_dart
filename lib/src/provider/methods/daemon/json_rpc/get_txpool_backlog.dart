import 'package:monero_dart/src/provider/core/core.dart';

/// Get all transaction pool backlog.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_txpool_backlog
class DaemonRequestGetTxPoolBackLog
    extends
        MoneroDaemonRequestParam<Map<String, dynamic>, Map<String, dynamic>> {
  DaemonRequestGetTxPoolBackLog();

  @override
  String get method => "get_txpool_backlog";

  @override
  DemonRequestType get encodingType => DemonRequestType.jsonRPC;
}
