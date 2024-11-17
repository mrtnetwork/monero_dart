import 'package:blockchain_utils/blockchain_utils.dart';

/// exception related to monero crypto operations.
class MoneroCryptoException extends BlockchainUtilsException {
  const MoneroCryptoException(super.message, {super.details});
}
