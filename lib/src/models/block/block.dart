import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/models/block/header.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MoneroBlock extends MoneroBlockheader {
  final MoneroTransaction minerTx;
  final List<List<int>> txHashes;
  MoneroBlock({
    required super.majorVersion,
    required super.minorVersion,
    required super.timestamp,
    required super.hash,
    required super.nonce,
    required this.minerTx,
    required List<List<int>> txHashes,
  }) : txHashes =
           txHashes
               .map(
                 (e) => e.asImmutableBytes.exc(
                   length: 32,
                   operation: "MoneroBlock",
                   name: "tx hash",
                   reason: "Invalid tx hash bytes length.",
                 ),
               )
               .toList()
               .immutable;
  factory MoneroBlock.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroBlock.deserializeJson(decode);
  }

  static List<String> getTxHashes(List<int> bytes, {String? property}) {
    final json = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return json
        .valueEnsureAsList<List<int>>("txHashes")
        .map(BytesUtils.toHexString)
        .toList();
  }

  factory MoneroBlock.deserializeJson(Map<String, dynamic> json) {
    return MoneroBlock(
      majorVersion: json.valueAs("majorVersion"),
      minorVersion: json.valueAs("minorVersion"),
      timestamp: json.valueAs("timestamp"),
      hash: json.valueAsBytes("hash"),
      nonce: json.valueAs("nonce"),
      minerTx: MoneroTransaction.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("minerTx"),
      ),
      txHashes: json.valueEnsureAsList<List<int>>("txHashes"),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintInt(property: "majorVersion"),
      MoneroLayoutConst.varintInt(property: "minorVersion"),
      MoneroLayoutConst.varintBigInt(property: "timestamp"),
      LayoutConst.fixedBlob32(property: "hash"),
      LayoutConst.u32(property: "nonce"),
      MoneroTransaction.layout(property: "minerTx", forcePrunable: false),
      MoneroLayoutConst.variantVec(
        LayoutConst.fixedBlob32(),
        property: "txHashes",
      ),
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
      "txHashes": txHashes,
    };
  }

  List<String> txIds() {
    return txHashes.map((e) => BytesUtils.toHexString(e)).toList();
  }

  String previousBlockHash() {
    return BytesUtils.toHexString(hash);
  }

  List<int> getBlockHashBytes() {
    final header = MoneroBlockheader.layout().serialize(toLayoutStruct());
    final txTree = getTxTreeHash();
    final extra = MoneroLayoutConst.varintInt().serialize(txHashes.length + 1);
    return QuickCrypto.keccack256Hash(
      MoneroLayoutConst.variantBytes().serialize([
        ...header,
        ...txTree,
        ...extra,
      ]),
    );
  }

  String getBlockHash() {
    return BytesUtils.toHexString(getBlockHashBytes());
  }

  List<int> getTxTreeHash() {
    final hashes = [minerTx.txHashBytes(), ...txHashes];
    const int hashSize = 32;
    if (hashes.length == 1) {
      return hashes[0];
    }
    if (hashes.length == 2) {
      return QuickCrypto.keccack256Hash([...hashes[0], ...hashes[1]]);
    }
    int count = hashes.length;
    int cnt = () {
      int pow = 2;
      while (pow < count) {
        pow <<= 1;
      }
      return pow >> 1;
    }();

    List<List<int>> ints = List.filled(cnt, List.filled(hashSize, 0));

    final int offset = 2 * cnt - count;

    for (int i = 0; i < offset; i++) {
      ints[i] = hashes[i];
    }

    for (int i = offset; i < cnt; i++) {
      ints[i] = hashes[i - offset];
    }
    for (int i = offset, j = offset; j < cnt; i += 2, j++) {
      ints[j] = QuickCrypto.keccack256Hash([...hashes[i], ...hashes[i + 1]]);
    }
    while (cnt > 2) {
      cnt >>= 1;

      for (int i = 0, j = 0; j < cnt; i += 2, j++) {
        ints[j] = QuickCrypto.keccack256Hash([...ints[i], ...ints[i + 1]]);
      }
    }
    return QuickCrypto.keccack256Hash([...ints[0], ...ints[1]]);
  }
}
