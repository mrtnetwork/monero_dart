import 'package:blockchain_utils/blockchain_utils.dart';

/// Monero-specific error types. Phase 2: taxonomy only, no serialization.
enum MoneroErrorType implements BuErrorType {
  plugin(11000),
  crypto(11001),
  multisigAccount(11002),
  serialization(11003),
  scanner(11004),
  scannerFailed(11005),
  badKeyImage(11006),
  proof(11007);

  @override
  String get domain => 'monero';

  @override
  String get errName => name;

  @override
  final int id;
  const MoneroErrorType(this.id);

  @override
  bool isValid(int? tag) {
    for (final t in values) {
      if (t.id == tag) return true;
    }
    return false;
  }
}

/// Same-signature helpers replacing removed factory constructors.
abstract final class MoneroErrors {
  static BuError scannerFailed(
    String operation, {
    Map<String, String?>? details,
    String? reason,
  }) => BuError(
    MoneroErrorType.scannerFailed,
    "Block scan failed during $operation",
    details: {"reason": reason, ...details ?? {}}.notNullValue,
  );
}
