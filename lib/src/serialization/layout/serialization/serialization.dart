import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/serialization/exception/exception.dart';

abstract class MoneroSerialization {
  static Map<String, dynamic> deserialize(
      {required List<int> bytes,
      required Layout<Map<String, dynamic>> layout}) {
    final decode = layout.deserialize(bytes);
    return decode.value;
  }

  const MoneroSerialization();

  Layout<Map<String, dynamic>> createLayout({String? property});
  Map<String, dynamic> toLayoutStruct();
  List<int> serialize({String? property}) {
    final layout = createLayout(property: property);
    return layout.serialize(toLayoutStruct());
  }

  String serializeHex() {
    return BytesUtils.toHexString(serialize());
  }
}

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

  String get variantName;
  Layout<Map<String, dynamic>> createVariantLayout({String? property});
  Map<String, dynamic> toVariantLayoutStruct() {
    return {variantName: toLayoutStruct()};
  }

  List<int> toVariantSerialize({String? property}) {
    final layout = createVariantLayout(property: property);
    return layout.serialize(toVariantLayoutStruct());
  }

  String toVariantSerializeHex() {
    return BytesUtils.toHexString(toVariantSerialize());
  }
}
