import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/layout/layouts/variant.dart';
import 'package:monero_dart/src/serialization/layout/layouts/variant_offset.dart';

class MoneroLayoutConst {
  /// var bigint layout. serialize BigInteger to monero var int.
  static MoneroBigIntVarInt varintBigInt({String? property}) {
    return MoneroBigIntVarInt(LayoutConst.u64(), property: property);
  }

  /// var int layout. serialize Integer to monero var int.
  static MoneroIntVarInt varintInt({String? property}) {
    return MoneroIntVarInt(LayoutConst.u32(), property: property);
  }

  /// var int bytes. serialize bytes with length as varint.
  /// [...(length as varint),...data]
  static CustomLayout<Map<String, dynamic>, List<int>> variantBytes(
      {String? property}) {
    return variantVec(LayoutConst.u8(), property: property);
  }

  /// like [variantBytes] but serialize and deserialize string. used utf8 to encode and decode
  /// string to bytes.
  static Layout<String> variantString({String? property}) {
    return CustomLayout<List<int>, String>(
        layout: variantBytes(),
        decoder: (bytes) {
          return StringUtils.decode(bytes);
        },
        encoder: (src) {
          return StringUtils.encode(src);
        },
        property: property);
  }

  /// vector layout with specify sub layoyt.
  /// this convert length as varint then serialize each object of list.
  static CustomLayout<Map<String, dynamic>, List<T>> variantVec<T>(
      Layout<T> elementLayout,
      {String? property}) {
    final layout = LayoutConst.struct(
        [LayoutConst.seq(elementLayout, variantOffset(), property: 'values')]);
    return CustomLayout<Map<String, dynamic>, List<T>>(
      layout: layout,
      encoder: (data) => {"values": data},
      decoder: (data) => (data["values"] as List).cast<T>(),
      property: property,
    );
  }

  /// serialize key and value of map.
  static CustomLayout map(
      {required Layout keyLayout,
      required Layout valueLayout,
      String? property}) {
    final layout = LayoutConst.struct([
      LayoutConst.seq(
          MapEntryLayout(
              keyLayout: keyLayout, valueLayout: valueLayout, property: ""),
          variantOffset(),
          property: 'values'),
    ]);
    return CustomLayout<Map<String, dynamic>, Map<dynamic, dynamic>>(
      layout: layout,
      decoder: (data) {
        final List<MapEntry<dynamic, dynamic>> values =
            (data['values'] as List).cast();
        return Map.fromEntries(values);
      },
      encoder: (values) => {'values': values.entries.toList()},
      property: property,
    );
  }

  static VariantOffsetLayout variantOffset({String? property}) =>
      VariantOffsetLayout(property: property);
}
