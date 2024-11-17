import 'package:monero_dart/src/provider/core/core.dart';

/// Generate a signature to prove of an available amount in a wallet.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#get_reserve_proof
class WalletRequestGetReserveProof
    extends MoneroWalletRequestParam<String, Map<String, dynamic>> {
  WalletRequestGetReserveProof(
      {required this.all,
      required this.accountIndex,
      required this.amount,
      this.message});

  /// Proves all wallet balance to be disposable.
  final bool all;

  /// Specify the account from which to prove reserve. (ignored if all is set to true)
  final int accountIndex;

  /// Amount (in atomic-units) to prove the account has in reserve. (ignored if all is set to true)
  final BigInt amount;

  /// add a message to the signature to further authenticate the proving process.
  /// If a message is added to get_reserve_proof (optional),
  /// this message will be required when using check_reserve_proof
  final String? message;
  @override
  String get method => "get_reserve_proof";
  @override
  Map<String, dynamic> get params => {
        "all": all,
        "account_index": accountIndex,
        "amount": amount.toString(),
        "message": message
      };

  @override
  String onResonse(Map<String, dynamic> result) {
    return result["signature"];
  }
}
