import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/exception/exception.dart';
import 'package:monero_dart/src/serialization/storage_format/constant/constant.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';
import 'package:monero_dart/src/serialization/storage_format/types/types.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/validator.dart';

import 'binary_container.dart';

/// Monero storage
class MoneroStorage {
  /// section
  final MoneroSection section;
  const MoneroStorage(this.section);
  factory MoneroStorage.fromJson(Map<String, dynamic> json) {
    return MoneroStorage(MoneroSection.fromJson(json));
  }
  factory MoneroStorage.deserialize(List<int> bytes) {
    return MoneroStorage(
        MoneroSection.fromJson(MoneroStorageSerializer.deserialize(bytes)));
  }

  /// encode storage to bytes.
  List<int> serialize() {
    return [
      ...MoneroSerializationConst.signaturePartBAndVersionVersion,
      ...section.serialize()
    ];
  }

  /// encode storage to hex string.
  String serializeHex() {
    return BytesUtils.toHexString(serialize());
  }
}

/// Monero section
class MoneroSection {
  /// entries of section
  final List<MoneroStorageEntry> enteries;
  MoneroSection(List<MoneroStorageEntry> enteries)
      : enteries = enteries.immutable;

  factory MoneroSection.fromJson(Map<String, dynamic> json) {
    final sortedMap = json.keys.toList()..sort();
    return MoneroSection(sortedMap
        .map((k) => MoneroStorageEntry.fromObject(name: k, value: json[k]))
        .toList());
  }

  /// check section has any entries or should be serialize as empty section.
  bool get hasValue {
    return !enteries.every((e) => !e.hasValue);
  }

  List<int> serialize() {
    final enteries = this.enteries.where((e) => e.hasValue);
    return [
      ...MoneroStorageSerializer.encodeVarintInt(enteries.length),
      ...enteries.expand((e) => e.serialize())
    ];
  }

  String serializeHex() {
    return BytesUtils.toHexString(serialize());
  }
}

abstract class MoneroStorageEntry<T> {
  /// the value of entery
  final T value;

  /// the name of entery
  final String name;

  /// the type of value
  final MoneroStorageTypes type;

  bool get hasValue => value != null;
  MoneroStorageEntry(
      {required this.type, required String name, required this.value})
      : name = MoneroStorageFormatValidator.asValidName(name);
  factory MoneroStorageEntry.fromObject({required String name, Object? value}) {
    final MoneroStorageEntry entry;
    if (value == null) {
      entry = MoneroStorageEntryNull(name);
    } else {
      final type = MoneroStorageFormatValidator.findType(value);

      if (type.isPrimitive) {
        entry = MoneroStorageEntryPromitive(name: name, value: value);
      } else if (type == MoneroStorageTypes.object) {
        entry = MoneroStorageEntrySection(
            json: MoneroStorageFormatValidator.asMap(value), name: name);
      } else {
        final list = MoneroStorageFormatValidator.asArrayOf<Object>(value,
            allowEmpty: true);
        if (list.isEmpty) {
          entry = MoneroStorageEntryNull(name);
        } else {
          entry = MoneroStorageEntryList(name: name, value: list);
        }
      }
    }
    if (entry is! MoneroStorageEntry<T>) {
      throw MoneroSerializationException(
          "Incorrect MoneroStorageEntry<$T> type",
          details: {"excepted": "$T", "entery": entry.runtimeType});
    }
    return entry;
  }

  List<int> serialize();
  String serializeHex() {
    return BytesUtils.toHexString(serialize());
  }
}

/// Entery for null objects
class MoneroStorageEntryNull extends MoneroStorageEntry<Null> {
  MoneroStorageEntryNull._({
    required super.name,
  }) : super(type: MoneroStorageTypes.unknown, value: null);
  factory MoneroStorageEntryNull(String name) {
    return MoneroStorageEntryNull._(name: name);
  }

  @override
  List<int> serialize() {
    return [0x00];
  }
}

class MoneroStorageEntryPromitive<T> extends MoneroStorageEntry<T> {
  @override
  final bool hasValue;
  MoneroStorageEntryPromitive._(
      {required super.name,
      required super.type,
      required super.value,
      required this.hasValue});
  factory MoneroStorageEntryPromitive(
      {required String name, required T value}) {
    final correctValue = MoneroStorageFormatValidator.asPrimitiveType<T>(value);
    bool hasValue = correctValue.item1 != null;
    if (hasValue && value is MoneroStorageContainer) {
      hasValue = value.hasValue;
    }
    return MoneroStorageEntryPromitive._(
        name: name,
        type: correctValue.item2,
        value: correctValue.item1,
        hasValue: hasValue);
  }

  @override
  List<int> serialize() {
    return [
      name.length,
      ...StringUtils.encode(name),
      ...MoneroStorageSerializer.encodePrimitive(type: type, value: value!)
    ];
  }
}

class MoneroStorageEntryList<T extends Object>
    extends MoneroStorageEntry<List<T>> {
  final MoneroStorageTypes childType;
  MoneroStorageEntryList._(
      {required super.name,
      required this.childType,
      required super.type,
      required super.value});
  factory MoneroStorageEntryList(
      {required String name, required List<T> value}) {
    final values = MoneroStorageFormatValidator.toArrayObject<T>(value);
    return MoneroStorageEntryList._(
        name: name,
        childType: values.item1,
        type: MoneroStorageTypes.array,
        value: values.item2);
  }
  @override
  bool get hasValue => value.isNotEmpty;
  @override
  List<int> serialize() {
    return [
      name.length,
      ...StringUtils.encode(name),
      ...MoneroStorageSerializer.encodeList(childType: childType, value: value)
    ];
  }
}

class MoneroStorageEntrySection extends MoneroStorageEntry<MoneroSection> {
  MoneroStorageEntrySection._(
      {required super.name, required super.type, required super.value});
  factory MoneroStorageEntrySection(
      {required Map<String, dynamic> json, required String name}) {
    return MoneroStorageEntrySection._(
        name: name,
        type: MoneroStorageTypes.object,
        value: MoneroSection.fromJson(json));
  }

  @override
  List<int> serialize() {
    if (!value.hasValue) return [0x00];
    return [
      name.length,
      ...StringUtils.encode(name),
      MoneroStorageTypes.object.flag,
      ...value.serialize(),
    ];
  }
}
