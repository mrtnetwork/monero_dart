import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/layout/layout.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/models/block/header.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroBlock extends MoneroBlockheader {
  final MoneroTransaction minerTx;
  final List<List<int>> txHashes;
  MoneroBlock(
      {required super.majorVersion,
      required super.minorVersion,
      required super.timestamp,
      required super.hash,
      required super.nonce,
      required this.minerTx,
      required List<List<int>> txHashes})
      : txHashes = txHashes
            .map((e) => e.asImmutableBytes.exc(32, name: "tx hash"))
            .toList()
            .immutable;
  factory MoneroBlock.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroBlock.fromStruct(decode);
  }
  static List<String> getTxHashes(List<int> bytes, {String? property}) {
    final json = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return json.asListBytes("txHashes")!.map(BytesUtils.toHexString).toList();
  }

  factory MoneroBlock.fromStruct(Map<String, dynamic> json) {
    return MoneroBlock(
        majorVersion: json.as("majorVersion"),
        minorVersion: json.as("minorVersion"),
        timestamp: json.as("timestamp"),
        hash: json.asBytes("hash"),
        nonce: json.as("nonce"),
        minerTx: MoneroTransaction.fromStruct(json.asMap("minerTx")),
        txHashes: json.asListBytes("txHashes")!);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintInt(property: "majorVersion"),
      MoneroLayoutConst.varintInt(property: "minorVersion"),
      MoneroLayoutConst.varintBigInt(property: "timestamp"),
      LayoutConst.fixedBlob32(property: "hash"),
      LayoutConst.u32(property: "nonce"),
      MoneroTransaction.layout(property: "minerTx", forcePrunable: false),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "txHashes")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "majorVersion": majorVersion,
      "minorVersion": minorVersion,
      "timestamp": timestamp,
      "hash": hash,
      "nonce": nonce,
      "minerTx": minerTx.toLayoutStruct(),
      "txHashes": txHashes
    };
  }

  List<String> txIds() {
    return txHashes.map((e) => BytesUtils.toHexString(e)).toList();
  }

  String previousBlockHash() {
    return BytesUtils.toHexString(hash);
  }
}
