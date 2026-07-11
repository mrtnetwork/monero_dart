import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/network/network.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/serialization.dart';
part 'integrated_address.dart';
part 'account_address.dart';

abstract class MoneroAddress extends MoneroSerialization
    with Equality, CborTagSerializable
    implements IAddress {
  final List<int> pubViewKey;
  final List<int> pubSpendKey;

  /// view public key
  late final MoneroPublicKey publicViewKey = MoneroPublicKey.fromBytes(
    pubViewKey,
  );

  late final MoneroPublicKey publicSpendKey = MoneroPublicKey.fromBytes(
    pubSpendKey,
  );

  /// address
  @override
  final String address;

  /// network of address
  final MoneroNetwork network;

  /// address type
  final XmrAddressType type;

  /// quick check account type.
  bool get isSubaddress => type == XmrAddressType.subaddress;
  bool get isStdAddress => type != XmrAddressType.subaddress;
  bool get isIntegratedAddress => type == XmrAddressType.integrated;

  MoneroAddress._({
    required List<int> pubSpendKey,
    required List<int> pubViewKey,
    required this.address,
    required this.network,
    required this.type,
  }) : pubViewKey = pubViewKey.asImmutableBytes,
       pubSpendKey = pubSpendKey.asImmutableBytes;

  factory MoneroAddress.deserializeJson(Map<String, dynamic> json) {
    return MoneroAddress(json.valueAs("address"));
  }
  factory MoneroAddress.deserializeIAddress({
    List<int>? bytes,
    CborObject? object,
  }) {
    final values = CborTagSerializable.decodeTaggedValue(
      identifier: BlockchainNetwork.monero.identifier,
      cborBytes: bytes,
      cborObject: object,
    );
    final type = XmrAddressType.fromValue(values.rawValueAt(0));
    return switch (type) {
      XmrAddressType.primaryAddress ||
      XmrAddressType.subaddress => MoneroAccountAddress.fromPubKeys(
        pubSpendKey: values.rawValueAt(1),
        pubViewKey: values.rawValueAt(2),
        network: MoneroNetwork.fromValue(values.rawValueAt(3)),
        type: type,
      ),
      XmrAddressType.integrated => MoneroIntegratedAddress.fromPubKeys(
        pubSpendKey: values.rawValueAt(1),
        pubViewKey: values.rawValueAt(2),
        paymentId: values.rawValueAt(3),
        network: MoneroNetwork.fromValue(values.rawValueAt(4)),
      ),
    };
  }

  factory MoneroAddress(
    String address, {
    MoneroNetwork? network,
    XmrAddressType? type,
  }) {
    final decode = XmrAddrDecoder().decode(address);
    if (type != null && decode.type != type) {
      throw DartMoneroPluginException(
        "Invalid address type.",
        details: {"expected": type.toString(), "type": decode.type.toString()},
      );
    }
    final psKey = decode.publicSpendKey;
    final pvKey = decode.publicViewKey;
    final addrNetwork = MoneroNetwork.fromNetVersion(decode.netVersion);
    if (network != null && addrNetwork != network) {
      throw DartMoneroPluginException(
        "Invalid address network.",
        details: {
          "expected": network.toString(),
          "type": addrNetwork.toString(),
        },
      );
    }
    switch (decode.type) {
      case XmrAddressType.integrated:
        return MoneroIntegratedAddress._(
          pubSpendKey: psKey,
          pubViewKey: pvKey,
          address: address,
          network: addrNetwork,
          paymentId: decode.paymentId!,
        );
      case XmrAddressType.primaryAddress:
      case XmrAddressType.subaddress:
        return MoneroAccountAddress._(
          pubSpendKey: psKey,
          pubViewKey: pvKey,
          address: address,
          network: addrNetwork,
          type: decode.type,
        );
    }
  }

  MoneroAddress toNetwork(MoneroNetwork network);

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantString(property: "address"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"address": address};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  T cast<T extends MoneroAddress>() {
    if (this is! T) {
      throw DartMoneroPluginException(
        "monero address casting failed.",
        details: {"expected": "$T", "type": type.name},
      );
    }
    return this as T;
  }

  @override
  List<dynamic> get variables => [address];

  @override
  List<int> encodeAsIAddress() {
    return toCbor().encode();
  }

  @override
  BlockchainNetwork get blockchainNetwork => BlockchainNetwork.monero;

  @override
  SerializationIdentifier get serializationIdentifier =>
      blockchainNetwork.identifier;

  @override
  String toString() {
    return address;
  }

  @override
  String get viewType => type.name;
}
