import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/tx_response.dart';

/// Look up one or more transactions by hash
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#get_transactions
class DaemonRequestGetTransactions
    extends MoneroDaemonRequestParam<List<TxResponse>, Map<String, dynamic>> {
  DaemonRequestGetTransactions(
    List<String> txHashes, {
    this.decodeAsJson,
    this.prune,
    this.split,
  }) : txHashes = txHashes.immutable;

  /// List of transaction hashes to look up.
  final List<String> txHashes;

  /// Optional (false by default). If set true, the returned transaction information will be decoded rather than binary.
  final bool? decodeAsJson;

  /// false by default
  final bool? prune;

  /// false by default
  final bool? split;
  @override
  String get method => "get_transactions";
  @override
  Map<String, dynamic> get params => {
    "txs_hashes": txHashes,
    "decode_as_json": decodeAsJson,
    "prune": prune,
    "split": split,
  };
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  List<TxResponse> onResonse(Map<String, dynamic> result) {
    final List? txs = result["txs"];
    if (txs?.isEmpty ?? true) return [];
    return txs!.map((e) => TxResponse.fromJson(e)).toList();
  }
}
