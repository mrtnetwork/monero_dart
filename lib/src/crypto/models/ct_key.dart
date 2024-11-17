import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class CtKey extends MoneroSerialization {
  /// The destination key
  final List<int> dest;

  /// The mask key,
  final List<int> mask;
  CtKey({required List<int> dest, required List<int> mask})
      : dest = dest.asImmutableBytes.exceptedLen(32),
        mask = mask.asImmutableBytes.exceptedLen(32);
  CtKey copyWith({List<int>? dest, List<int>? mask}) {
    return CtKey(dest: dest ?? this.dest, mask: mask ?? this.mask);
  }

  factory CtKey.fromStruct(Map<String, dynamic> json) {
    return CtKey(dest: json.asBytes("dest"), mask: json.asBytes("mask"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "dest"),
      LayoutConst.fixedBlob32(property: "mask")
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"mask": mask, "dest": dest};
  }

  Map<String, dynamic> toJson() {
    return {
      "mask": BytesUtils.toHexString(mask),
      "dest": BytesUtils.toHexString(dest)
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CtKey &&
          runtimeType == other.runtimeType &&
          BytesUtils.bytesEqual(dest, other.dest) &&
          BytesUtils.bytesEqual(mask, other.mask);
  @override
  int get hashCode =>
      HashCodeGenerator.generateBytesHashCode([...dest, ...mask]);
}
