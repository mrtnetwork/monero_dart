import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/bip/coin_conf/coin_conf.dart';
import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/bip/monero/conf/monero_coins.dart';
import 'package:monero_dart/src/exception/exception.dart';

class MoneroNetwork {
  final String name;
  final CoinConf config;
  List<int> get prefixes => [
        ...config.params.addrNetVer!,
        ...config.params.addrIntNetVer!,
        ...config.params.subaddrNetVer!,
      ];
  const MoneroNetwork._({required this.name, required this.config});
  static const MoneroNetwork mainnet = MoneroNetwork._(
    name: "Mainnet",
    config: CoinsConf.moneroMainNet,
  );
  static const MoneroNetwork testnet = MoneroNetwork._(
    name: "Testnet",
    config: CoinsConf.moneroTestNet,
  );
  static const MoneroNetwork stagenet = MoneroNetwork._(
    name: "Stagenet",
    config: CoinsConf.moneroStageNet,
  );
  static const List<MoneroNetwork> values = [mainnet, testnet, stagenet];
  static MoneroNetwork fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException(
            "The provided network name does not exist.",
            details: {"name": name}));
  }

  static MoneroNetwork findNetwork(XmrAddressType type) {
    for (final i in type.prefixes) {
      for (final n in values) {
        if (n.prefixes.contains(i)) {
          return n;
        }
      }
    }
    throw const DartMoneroPluginException(
        "Invalid prefix: no related network found for the provided prefix.");
  }

  List<int> findPrefix(XmrAddressType type) {
    switch (type) {
      case XmrAddressType.integrated:
        return config.params.addrIntNetVer!;
      case XmrAddressType.primaryAddress:
        return config.params.addrNetVer!;
      case XmrAddressType.subaddress:
        return config.params.subaddrNetVer!;
      default:
        throw DartMoneroPluginException("Invalid monero address type.",
            details: {"type": type.toString()});
    }
  }

  MoneroCoins get coin {
    switch (this) {
      case MoneroNetwork.mainnet:
        return MoneroCoins.moneroMainnet;
      case MoneroNetwork.testnet:
        return MoneroCoins.moneroTestnet;
      case MoneroNetwork.stagenet:
        return MoneroCoins.moneroStagenet;
      default:
        throw DartMoneroPluginException("Invalid monero network.",
            details: {"network": name});
    }
  }

  @override
  String toString() {
    return "MoneroNetwork.$stagenet";
  }
}
