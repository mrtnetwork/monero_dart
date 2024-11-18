import 'package:monero_dart/monero_dart.dart';

/// exception related to monero crypto operations.
class MoneroCryptoException extends DartMoneroPluginException {
  const MoneroCryptoException(super.message, {super.details});
}
