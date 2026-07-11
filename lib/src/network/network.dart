import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';

enum MoneroNetwork {
  /// mainnet
  mainnet(value: 0, name: "Mainnet", config: CoinsConf.moneroMainNet),

  /// testnet
  testnet(value: 1, name: "Testnet", config: CoinsConf.moneroTestNet),

  /// stagenet
  stagenet(value: 2, name: "Stagenet", config: CoinsConf.moneroStageNet);

  /// network name
  final String name;

  /// network address configration.
  final CoinConf config;

  final int value;

  /// network address prefixes.
  List<int> get prefixes => [
    ...?config.params.addrNetVer,
    ...?config.params.addrIntNetVer,
    ...?config.params.subaddrNetVer,
  ];
  const MoneroNetwork({
    required this.name,
    required this.config,
    required this.value,
  });

  /// find monero network from name.
  static MoneroNetwork fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () => throw ItemNotFoundException(name: "MoneroNetwork", value: name),
    );
  }

  /// find monero network from index.
  static MoneroNetwork fromValue(int? index) {
    return values.firstWhere(
      (e) => e.index == index,
      orElse: () => throw ItemNotFoundException(name: "MoneroNetwork"),
    );
  }

  /// find network from address type prefix bytes.
  static MoneroNetwork fromNetVersion(int netVersion) {
    for (final n in values) {
      if (n.prefixes.contains(netVersion)) {
        return n;
      }
    }
    throw const DartMoneroPluginException(
      "Invalid prefix: no related network found for the provided prefix.",
    );
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
    }
  }

  @override
  String toString() {
    return "MoneroNetwork.$name";
  }
}
