import 'package:monero_dart/src/provider/core/core.dart';

/// Label an account.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#label_account
class WalletRequestLabelAccount
    extends
        MoneroWalletRequestParam<Map<String, dynamic>, Map<String, dynamic>> {
  const WalletRequestLabelAccount({
    required this.accountIndex,
    required this.label,
  });

  /// Apply label to account at this index.
  final int accountIndex;

  /// Label for the account.
  final String label;
  @override
  String get method => "label_account";
  @override
  Map<String, dynamic> get params => {
    "account_index": accountIndex,
    "label": label,
  };
}
