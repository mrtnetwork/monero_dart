import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/network/network.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/serialization/serialization.dart';
part 'integrated_address.dart';
part 'account_address.dart';

abstract class MoneroAddress extends MoneroSerialization {
  /// view public key
  final MoneroPublicKey pubViewKey;

  /// spend public key
  final MoneroPublicKey pubSpendKey;

  /// address
  final String address;

  /// network of address
  final MoneroNetwork network;

  /// address type
  final XmrAddressType type;

  /// quick check account type.
  bool get isSubaddress => type == XmrAddressType.subaddress;
  bool get isStdAddress => type != XmrAddressType.subaddress;
  bool get isIntegratedAddress => type == XmrAddressType.integrated;

  const MoneroAddress._(
      {required this.pubSpendKey,
      required this.pubViewKey,
      required this.address,
      required this.network,
      required this.type});

  factory MoneroAddress.fromStruct(Map<String, dynamic> json) {
    return MoneroAddress(json.as("address"));
  }
  factory MoneroAddress(String address,
      {MoneroNetwork? network, XmrAddressType? type}) {
    final decode = XmrAddrDecoder().decode(address);
    if (type != null && decode.type != type) {
      throw DartMoneroPluginException("Invalid address type.", details: {
        "excepted": type.toString(),
        "type": decode.type.toString()
      });
    }
    final psKey = MoneroPublicKey.fromBytes(decode.publicSpendKey);
    final pvKey = MoneroPublicKey.fromBytes(decode.publicViewKey);
    final addrNetwork = MoneroNetwork.findNetwork(decode.type);
    if (network != null && addrNetwork != network) {
      throw DartMoneroPluginException("Invalid address network.", details: {
        "excepted": network.toString(),
        "type": addrNetwork.toString()
      });
    }
    switch (decode.type) {
      case XmrAddressType.integrated:
        return MoneroIntegratedAddress._(
            pubSpendKey: psKey,
            pubViewKey: pvKey,
            address: address,
            network: addrNetwork,
            paymentId: decode.paymentId!);
      case XmrAddressType.primaryAddress:
      case XmrAddressType.subaddress:
        return MoneroAccountAddress._(
            pubSpendKey: psKey,
            pubViewKey: pvKey,
            address: address,
            network: addrNetwork,
            type: decode.type);
      default:
        throw DartMoneroPluginException("Invalid monero address type.",
            details: {"type": decode.type.toString()});
    }
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct(
        [MoneroLayoutConst.variantString(property: "address")],
        property: property);
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
      throw DartMoneroPluginException("monero address casting failed.",
          details: {"excepted": "$T", "type": type.name});
    }
    return this as T;
  }

  @override
  operator ==(other) {
    if (other is! MoneroAddress) return false;
    return address == other.address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return address;
  }
}
