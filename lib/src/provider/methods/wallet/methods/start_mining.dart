import 'package:monero_dart/src/provider/core/core.dart';

/// Start mining in the Monero daemon.
/// https://docs.getmonero.org/rpc-library/wallet-rpc/#start_mining
class WalletRequestStartMining
    extends MoneroWalletRequestParam<void, Map<String, dynamic>> {
  WalletRequestStartMining({
    required this.threadsCount,
    required this.doBackgroundMining,
    required this.ignoreBattery,
  });

  /// Number of threads created for mining
  final int threadsCount;

  /// Allow to start the miner in smart mining mode.
  final bool doBackgroundMining;

  /// Ignore battery status (for smart mining only)
  final bool ignoreBattery;

  @override
  String get method => "start_mining";
  @override
  Map<String, dynamic> get params => {
    "threads_count": threadsCount,
    "do_background_mining": doBackgroundMining,
    "ignore_battery": ignoreBattery,
  };

  @override
  void onResonse(Map<String, dynamic> result) {}
}
