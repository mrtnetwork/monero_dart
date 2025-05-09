part of 'address.dart';

class MoneroAccountAddress extends MoneroAddress {
  MoneroAccountAddress._(
      {required super.pubSpendKey,
      required super.pubViewKey,
      required super.address,
      required super.network,
      required super.type})
      : super._();

  factory MoneroAccountAddress(String address,
      {MoneroNetwork? network, XmrAddressType? type}) {
    final decode = XmrAddrDecoder().decode(address);
    if (decode.type == XmrAddressType.integrated) {
      throw const DartMoneroPluginException(
          "Use `MoneroIntegratedAddress` for creating a MoneroAccount address.");
    }
    if (type != null && decode.type != type) {
      throw DartMoneroPluginException("Invalid address type.", details: {
        "expected": type.toString(),
        "type": decode.type.toString()
      });
    }
    final addrNetwork = MoneroNetwork.fromNetVersion(decode.netVersion);
    if (network != null && addrNetwork != network) {
      throw DartMoneroPluginException("Invalid address network.", details: {
        "expected": network.toString(),
        "type": addrNetwork.toString()
      });
    }
    return MoneroAccountAddress._(
        pubSpendKey: decode.publicSpendKey,
        pubViewKey: decode.publicViewKey,
        address: address,
        network: addrNetwork,
        type: decode.type);
  }

  factory MoneroAccountAddress.fromPubKeys({
    required List<int> pubSpendKey,
    required List<int> pubViewKey,
    MoneroNetwork network = MoneroNetwork.mainnet,
    XmrAddressType type = XmrAddressType.primaryAddress,
  }) {
    if (type == XmrAddressType.integrated) {
      throw const DartMoneroPluginException(
          "Use `MoneroIntegratedAddress` for creating a MoneroAccount address.");
    }
    final encode = XmrAddrEncoder().encode(
        pubSpendKey: pubSpendKey,
        pubViewKey: pubViewKey,
        netVarBytes: network.findPrefix(type));
    return MoneroAccountAddress._(
        pubSpendKey: pubSpendKey,
        pubViewKey: pubViewKey,
        address: encode,
        network: network,
        type: type);
  }
  bool get isSubAddress => type == XmrAddressType.subaddress;
}
