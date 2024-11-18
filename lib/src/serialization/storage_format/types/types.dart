import 'package:monero_dart/src/serialization/exception/exception.dart';

class MoneroStorageTypes {
  const MoneroStorageTypes._(this.name, this._value,
      {this.isPrimitive = true, this.isInteger = true});

  // Fields to hold the string name and the associated value
  final String name;
  final int _value;
  final bool isPrimitive;
  final bool isInteger;

  int get flag {
    if (this == MoneroStorageTypes.unknown) {
      throw const MoneroSerializationException(
          "Unknown type: No associated flag found.");
    }
    return _value;
  }

  // Define common serialization types as static constants
  static const MoneroStorageTypes int64 = MoneroStorageTypes._("INT64", 0x1);
  static const MoneroStorageTypes int32 = MoneroStorageTypes._("INT32", 0x2);
  static const MoneroStorageTypes int16 = MoneroStorageTypes._("INT16", 0x3);
  static const MoneroStorageTypes int8 = MoneroStorageTypes._("INT8", 0x4);
  static const MoneroStorageTypes uint64 = MoneroStorageTypes._("UINT64", 0x5);
  static const MoneroStorageTypes uint32 = MoneroStorageTypes._("UINT32", 0x6);
  static const MoneroStorageTypes uint16 = MoneroStorageTypes._("UINT16", 0x7);
  static const MoneroStorageTypes uint8 = MoneroStorageTypes._("UINT8", 0x8);
  static const MoneroStorageTypes double =
      MoneroStorageTypes._("DOUBLE", 0x9, isInteger: false);
  static const MoneroStorageTypes string =
      MoneroStorageTypes._("STRING", 0xa, isInteger: false);
  static const MoneroStorageTypes boolType =
      MoneroStorageTypes._("BOOL", 0xb, isInteger: false);
  static const MoneroStorageTypes object =
      MoneroStorageTypes._("OBJECT", 0xc, isPrimitive: false, isInteger: false);
  static const MoneroStorageTypes array =
      MoneroStorageTypes._("ARRAY", 0xd, isPrimitive: false, isInteger: false);
  static const MoneroStorageTypes unknown = MoneroStorageTypes._(
      "Unknown", 0x00,
      isPrimitive: false, isInteger: false);
  static const List<MoneroStorageTypes> values = [
    int64,
    int32,
    int16,
    uint64,
    uint32,
    uint16,
    uint8,
    double,
    string,
    boolType,
    object,
    array
  ];
  static MoneroStorageTypes fromFlag(int flag) {
    return values.firstWhere(
      (e) => e.flag == flag,
      orElse: () => throw MoneroSerializationException(
          "Invalid storage type: Unable to determine the correct type from the provided flag.",
          details: {"flag": flag}),
    );
  }

  @override
  String toString() {
    return 'MoneroStorageTypes.$name';
  }
}
