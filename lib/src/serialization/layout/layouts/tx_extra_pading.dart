import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';

class TxExtraPaddingLayout extends Layout<List<int>> {
  TxExtraPaddingLayout({super.property}) : super(-1);

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    int start = offset;

    while (offset < bytes.length && bytes.at(offset) == 0) {
      offset++;
    }

    return LayoutDecodeResult(
      consumed: offset - start,
      value: bytes.sublist(start, offset),
    );
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    assert(source.every((e) => e == 0));
    writer.setAll(offset, source);
    return source.length;
  }

  @override
  TxExtraPaddingLayout clone({String? newProperty}) {
    return TxExtraPaddingLayout(property: newProperty);
  }
}
