import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';

import 'variant.dart';

class VariantOffsetLayout extends ExternalOffsetLayout {
  VariantOffsetLayout({super.property});
  final MoneroIntVarInt layout = MoneroIntVarInt(LayoutConst.u48());
  @override
  bool isCount() {
    return true;
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = layout.decode(bytes, offset: offset);
    return decode;
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final encodeLength = MoneroIntVarInt.writeVarint(source);
    writer.setAll(offset, encodeLength);
    return encodeLength.length;
  }

  @override
  VariantOffsetLayout clone({String? newProperty}) {
    return VariantOffsetLayout(property: newProperty);
  }

  @override
  LayoutDecodeResult<int> getLenAndSpan(LayoutByteReader bytes,
      {int offset = 0}) {
    throw UnimplementedError();
  }
}
