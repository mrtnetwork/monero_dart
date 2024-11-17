import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/wallet/basic_models.dart';

/// Restores a wallet from a given wallet address, view key, and optional spend key.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#generate_from_keys
class WalletRequestGenerateFromKeys extends MoneroWalletRequestParam<
    WalletRPCGenerateFromKeysResponse, Map<String, dynamic>> {
  WalletRequestGenerateFromKeys(
      {this.restoreHeight,
      required this.fileName,
      required this.address,
      this.spendKey,
      required this.viewKey,
      required this.password,
      this.autosaveCurrent});

  /// The block height to restore the wallet from.
  final int? restoreHeight;

  /// The wallet's file name on the RPC server.
  final String fileName;

  /// The wallet's primary address.
  final MoneroAddress address;

  /// The wallet's private spend key.
  final String? spendKey;

  /// The wallet's private view key.
  final String viewKey;

  /// The wallet's password.
  final String password;

  /// If true, save the current wallet before generating the new
  final bool? autosaveCurrent;
  @override
  String get method => "generate_from_keys";
  @override
  Map<String, dynamic> get params => {
        "restore_height": restoreHeight,
        "autosave_current": autosaveCurrent,
        "filename": fileName,
        "address": address.address,
        "spendkey": spendKey,
        "viewkey": viewKey,
        "password": password
      };

  @override
  WalletRPCGenerateFromKeysResponse onResonse(Map<String, dynamic> result) {
    return WalletRPCGenerateFromKeysResponse.fromJson(result);
  }
}
