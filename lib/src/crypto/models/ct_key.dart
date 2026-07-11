import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class CtKey extends MoneroSerialization with Equality {
  /// The destination key
  final List<int> dest;

  /// The mask key,
  final List<int> mask;
  CtKey({required List<int> dest, required List<int> mask})
    : dest = dest.asImmutableBytes.exc(
        length: 32,
        operation: "CtKey",
        reason: "Invalid dest bytes length.",
      ),
      mask = mask.asImmutableBytes.exc(
        length: 32,
        operation: "CtKey",
        reason: "Invalid mask bytes length.",
      );
  CtKey copyWith({List<int>? dest, List<int>? mask}) {
    return CtKey(dest: dest ?? this.dest, mask: mask ?? this.mask);
  }

  factory CtKey.deserializeJson(Map<String, dynamic> json) {
    return CtKey(
      dest: json.valueAsBytes("dest"),
      mask: json.valueAsBytes("mask"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "dest"),
      LayoutConst.fixedBlob32(property: "mask"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"mask": mask, "dest": dest};
  }

  Map<String, dynamic> toJson() {
    return {
      "mask": BytesUtils.toHexString(mask),
      "dest": BytesUtils.toHexString(dest),
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  List<dynamic> get variables => [dest, mask];
}
