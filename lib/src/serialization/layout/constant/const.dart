import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/layout/layouts/variant.dart';
import 'package:monero_dart/src/serialization/layout/layouts/variant_offset.dart';

class MoneroLayoutConst {
  static MoneroBigIntVarInt varintBigInt({String? property}) {
    return MoneroBigIntVarInt(LayoutConst.u64(), property: property);
  }

  static MoneroIntVarInt varintInt({String? property}) {
    return MoneroIntVarInt(LayoutConst.u32(), property: property);
  }

  static CustomLayout<Map<String, dynamic>, List<int>> variantBytes(
      {String? property}) {
    return variantVec(LayoutConst.u8(), property: property);
  }

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
