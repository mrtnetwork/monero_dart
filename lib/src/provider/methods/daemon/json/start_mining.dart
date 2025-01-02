import 'package:monero_dart/src/provider/core/core.dart';
import 'package:monero_dart/src/provider/models/daemon/basic_models.dart';

/// Start mining on the daemon.
/// https://www.getmonero.org/resources/developer-guides/daemon-rpc.html#start_mining
class DaemonRequestStartMining
    extends MoneroDaemonRequestParam<DaemonBaseResponse, Map<String, dynamic>> {
  const DaemonRequestStartMining(
      {required this.doBackgroundMining,
      required this.ignoreBattery,
      required this.minerAddress,
      required this.threadsCount});

  /// Account address to mine to.
  final String minerAddress;

  /// Number of mining thread to run.
  final BigInt threadsCount;

  /// States if the mining should run in background
  final bool doBackgroundMining;

  /// States if battery state (on laptop) should be ignored
  final bool ignoreBattery;
  @override
  String get method => "start_mining";
  @override
  Map<String, dynamic> get params => {
        "threads_count": threadsCount.toString(),
        "miner_address": minerAddress,
        "do_background_mining": doBackgroundMining,
        "ignore_battery": ignoreBattery
      };
  @override
  DemonRequestType get encodingType => DemonRequestType.json;

  @override
  DaemonBaseResponse onResonse(Map<String, dynamic> result) {
    return DaemonBaseResponse.fromJson(result);
  }
}
