import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';
import 'package:monero_dart/src/serialization/storage_format/storage_format.dart';

/// Get global outputs of transactions. Binary request.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_o_indexesbin
class DaemonRequestGetOIndexes
    extends
        MoneroDaemonRequestParam<
          DaemonGetTxGlobalOutputIndexesResponse,
          Map<String, dynamic>
        > {
  DaemonRequestGetOIndexes(this.txId);

  /// binary txid
  final String txId;

  @override
  String get method => "get_o_indexes.bin";
  @override
  Map<String, dynamic> get params => {
    "txid": MoneroStorageBinary.fromListOfHex([txId]),
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.binary;

  @override
  DaemonGetTxGlobalOutputIndexesResponse onResonse(
    Map<String, dynamic> result,
  ) {
    return DaemonGetTxGlobalOutputIndexesResponse.fromJson(result);
  }
}
