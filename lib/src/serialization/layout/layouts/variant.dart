import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/layout.dart';

class MoneroBigIntVarInt extends Layout<BigInt> {
  MoneroBigIntVarInt(this.layout, {String? property})
      : super(-1, property: property);
  final BaseIntiger layout;
  static BigInt readVarintBig(List<int> bytes) {
    BigInt result = BigInt.zero;
    int shift = 0;
    for (int i = 0; i < bytes.length; i++) {
      final int byte = bytes[i];
      result |= BigInt.from((byte & 0x7F)) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        break;
      }
    }

    return result;
  }

  final BigInt continueFlag = BigInt.from(128);
  final BigInt sevenBitMask = BigInt.from(127);
  List<int> writeVarintBig(BigInt value) {
    final List<int> dest = [];
    while (value >= continueFlag) {
      final v = (value & sevenBitMask) | continueFlag;
      dest.add(v.toInt());
      value >>= 7;
    }
    final lastByte = (value & sevenBitMask).toInt();
    dest.add(lastByte);
    return dest;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, BigInt? source}) {
    int span = 0;
    while ((bytes!.at(offset + span) & 0x80) != 0) {
      span++;
    }
    return span + 1;
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final span = getSpan(bytes, offset: offset);
    final decode = readVarintBig(bytes.sublist(offset, offset + span));

    return LayoutDecodeResult(consumed: span, value: decode);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final encode = writeVarintBig(source);
    writer.setAll(offset, encode);
    return encode.length;
  }

  @override
  MoneroBigIntVarInt clone({String? newProperty}) {
    return MoneroBigIntVarInt(layout, property: newProperty);
  }
}

class MoneroIntVarInt extends Layout<int> {
  MoneroIntVarInt(this.layout, {String? property})
      : super(-1, property: property);
  final BaseIntiger layout;
  int readVarint(List<int> bytes, {int startIndex = 0}) {
    int result = 0;
    int shift = 0;
    for (int i = startIndex; i < bytes.length; i++) {
      final int byte = bytes[i];
      result |= (byte & 0x7F) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        break; // No more bytes to read
      }
    }

    return result;
  }

  static List<int> writeVarint(int value) {
    final List<int> dest = [];
    while (value >= 0x80) {
      dest.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    dest.add(value & 0x7F);
    return dest;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, int? source}) {
    int span = 0;
    while ((bytes!.at(offset + span) & 0x80) != 0) {
      span++;
    }
    return span + 1;
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final span = getSpan(bytes, offset: offset);
    final decode = readVarint(bytes.sublist(offset, offset + span));

    return LayoutDecodeResult(consumed: span, value: decode);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final encode = writeVarint(source);
    writer.setAll(offset, encode);
    return encode.length;
  }

  @override
  MoneroIntVarInt clone({String? newProperty}) {
    return MoneroIntVarInt(layout, property: newProperty);
  }
}
