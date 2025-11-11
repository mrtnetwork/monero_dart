import 'package:blockchain_utils/helper/helper.dart';
import 'package:monero_dart/src/exception/exception.dart';

extension IntegerListValidator<T> on List<int> {
  List<int> as32Bytes(String operationName) {
    if (length != 32) {
      throw DartMoneroPluginException(
          "$operationName failed. incorrect key 32 length.",
          details: {"expected": 32, "length": length});
    }
    return this;
  }
}

extension StringValidator on String {
  String max(int length, {String? name}) {
    if (this.length > length) {
      throw DartMoneroPluginException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {"maximum": length, "length": this.length});
    }
    return this;
  }

  String min(int length, {String? name}) {
    if (this.length < length) {
      throw DartMoneroPluginException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {"minimum": length, "length": this.length});
    }
    return this;
  }

  String exc(int length, {String? name}) {
    if (this.length != length) {
      throw DartMoneroPluginException(
          "Incorrect ${name == null ? '' : '$name '}array length.",
          details: {"expected": length, "length": this.length});
    }
    return this;
  }
}

extension QuickMap on Map<String, dynamic> {
  static const Map<String, dynamic> _map = {};
  static const List _list = [];
  void asEmpty({String? error}) {
    if (isEmpty) return;
    throw DartMoneroPluginException(
        error ?? "The map must be empty, but data was received.");
  }

  T as<T>(String key) {
    final value = _getValue(key, throwOnNull: null is! T);
    if (value == null) return value;
    try {
      return value as T;
    } on TypeError {
      throw DartMoneroPluginException("Incorrect value.", details: {
        "key": key,
        "expected": "$T",
        "value": value.runtimeType,
        "data": this
      });
    }
  }

  dynamic _getValue(String key, {bool throwOnNull = true}) {
    final value = this[key];
    if (value == null) {
      if (!throwOnNull) {
        return null;
      }
      throw DartMoneroPluginException("Key not found.",
          details: {"key": key, "data": this});
    }
    return value;
  }

  List<BigInt>? asListBig(String key, {bool throwOnNull = true}) {
    final value = _getValue(key, throwOnNull: throwOnNull);
    if (value == null) return value;
    try {
      return (value as List).cast<BigInt>();
    } on TypeError {
      throw DartMoneroPluginException("Incorrect list of big integer.",
          details: {"key": key, "data": this});
    }
  }

  List<List<int>>? asListBytes(String key, {bool throwOnNull = true}) {
    final value = _getValue(key, throwOnNull: throwOnNull);
    if (value == null) return value;
    try {
      return (value as List)
          .map((e) => (e as List).cast<int>().asBytes)
          .toList();
    } on TypeError {
      throw DartMoneroPluginException("Incorrect list of bytes.",
          details: {"key": key, "data": this});
    }
  }

  List<List<List<int>>>? asListOfListBytes(String key,
      {bool throwOnNull = true}) {
    final value = _getValue(key, throwOnNull: throwOnNull);
    if (value == null) return value;
    try {
      return (value as List)
          .map((e) =>
              (e as List).cast<List<int>>().map((d) => d.asBytes).toList())
          .toList();
    } on TypeError {
      throw DartMoneroPluginException("Incorrect list of list bytes.",
          details: {"key": key, "data": this});
    }
  }

  E asMap<E>(String key) {
    if (_map is! E) {
      throw const DartMoneroPluginException(
          "Invalid map casting. only use `asMap` method for casting Map<String,dynamic>.");
    }
    final Map? value = as(key);
    if (value == null) {
      if (null is E) {
        return null as E;
      }
      throw DartMoneroPluginException("Key not found.",
          details: {"key": key, "data": this});
    }
    try {
      return value.cast<String, dynamic>() as E;
    } on TypeError {
      throw DartMoneroPluginException("Incorrect value.", details: {
        "key": key,
        "expected": "$E",
        "value": value.runtimeType,
        "data": this
      });
    }
  }

  E asBytes<E>(String key) {
    if (<int>[] is! E) {
      throw DartMoneroPluginException(
          "Invalid bytes casting. only use `valueAsList` method for bytes.",
          details: {"key": key});
    }
    final List? value = as(key);
    if (value == null) {
      if (null is E) {
        return null as E;
      }
      throw DartMoneroPluginException("Key not found.",
          details: {"key": key, "data": this});
    }
    try {
      return value.cast<int>() as E;
    } on TypeError {
      throw DartMoneroPluginException("Incorrect value.", details: {
        "key": key,
        "expected": "$E",
        "value": value.runtimeType,
        "data": this
      });
    }
  }

  List<Map<String, dynamic>>? asListOfMap(String key,
      {bool throwOnNull = true}) {
    final List? value = as(key);
    if (value == null) {
      if (!throwOnNull) {
        return null;
      }
      throw DartMoneroPluginException("Key not found.",
          details: {"key": key, "data": this});
    }
    try {
      return value.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (e, s) {
      throw DartMoneroPluginException("Incorrect value.", details: {
        "key": key,
        "value": value.runtimeType,
        "data": this,
        "error": e.toString(),
        "stack": s.toString()
      });
    }
  }

  E _valueAsList<T, E>(String key) {
    if (_list is! E) {
      throw const DartMoneroPluginException(
          "Invalid list casting. only use `valueAsList` method for list casting.");
    }
    final List? value = as(key);
    if (value == null) {
      if (null is E) {
        return null as E;
      }
      throw DartMoneroPluginException("Key not found.",
          details: {"key": key, "data": this});
    }
    try {
      if (_map is T) {
        return value.map((e) => (e as Map).cast<String, dynamic>()).toList()
            as E;
      }
      return value.cast<T>() as E;
    } on TypeError {
      throw DartMoneroPluginException("Incorrect value.", details: {
        "key": key,
        "expected": "$T",
        "value": value.runtimeType,
        "data": this
      });
    }
  }

  E? mybeAs<E, T>({
    required String key,
    required E Function(T) onValue,
  }) {
    if (this[key] != null) {
      if (_map is T) {
        return onValue(asMap(key));
      }

      if (_list is T) {
        return onValue(_valueAsList(key));
      }
      return onValue(as(key));
    }
    return null;
  }
}
