import 'package:monero_dart/src/exception/exception.dart';

/// exception for multisig account generating operations.
class MoneroMultisigAccountException extends DartMoneroPluginException {
  const MoneroMultisigAccountException(super.message, {super.details});
}
