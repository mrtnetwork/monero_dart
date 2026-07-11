import 'package:monero_dart/src/monero_base.dart';
import 'package:test/test.dart' show test, expect;

void main() {
  test('Exception serialization', () {
    {
      final error = DartMoneroPluginException(
        "error",
        details: {"length": "32"},
      );
      final decode = BaseDartMoneroPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = MoneroCryptoException("error", details: {"length": "32"});
      final decode = BaseDartMoneroPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = MoneroMultisigAccountException(
        "error",
        details: {"length": "32"},
      );
      final decode = BaseDartMoneroPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = MoneroSerializationException(
        "error",
        details: {"length": "32"},
      );
      final decode = BaseDartMoneroPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
  });
}
