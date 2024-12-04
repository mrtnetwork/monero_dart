import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';

class MoneroNetwork {
  /// network name
  final String name;

  /// network address configration.
  final CoinConf config;

  /// network address prefixes.
  List<int> get _prefixes => [
        ...config.params.addrNetVer!,
        ...config.params.addrIntNetVer!,
        ...config.params.subaddrNetVer!,
      ];
  const MoneroNetwork._({required this.name, required this.config});

  /// mainnet
  static const MoneroNetwork mainnet =
      MoneroNetwork._(name: "Mainnet", config: CoinsConf.moneroMainNet);

  /// testnet
  static const MoneroNetwork testnet =
      MoneroNetwork._(name: "Testnet", config: CoinsConf.moneroTestNet);

  /// stagenet
  static const MoneroNetwork stagenet =
      MoneroNetwork._(name: "Stagenet", config: CoinsConf.moneroStageNet);

  static const List<MoneroNetwork> values = [mainnet, testnet, stagenet];

  /// find monero network from name.
  static MoneroNetwork fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw DartMoneroPluginException(
            "The provided network name does not exist.",
            details: {"name": name}));
  }

  /// find network from address type prefix bytes.
  static MoneroNetwork fromNetVersion(int netVersion) {
    for (final n in values) {
      if (n._prefixes.contains(netVersion)) {
        return n;
      }
    }
    throw const DartMoneroPluginException(
        "Invalid prefix: no related network found for the provided prefix.");
  }

  /// detect address prefix bytes from type.
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

  /// quick method to get coin from network.
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
    return "MoneroNetwork.$name";
  }
}
