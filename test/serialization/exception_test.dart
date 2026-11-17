import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/error/monero_error.dart';
import 'package:monero_dart/src/monero_base.dart';
import 'package:test/test.dart' show test, expect, equals;

import '../utils.dart';

void exceptionTest() {
  test('Exception serialization', () {
    BuErrorCodec.registerTypes(MoneroErrorType.values);
    {
      final error = BuError(
        MoneroErrorType.plugin,
        "error",
        details: {"length": "32"},
      );
      final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
      expect(decode.type, MoneroErrorType.plugin);
      expect(decode.message, "error");
      expect(decode.details, {"length": "32"});
    }
    {
      final error = BuError(
        MoneroErrorType.crypto,
        "error",
        details: {"length": "32"},
      );
      final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
      expect(decode.type, MoneroErrorType.crypto);
      expect(decode.message, "error");
    }
    {
      final error = BuError(
        MoneroErrorType.multisigAccount,
        "error",
        details: {"length": "32"},
      );
      final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
      expect(decode.type, MoneroErrorType.multisigAccount);
      expect(decode.message, "error");
    }
    {
      final error = BuError(
        MoneroErrorType.serialization,
        "error",
        details: {"length": "32"},
      );
      final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
      expect(decode.type, MoneroErrorType.serialization);
      expect(decode.message, "error");
    }
    {
      final error = MoneroErrors.scannerFailed("sync", reason: "timeout");
      expect(error.type, MoneroErrorType.scannerFailed);
      expect(error.message, "Block scan failed during sync");
      final decode = BuErrorCodec.decode(bytes: error.toCborBytes());
      expect(decode.type, MoneroErrorType.scannerFailed);
      expect(decode.details, {"reason": "timeout"});
    }
    {
      final ids = MoneroErrorType.values.map((e) => e.id);
      expect(ids.toSet().length, MoneroErrorType.values.length);
      for (final id in ids) {
        expect(id > 258, equals(true));
      }
    }
  });
}

void main() {
  MoneroTestApi.runTest(exceptionTest, "Exception");
}
