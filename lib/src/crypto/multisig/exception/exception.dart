import 'package:blockchain_utils/exception/exception.dart';

/// exception for multisig account generating operations.
class MoneroMultisigAccountException extends BlockchainUtilsException {
  const MoneroMultisigAccountException(super.message, {super.details});
}
