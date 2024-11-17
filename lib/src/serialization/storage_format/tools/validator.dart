import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/exception/exception.dart';
import 'package:monero_dart/src/serialization/storage_format/types/binary_container.dart';
import 'package:monero_dart/src/serialization/storage_format/types/entry.dart';
import 'package:monero_dart/src/serialization/storage_format/types/types.dart';
import 'package:monero_dart/src/serialization/storage_format/tools/serializer.dart';

class MoneroStorageFormatValidator {
  static String asValidName(String name) {
    if (name.isEmpty || name.length > 255) {
      throw const MoneroSerializationException(
          "The entry name must be between 1 and 255 characters.");
    }
    return name;
  }

  static T asA<T>(Object? value) {
    try {
      return value as T;
    } catch (_) {
      throw MoneroSerializationException("Failed to cast to type $T.",
          details: {"value": value.toString()});
    }
  }

  static Map<String, dynamic> asMap(Object? value) {
    try {
      return (value as Map).cast<String, dynamic>();
    } catch (_) {
      throw const MoneroSerializationException(
          "Invalid map: Object must be a Map<String, dynamic>.");
    }
  }

  static BigInt validateNumricData(
      {required Object? value, required MoneroStorageTypes type}) {
    final typeData = MoneroStorageSerializer.getNumericTypesBitLength(type);
    final toBig = BigintUtils.tryParse(value);
    if (toBig == null ||
        toBig.bitLength > typeData.item1 ||
        toBig.isNegative && !typeData.item2) {
      throw MoneroSerializationException(
          "Invalid numeric for type ${type.name}",
          details: {"type": type.name, "value": value.toString()});
    }
    return toBig;
  }

  static List<T> asArrayOf<T>(Object? value, {bool allowEmpty = false}) {
    try {
      final toList = (value as List).cast<Object?>();
      if (toList.isEmpty && !allowEmpty) {
        throw const MoneroSerializationException(
            "Invalid array values: Array must not be empty.");
      }
      if (toList.any((e) => e == null)) {
        throw MoneroSerializationException(
            "Invalid array values: Array cannot contain null elements.",
            details: {"elements": toList.map((e) => e.toString()).join(", ")});
      }

      return toList.cast<T>();
    } on MoneroSerializationException {
      rethrow;
    } catch (_) {
      throw MoneroSerializationException("Invalid array of $T.",
          details: {"value": value.toString()});
    }
  }

  static Tuple<MoneroStorageTypes, List<T>> toArrayObject<T>(Object? value) {
    try {
      final asList = asArrayOf<Object>(value);
      final type = findType(asList[0]);
      if (type.isPrimitive) {
        final List<Tuple<Object, MoneroStorageTypes>> toPromitive =
            asList.map((e) => asPrimitiveType<Object>(e)).toList();
        final MoneroStorageTypes type = toPromitive[0].item2;
        if (toPromitive.any((e) => e.item2 != type)) {
          throw MoneroSerializationException(
              "Invalid array values: All elements in the array must be of the same type.",
              details: {
                "type": type.name,
                "values": asList.map((e) => e.toString()).join(", ")
              });
        }
        return Tuple(type, toPromitive.map((e) => e.item1).toList().cast<T>());
      }
      if (type == MoneroStorageTypes.object) {
        try {
          final List<Map<String, dynamic>> values =
              asList.map((e) => (e as Map).cast<String, dynamic>()).toList();
          return Tuple(MoneroStorageTypes.object,
              values.map((e) => MoneroSection.fromJson(e)).toList().cast<T>());
        } catch (_) {}
      }
      throw MoneroSerializationException(
          "Invalid array values: Unable to determine the element type.",
          details: {"value": value.toString()});
    } on MoneroSerializationException {
      rethrow;
    } catch (e) {
      throw MoneroSerializationException("Invalid array of type $T",
          details: {"value": value.toString()});
    }
  }

  static MoneroStorageTypes findType(Object? value) {
    if (value is MoneroStorageContainer) {
      return value.type;
    }
    if (value is int || value is BigInt) {
      final val = BigintUtils.parse(value);
      if (val.isNegative) {
        return MoneroStorageTypes.int64;
      }
      return MoneroStorageTypes.uint64;
    }
    if (value is String) {
      return MoneroStorageTypes.string;
    } else if (value is bool) {
      return MoneroStorageTypes.boolType;
    } else if (value is double) {
      return MoneroStorageTypes.double;
    } else if (value is List) {
      return MoneroStorageTypes.array;
    } else if (value is Map) {
      return MoneroStorageTypes.object;
    }
    throw MoneroSerializationException(
        "Unknown storage format: Unable to determine the correct type for the provided value.",
        details: {"value": value});
  }

  static Tuple<T, MoneroStorageTypes> asPrimitiveType<T>(Object? value) {
    final type = findType(value);
    if (type.isPrimitive) {
      final currentValue = validatePrimitiveObjects(value: value, type: type);
      if (currentValue is! T) {
        throw MoneroSerializationException("Incorrect primitive $T value.",
            details: {"value": value});
      }
      return Tuple(currentValue as T, type);
    }
    throw MoneroSerializationException("Invalid primitive value.",
        details: {"value": value});
  }

  static Object validatePrimitiveObjects(
      {required Object? value, required MoneroStorageTypes type}) {
    if (value is MoneroStorageContainer && value.type.isPrimitive) {
      return value;
    }
    if (type.isInteger) {
      return MoneroStorageFormatValidator.validateNumricData(
          value: value, type: type);
    }
    switch (type) {
      case MoneroStorageTypes.double:
        if (value is double) return value;
        break;
      case MoneroStorageTypes.string:
        if (value is String) return value;
        break;
      case MoneroStorageTypes.boolType:
        if (value is bool) return value;
        break;

      default:
        break;
    }
    throw MoneroSerializationException("Invalid value for type ${type.name}",
        details: {"type": type.name, "value": value.toString()});
  }
}
