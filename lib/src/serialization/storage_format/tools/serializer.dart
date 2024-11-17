import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:monero_dart/src/serialization/exception/exception.dart';
import 'package:monero_dart/src/serialization/storage_format/constant/constant.dart';
import 'package:monero_dart/src/serialization/storage_format/types/binary_container.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/validator.dart';
import 'package:monero_dart/src/serialization/storage_format/types/storage_result.dart';
import 'package:monero_dart/src/serialization/storage_format/types/types.dart';


class MoneroStorageSerializer {
  static Map<String, dynamic> deserialize(List<int> bytes,
      {bool withSignature = true}) {
    bytes = bytes.asImmutableBytes;
    if (withSignature) {
      if (bytes.length <
          MoneroSerializationConst.signaturePartBAndVersionVersion.length) {
        throw const MoneroSerializationException(
            "Missing or invalid signature and version information.");
      }
      final signature = bytes.sublist(
          0, MoneroSerializationConst.signaturePartBAndVersionVersion.length);
      if (!BytesUtils.bytesEqual(signature,
          MoneroSerializationConst.signaturePartBAndVersionVersion)) {
        throw const MoneroSerializationException(
            "Missing or invalid signature and version information.");
      }
    }
    final decode = decodeSection(
        bytes: bytes,
        offset: withSignature
            ? MoneroSerializationConst.signaturePartBAndVersionVersion.length
            : 0);
    return decode.value;
  }

  static DecodeStorageResult<Map<String, dynamic>> decodeSection(
      {required List<int> bytes, int offset = 0}) {
    int o = 0;
    if (bytes[o + offset] == 0x00) {
      o++;
      return DecodeStorageResult<Map<String, dynamic>>(length: o, value: {});
    }
    final decode = decodeVarint(bytes: bytes, offset: offset + o);
    o += decode.length;
    final len = decode.value;
    final Map<String, dynamic> values = {};
    for (int i = 0; i < len; i++) {
      final int nameLength = bytes[offset + o];
      o++;
      final name = StringUtils.decode(
          bytes.sublist(offset + o, offset + o + nameLength));
      o += nameLength;
      final int flagTag = bytes[offset + o];
      final flag = flagTag & ~MoneroSerializationConst.arrayFalgs;
      o++;
      final type = MoneroStorageTypes.fromFlag(flag);
      if (type == MoneroStorageTypes.array) {
        throw const MoneroSerializationException(
            "Invalid array element type: Unable to decode untyped element.");
      }
      if (flag != flagTag) {
        final decode =
            _decodeArray(bytes: bytes, childtype: type, offset: o + offset);
        values[name] = decode.value;
        o += decode.length;
        continue;
      }
      switch (type) {
        case MoneroStorageTypes.object:
          final decode = decodeSection(bytes: bytes, offset: offset + o);
          values[name] = decode.value;
          o += decode.length;
          break;
        default:
          final decode =
              _decodePromitive(bytes: bytes, type: type, offset: offset + o);
          values[name] = decode.value;
          o += decode.length;
          break;
      }
    }
    return DecodeStorageResult(value: values, length: o);
  }

  static DecodeStorageResult _decodePromitive(
      {required List<int> bytes,
      required MoneroStorageTypes type,
      int offset = 0}) {
    if (type.isInteger) {
      final typeDetails = getNumericTypesBitLength(type);
      return _decodeNumeric(
          bytes: bytes,
          bitLength: typeDetails.item1,
          sign: typeDetails.item2,
          offset: offset);
    }
    switch (type) {
      case MoneroStorageTypes.boolType:
        return _decodeBoolean(bytes: bytes, offset: offset);
      case MoneroStorageTypes.string:
        return _decodeString(bytes: bytes, offset: offset);
      case MoneroStorageTypes.double:
        return _decodeDouble(bytes: bytes, offset: offset);
      default:
    }
    throw MoneroSerializationException("Invalid promitive type.",
        details: {"type": type.name});
  }

