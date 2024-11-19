import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/exception/exception.dart';

/// deserialize struct info for variant models.
/// like models have multiple subclass.
class MoneroVariantDecodeResult {
  final Map<String, dynamic> result;
  String get variantName => result["key"];
  Map<String, dynamic> get value => result["value"];
  MoneroVariantDecodeResult(Map<String, dynamic> result)
      : result = result.immutable;

  @override
  String toString() {
    return "$variantName: $value";
  }
}

abstract class MoneroSerialization {
  const MoneroSerialization();

  /// quick method for deserialize layout.
  static Map<String, dynamic> deserialize(
      {required List<int> bytes,
      required Layout<Map<String, dynamic>> layout}) {
    final decode = layout.deserialize(bytes);
    assert(bytes.length - decode.consumed == 0);
    return decode.value;
  }

  /// struct layout.
  Layout<Map<String, dynamic>> createLayout({String? property});

  /// model struct in map
  Map<String, dynamic> toLayoutStruct();

  /// serialize object with current layout and strcut.
  List<int> serialize({String? property}) {
    final layout = createLayout(property: property);
    return layout.serialize(toLayoutStruct());
  }

  /// serialize object and return hex.
  String serializeHex() {
    return BytesUtils.toHexString(serialize());
  }
}

/// base class for models with multiple sub class.
abstract class MoneroVariantSerialization extends MoneroSerialization {
  const MoneroVariantSerialization();
  static MoneroVariantDecodeResult toVariantDecodeResult(
      Map<String, dynamic> json) {
    if (json["key"] is! String || !json.containsKey("value")) {
      throw const MoneroSerializationException(
          "Invalid variant layout. only use enum layout to deserialize with `MoneroVariantSerialization.deserialize` method.");
    }
    return MoneroVariantDecodeResult(json);
  }

  /// quick method to deserialize variant struct bytes.
  static Map<String, dynamic> deserialize(
      {required List<int> bytes,
      required Layout<Map<String, dynamic>> layout}) {
    final json = layout.deserialize(bytes).value;
    if (json["key"] is! String || !json.containsKey("value")) {
      throw const MoneroSerializationException(
          "Invalid variant layout. only use enum layout to deserialize with `MoneroVariantSerialization.deserialize` method.");
    }
    return json;
  }

  /// name of variant
  String get variantName;

  /// the variant layout of struct.
  Layout<Map<String, dynamic>> createVariantLayout({String? property});

  /// convert struct to map for serialize struct.
  Map<String, dynamic> toVariantLayoutStruct() {
    return {variantName: toLayoutStruct()};
  }

  /// serialize struct with parent class and current variant.
  List<int> toVariantSerialize({String? property}) {
    final layout = createVariantLayout(property: property);
    return layout.serialize(toVariantLayoutStruct());
  }

  /// serialize struct in hex.
  String toVariantSerializeHex() {
    return BytesUtils.toHexString(toVariantSerialize());
  }
}
