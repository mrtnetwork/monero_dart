import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Broadcast a raw transaction to the network.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#send_raw_transaction
class DaemonRequestSendRawTransaction
    extends
        MoneroDaemonRequestParam<
          DaemonSendRawTxResponse,
          Map<String, dynamic>
        > {
  DaemonRequestSendRawTransaction({
    required this.txAsHex,
    this.doNotRelay = false,
    this.doSanityChecks = true,
  });

  final String txAsHex;
  final bool doNotRelay;
  final bool doSanityChecks;

  @override
  String get method => "send_raw_transaction";
  @override
  Map<String, dynamic> get params => {
    "tx_as_hex": txAsHex,
    "do_not_relay": doNotRelay,
    "do_sanity_checks": doSanityChecks,
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonSendRawTxResponse onResonse(Map<String, dynamic> result) {
    return DaemonSendRawTxResponse.fromJson(result);
  }
}