  static DecodeStorageResult<List> _decodeArray(
      {required List<int> bytes,
      required MoneroStorageTypes childtype,
      int offset = 0}) {
    final length = decodeVarint(bytes: bytes, offset: offset);
    int len = length.length;
    final List<dynamic> values = [];
    for (int i = 0; i < length.value; i++) {
      switch (childtype) {
        case MoneroStorageTypes.object:
          final decode = decodeSection(bytes: bytes, offset: offset + len);
          values.add(decode.value);
          len += decode.length;
          break;
        case MoneroStorageTypes.array:
          throw const MoneroSerializationException(
              "Invalid array element type: Unable to decode untyped element.");
        default:
          final decode = _decodePromitive(
              bytes: bytes, offset: offset + len, type: childtype);
          values.add(decode.value);
          len += decode.length;
          break;
      }
    }
    return DecodeStorageResult(value: values, length: len);
  }

  static DecodeStorageResult<bool> _decodeBoolean(
      {required List<int> bytes, int offset = 0}) {
    final int byte = bytes[offset];
    if (byte != 1 && byte != 0) {
      throw MoneroSerializationException("Invalid boolean byte.",
          details: {"byte": byte});
    }
    return DecodeStorageResult(value: byte == 1, length: 1);
  }

  static DecodeStorageResult<String> _decodeString(
      {required List<int> bytes, int offset = 0}) {
    final decodeLength = decodeVarint(bytes: bytes, offset: offset);
    offset += decodeLength.length;
    final strBytes =
        bytes.sublist(offset, offset + decodeLength.value).immutable;
    String? str = StringUtils.tryDecode(strBytes);
    str ??= BytesUtils.toHexString(strBytes);
    return DecodeStorageResult(
        value: str, length: decodeLength.length + decodeLength.value);
  }

  static DecodeStorageResult<double> _decodeDouble(
      {required List<int> bytes, int offset = 0}) {
    final value = DoubleCoder.fromBytes(bytes.sublist(offset, offset + 8),
        byteOrder: Endian.little);
    return DecodeStorageResult(value: value, length: 8);
  }

  static DecodeStorageResult<BigInt> _decodeNumeric(
      {required List<int> bytes,
      required int bitLength,
      required bool sign,
      int offset = 0}) {
    final byteLength = bitLength ~/ 8;
    final value = BigintUtils.fromBytes(
        bytes.sublist(offset, offset + byteLength),
        byteOrder: Endian.little,
        sign: sign);
    return DecodeStorageResult(value: value, length: byteLength);
  }

  static int getVarintLength(int byte) {
    final int lastByte =
        byte & MoneroSerializationConst.portableRawSizeMarkMask;
    switch (lastByte) {
      case MoneroSerializationConst.portableRawSizeMarkByte:
        return 1;
      case MoneroSerializationConst.portableRawSizeMarkWord:
        return 2;
      case MoneroSerializationConst.portableRawSizeMarkDword:
        return 4;
      case MoneroSerializationConst.portableRawSizeMarkInt64:
        return 8;
      default:
        throw const MoneroSerializationException("Invalid varint mark.");
    }
  }

  static DecodeStorageResult<int> decodeVarint(
      {required List<int> bytes, int offset = 0}) {
    final int length = getVarintLength(bytes[offset]);
    BigInt value = BigintUtils.fromBytes(bytes.sublist(offset, offset + length),
        byteOrder: Endian.little);
    value = value >> 2;
    if (value.isValidInt) {
      return DecodeStorageResult(length: length, value: value.toInt());
    }
    throw const MoneroSerializationException(
        "Your environment cannot fully decode 62-bit varint.");
  }

  static DecodeStorageResult<BigInt> decodeVarintBig(
      {required List<int> bytes, int offset = 0}) {
    final int length = getVarintLength(bytes[offset]);
    BigInt value = BigintUtils.fromBytes(bytes.sublist(offset, offset + length),
        byteOrder: Endian.little);
    value = value >> 2;
    return DecodeStorageResult(length: length, value: value);
  }

  static Tuple<int, bool> getNumericTypesBitLength(MoneroStorageTypes type) {
    if (!type.isInteger) {
      throw MoneroSerializationException(
          "The provided type is not integer type.",
          details: {"type": type.name});
    }
    final bitlenPart = type.name.split(RegExp(r'[^0-9]+'));
    final int bitLength = int.parse(bitlenPart[1]);
    return Tuple(bitLength, type.name.startsWith("INT"));
  }

