part of 'address.dart';

class MoneroIntegratedAddress extends MoneroAddress {
  final List<int> paymentId;
  MoneroIntegratedAddress._({
    required super.pubSpendKey,
    required super.pubViewKey,
    required super.address,
    required super.network,
    required List<int> paymentId,
  })  : paymentId = paymentId.asImmutableBytes,
        super._(type: XmrAddressType.integrated);

  factory MoneroIntegratedAddress(String address, {MoneroNetwork? network}) {
    final decode = XmrAddrDecoder().decode(address);
    if (decode.type != XmrAddressType.integrated) {
      throw const DartMoneroPluginException(
          "Use `MoneroAccountAddress` for creating a MoneroAccount address.");
    }
    final addrNetwork = MoneroNetwork.findNetwork(decode.type);
    if (network != null && addrNetwork != network) {
      throw DartMoneroPluginException("Invalid address network.", details: {
        "excepted": network.toString(),
        "type": addrNetwork.toString()
      });
    }
    return MoneroIntegratedAddress._(
        pubSpendKey: MoneroPublicKey.fromBytes(decode.publicSpendKey),
        pubViewKey: MoneroPublicKey.fromBytes(decode.publicViewKey),
        address: address,
        network: addrNetwork,
        paymentId: decode.paymentId!);
  }

  factory MoneroIntegratedAddress.fromPubKeys(
      {required List<int> pubSpendKey,
      required List<int> pubViewKey,
      required List<int> paymentId,
      MoneroNetwork network = MoneroNetwork.mainnet}) {
    paymentId = paymentId.asImmutableBytes;
    final psKey = MoneroPublicKey.fromBytes(pubSpendKey);
    final pvKey = MoneroPublicKey.fromBytes(pubViewKey);
    final encode = XmrAddrEncoder().encode(
        pubSpendKey: psKey.compressed,
        pubViewKey: pvKey.compressed,
        paymentId: paymentId,
        netVarBytes: network.findPrefix(XmrAddressType.integrated));
    return MoneroIntegratedAddress._(
        pubSpendKey: psKey,
        pubViewKey: pvKey,
        address: encode,
        network: network,
        paymentId: paymentId);
  }
}