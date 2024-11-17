import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MECSignature extends MoneroSerialization {
  final RctKey c;
  final RctKey r;
  MECSignature({required RctKey c, required RctKey r})
      : c = c.as32Bytes("EcSignature").asImmutableBytes,
        r = r.as32Bytes("EcSignature").asImmutableBytes;
  factory MECSignature.fromBytes(List<int> bytes) {
    if (bytes.length != 64) {
      throw DartMoneroPluginException("Invalid EcSignature bytes length.",
          details: {"excepted": 64, "length": bytes.length});
    }
    return MECSignature(c: bytes.sublist(0, 32), r: bytes.sublist(32));
  }
  factory MECSignature.fromStruct(Map<String, dynamic> json) {
    return MECSignature(c: json.asBytes("c"), r: json.asBytes("r"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "c"),
      LayoutConst.fixedBlob32(property: "r"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"c": c, "r": r};
  }

  List<int> toBytes() {
    return [...c, ...r];
  }
}