  static List<int> encodePrimitive(
      {required Object value, required MoneroStorageTypes type}) {
    return [type.flag, ..._encodePrimitive(value: value, type: type)];
  }

  static List<int> _encodePrimitive(
      {required Object value, required MoneroStorageTypes type}) {
    if (value is MoneroStorageContainer) {
      return value.serialize();
    }
    if (type.isInteger) {
      final info = getNumericTypesBitLength(type);
      final asBigInt = MoneroStorageFormatValidator.asA<BigInt>(value);
      return BigintUtils.toBytes(asBigInt,
          length: info.item1 ~/ 8, order: Endian.little);
    }
    switch (type) {
      case MoneroStorageTypes.string:
        final asString = MoneroStorageFormatValidator.asA<String>(value);

        final encodeStr = StringUtils.encode(asString);
        final encodeLen = encodeVarintInt(encodeStr.length);
        return [...encodeLen, ...encodeStr];
      case MoneroStorageTypes.boolType:
        final asBool = MoneroStorageFormatValidator.asA<bool>(value);
        if (asBool) return [0x01];
        return [0x00];
      case MoneroStorageTypes.double:
        final asDouble = MoneroStorageFormatValidator.asA<double>(value);
        return DoubleCoder.toBytes(asDouble, byteOrder: Endian.little);
      default:
        throw MoneroSerializationException("Invalid promitive type.",
            details: {"type": type.name, "value": value.toString()});
    }
  }

  static List<int> encodeList(
      {required List<Object> value, required MoneroStorageTypes childType}) {
    final List<int> bytes = [...encodeVarintInt(value.length)];
    if (childType.isPrimitive) {
      for (final i in value) {
        final encode = _encodePrimitive(value: i, type: childType);
        bytes.addAll(encode);
      }
    } else {
      final sections = List<MoneroSection>.from(value);
      for (final i in sections) {
        bytes.addAll(i.serialize());
      }
    }
    final int flag = MoneroSerializationConst.arrayFalgs | childType.flag;
    return [flag, ...bytes];
  }

  static List<int> encodeVarintInt(int val) {
    if (val.isNegative) {
      throw MoneroSerializationException(
          "Negative values are not allowed for varints.",
          details: {"varint": val.toString()});
    }
    if (val <= MoneroSerializationConst.varintMaxOnByte) {
      int v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkByte;
      return [v];
    } else if (val <= MoneroSerializationConst.varintMaxTwoByte) {
      int v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkWord;
      return IntUtils.toBytes(v, length: 2, byteOrder: Endian.little);
    } else if (val <= MoneroSerializationConst.varintMaxFourByte) {
      int v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkDword;
      return IntUtils.toBytes(v, length: 4, byteOrder: Endian.little);
    }
    throw MoneroSerializationException(
        "Varint is too large to be encoded as bytes. use `encodeVarintBigInt` instead `encodeVarintInt`",
        details: {"varint": val});
  }

  static List<int> encodeVarintBigInt(BigInt val) {
    if (val.isNegative) {
      throw MoneroSerializationException(
          "Negative values are not allowed for varints.",
          details: {"varint": val.toString()});
    }
    if (val <= MoneroSerializationConst.varintBigIntMaxOnByte) {
      BigInt v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkByteBigInt;
      return [v.toInt()];
    } else if (val <= MoneroSerializationConst.varintBigIntMaxTwoByte) {
      BigInt v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkWordBigInt;
      return BigintUtils.toBytes(v, length: 2, order: Endian.little);
    } else if (val <= MoneroSerializationConst.varintBigIntMaxFourByte) {
      BigInt v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkDwordBigInt;
      return BigintUtils.toBytes(v, length: 4, order: Endian.little);
    } else if (val <= MoneroSerializationConst.varintBigIntMaxEightByte) {
      BigInt v = val << 2;
      v |= MoneroSerializationConst.portableRawSizeMarkInt64BigInt;
      return BigintUtils.toBytes(v, length: 8, order: Endian.little);
    }
    throw MoneroSerializationException(
        "Varint is too large to be encoded as bytes.",
        details: {"varint": val.toString()});
  }
}
