import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';

class TxResponse {
  final int? height;
  final int? timestamp;
  final int? confirmations;
  final bool doubleSpend;
  final bool inPool;
  final List<BigInt> outoutIndices;
  final String txHash;
  final String txHex;
  final String prunableHash;
  final Map<String, dynamic>? txJson;
  TxResponse({
    required this.height,
    required this.timestamp,
    required this.confirmations,
    required this.doubleSpend,
    required this.inPool,
    required List<BigInt> outoutIndices,
    required this.txHash,
    required this.txHex,
    required this.prunableHash,
    this.txJson,
  }) : outoutIndices = outoutIndices.immutable;
  factory TxResponse.fromJson(Map<String, dynamic> json) {
    String txHex = json["as_hex"] ?? '';
    if (txHex.trim().isEmpty) {
      txHex = json["pruned_as_hex"];
    }
    Map<String, dynamic>? asJson;
    if ((json["as_json"] as String?)?.isNotEmpty ?? false) {
      asJson = StringUtils.tryToJson<Map<String, dynamic>>(json["as_json"]);
    }
    return TxResponse(
      height: IntUtils.tryParse(json["block_height"]),
      timestamp: IntUtils.tryParse(json["block_timestamp"]),
      confirmations: IntUtils.tryParse(json["confirmations"]),
      doubleSpend: json["double_spend_seen"],
      inPool: json["in_pool"],
      outoutIndices:
          (json["output_indices"] as List?)
              ?.map((e) => BigintUtils.parse(e))
              .toList() ??
          [],
      txHash: json["tx_hash"],
      txHex: txHex.trim(),
      prunableHash: json["prunable_hash"],
      txJson: asJson,
    );
  }

  MoneroTransaction toTx() {
    final toBytes = BytesUtils.tryFromHexString(txHex);
    if (toBytes?.isEmpty ?? true) {
      throw const DartMoneroPluginException("Invalid monero tx hex.");
    }
    return MoneroTransaction.deserialize(toBytes!);
  }
}
