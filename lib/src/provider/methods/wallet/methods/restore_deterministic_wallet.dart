import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Create and open a wallet on the RPC server from an existing mnemonic phrase and close the currently open wallet.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#restore_deterministic_wallet
class WalletRequestRestoreDeterministicWallet
    extends
        MoneroWalletRequestParam<
          WalletRPCRestoreDeterministicWalletResponse,
          Map<String, dynamic>
        > {
  WalletRequestRestoreDeterministicWallet({
    required this.fileName,
    required this.password,
    required this.seed,
    this.restoreHeight,
    this.language,
    this.seedOffset,
    this.autoSaveCurrent,
  });
  final String fileName;
  final String password;
  final String seed;
  final BigInt? restoreHeight;
  final String? language;
  final String? seedOffset;
  final bool? autoSaveCurrent;
  @override
  String get method => "restore_deterministic_wallet";
  @override
  Map<String, dynamic> get params => {
    "filename": fileName,
    "password": password,
    "seed": seed,
    "restore_height": restoreHeight?.toString(),
    "language": language,
    "seed_offset": seedOffset,
    "autosave_current": autoSaveCurrent,
  };

  @override
  WalletRPCRestoreDeterministicWalletResponse onResonse(
    Map<String, dynamic> result,
  ) {
    return WalletRPCRestoreDeterministicWalletResponse.fromJson(result);
  }
}
