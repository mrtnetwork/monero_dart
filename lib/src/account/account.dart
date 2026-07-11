import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/models/models.dart';
import 'package:monero_dart/src/crypto/crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/network/config.dart';
import 'package:monero_dart/src/network/network.dart';
import 'package:monero_dart/src/serialization/layout/layout.dart';

/// Represents a type of Monero account keys.
class MoneroAccountKeysType {
  final String name;
  final int value;
  const MoneroAccountKeysType._({required this.name, required this.value});
  static const MoneroAccountKeysType simple = MoneroAccountKeysType._(
    name: "Simple",
    value: 0,
  );
  static const MoneroAccountKeysType multisig = MoneroAccountKeysType._(
    name: "Multisig",
    value: 1,
  );
  static const List<MoneroAccountKeysType> values = [simple, multisig];
  static MoneroAccountKeysType fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse:
          () =>
              throw ItemNotFoundException(
                name: "MoneroAccountKeysType",
                value: name,
              ),
    );
  }

  bool get isMultisig => this == MoneroAccountKeysType.multisig;

  @override
  String toString() {
    return "MoneroAccountKeysType.$name";
  }
}

abstract class MoneroBaseAccountKeys extends MoneroVariantSerialization {
  /// account network
  final MoneroNetwork network;

  /// active subaddress indexes
  final List<MoneroSubIndex> indexes;

  /// type of account
  final MoneroAccountKeysType type;

  /// monero account
  final MoneroAccount account;
  final Map<MoneroSubIndex, MoneroPrivateKey> _cachedIndexSpendSecretKey = {};
  final Map<MoneroSubIndex, MoneroPublicKey> _cachedIndexSpendPubKey = {};
  MoneroBaseAccountKeys._({
    required this.network,
    required List<MoneroSubIndex> indexes,
    required this.type,
    required this.account,
  }) : indexes = indexes.toImutableList;

  factory MoneroBaseAccountKeys.deserialize(
    List<int> bytes, {
    String? property,
  }) {
    final decode = MoneroVariantSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroBaseAccountKeys.deserializeJson(decode);
  }

  factory MoneroBaseAccountKeys.deserializeJson(Map<String, dynamic> json) {
    final decode = MoneroVariantSerialization.toVariantDecodeResult(json);
    final type = MoneroAccountKeysType.fromName(decode.variantName);
    switch (type) {
      case MoneroAccountKeysType.multisig:
        return MoneroMultisigAccountKeys.deserializeJson(decode.value);
      case MoneroAccountKeysType.simple:
        return MoneroAccountKeys.deserializeJson(decode.value);
      default:
        throw const DartMoneroPluginException("Invalod account info type.");
    }
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.lazyEnum([
      LazyVariantModel(
        layout: MoneroAccountKeys.layout,
        property: MoneroAccountKeysType.simple.name,
        index: MoneroAccountKeysType.simple.value,
      ),
      LazyVariantModel(
        layout: MoneroMultisigAccountKeys.layout,
        property: MoneroAccountKeysType.multisig.name,
        index: MoneroAccountKeysType.multisig.value,
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createVariantLayout({String? property}) {
    return layout(property: property);
  }

  /// add subadress index
  MoneroBaseAccountKeys addIndex({int minor = 1, int major = 0}) {
    final index = MoneroSubIndex(major: major, minor: minor);
    if (indexes.contains(index)) {
      throw const DartMoneroPluginException("Cccount index already exist.");
    }
    return MoneroAccountKeys(
      account: account,
      indexes: [...indexes, index],
      network: network,
    );
  }

  /// get private spend key
  RctKey getPrivateSpendKey() {
    if (isWatchOnly) {
      throw const DartMoneroPluginException(
        "Watch only account does not have a private spend key",
      );
    }
    return account.privSkey!.key;
  }

  MoneroPrivateKey getSubAddressSpendPrivateKey(MoneroSubIndex index) {
    if (!indexes.contains(index)) {
      throw const DartMoneroPluginException("Index does not exists.");
    }
    _cachedIndexSpendSecretKey[index] ??=
        account.scubaddr.computeKeys(index.minor, index.major).privateKey;
    return _cachedIndexSpendSecretKey[index]!;
  }

  /// get spend public key
  MoneroPublicKey getSpendPublicKey(MoneroSubIndex index) {
    if (!indexes.contains(index)) {
      throw const DartMoneroPluginException("Index does not exists.");
    }
    if (!index.isSubaddress) {
      return account.pubSkey;
    }
    _cachedIndexSpendPubKey[index] ??=
        account.scubaddr.computeKeys(index.minor, index.major).pubSKey;
    return _cachedIndexSpendPubKey[index]!;
  }

  /// create integrated address with specify paymentId
  MoneroAddress integratedAddress({List<int>? paymentId}) {
    paymentId ??= QuickCrypto.generateRandom(
      MoneroNetworkConst.paymentIdLength,
    );
    return MoneroIntegratedAddress.fromPubKeys(
      pubSpendKey: account.pubSkey.key,
      pubViewKey: account.pubVkey.key,
      paymentId: paymentId,
      network: network,
    );
  }

  /// primary address
  MoneroAddress primaryAddress() {
    return MoneroAccountAddress.fromPubKeys(
      pubSpendKey: account.pubSkey.key,
      pubViewKey: account.pubVkey.key,
      network: network,
    );
  }

  /// remove index from account keys
  MoneroBaseAccountKeys removeIndex(MoneroSubIndex index) {
    final rIndex = indexes.remove(index);
    if (!rIndex) {
      throw const DartMoneroPluginException("Index does not exists.");
    }
    return MoneroAccountKeys(
      account: account,
      indexes: indexes,
      network: network,
    );
  }

  /// create subAddress with specify index
  /// index must be exists
  MoneroAddress subAddress(MoneroSubIndex index) {
    if (!index.isSubaddress) {
      throw const DartMoneroPluginException(
        "Use primary address for Non-subaddress index.",
      );
    }
    final keys = account.scubaddr.computeKeys(index.minor, index.major);
    return MoneroAccountAddress.fromPubKeys(
      pubSpendKey: keys.pubSKey.key,
      pubViewKey: keys.pubVKey.key,
      network: network,
      type: XmrAddressType.subaddress,
    );
  }

  MoneroAddress indexAddress(MoneroSubIndex index) {
    if (index.isSubaddress) {
      return subAddress(index);
    }
    return primaryAddress();
  }

  @override
  String get variantName => type.name;

  bool get isWatchOnly => account.isWatchOnly;

  @override
  String toString() {
    return indexes
        .map((e) {
          return {
            "type": type.name,
            ...e.toJson(),
            "address":
                e.isSubaddress
                    ? subAddress(e).address
                    : primaryAddress().address,
          };
        })
        .toList()
        .toString();
  }
}

class MoneroAccountKeys extends MoneroBaseAccountKeys {
  MoneroAccountKeys._({
    required super.account,
    required super.indexes,
    required super.network,
  }) : super._(type: MoneroAccountKeysType.simple);
  factory MoneroAccountKeys({
    required MoneroAccount account,
    List<MoneroSubIndex> indexes = const [
      MoneroSubIndex.primary,
      MoneroSubIndex.minor1,
    ],
    required MoneroNetwork network,
  }) {
    if (indexes.isEmpty) {
      throw const DartMoneroPluginException("Indexes must not be empty");
    }
    if (indexes.toSet().length != indexes.length) {
      throw const DartMoneroPluginException("Duplicate indexes find.");
    }
    return MoneroAccountKeys._(
      account: account,
      indexes: indexes,
      network: network,
    );
  }
  factory MoneroAccountKeys.deserializeJson(Map<String, dynamic> json) {
    final List<int>? privSkey = json.valueAsBytes("privSkey");
    final MoneroPrivateKey privVkey = MoneroPrivateKey.fromBytes(
      json.valueAsBytes("privVkey"),
    );
    final MoneroPublicKey pubSkey = MoneroPublicKey.fromBytes(
      json.valueAsBytes("pubSkey"),
    );
    MoneroAccount account;
    if (privSkey != null) {
      account = MoneroAccount.fromPrivateSpendKey(privSkey);
    } else {
      account = MoneroAccount.fromWatchOnly(privVkey.key, pubSkey.key);
    }
    if (account.privVkey != privVkey || account.pubSkey != pubSkey) {
      throw const DartMoneroPluginException("Account verification failed.");
    }
    return MoneroAccountKeys(
      account: account,
      indexes:
          json
              .valueEnsureAsList<Map<String, dynamic>>("indexes")
              .map((e) => MoneroSubIndex.deserializeJson(e))
              .toList(),
      network: MoneroNetwork.fromName(json.valueAs("network")),
    );
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantString(property: "network"),
      LayoutConst.optional(LayoutConst.fixedBlob32(), property: "privSkey"),
      LayoutConst.fixedBlob32(property: "privVkey"),
      LayoutConst.fixedBlob32(property: "pubSkey"),
      MoneroLayoutConst.variantVec(
        MoneroSubIndex.layout(),
        property: "indexes",
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "network": network.name,
      "privSkey": account.privSkey?.key,
      "privVkey": account.privVkey.key,
      "pubSkey": account.pubVkey.key,
      "indexes": indexes.map((e) => e.toLayoutStruct()).toList(),
    };
  }
}

class MoneroMultisigAccountKeys extends MoneroBaseAccountKeys {
  final MoneroMultisigAccount multisigAccount;
  MoneroMultisigAccountKeys._({
    required this.multisigAccount,
    required super.indexes,
    super.network = MoneroNetwork.mainnet,
  }) : super._(
         type: MoneroAccountKeysType.multisig,
         account: multisigAccount.toAccount(),
       );
  factory MoneroMultisigAccountKeys({
    required MoneroMultisigAccount multisigAccount,
    List<MoneroSubIndex> indexes = const [
      MoneroSubIndex.primary,
      MoneroSubIndex.minor1,
    ],
    MoneroNetwork network = MoneroNetwork.mainnet,
  }) {
    if (indexes.isEmpty) {
      throw const DartMoneroPluginException("Indexes must not be empty");
    }
    if (indexes.toSet().length != indexes.length) {
      throw const DartMoneroPluginException("Duplicate indexes find.");
    }
    return MoneroMultisigAccountKeys._(
      multisigAccount: multisigAccount,
      indexes: indexes,
      network: network,
    );
  }
  factory MoneroMultisigAccountKeys.deserializeJson(Map<String, dynamic> json) {
    return MoneroMultisigAccountKeys(
      multisigAccount: MoneroMultisigAccount.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("account"),
      ),
      indexes:
          json
              .valueEnsureAsList<Map<String, dynamic>>("indexes")
              .map((e) => MoneroSubIndex.deserializeJson(e))
              .toList(),
      network: MoneroNetwork.fromName(json.valueAs("network")),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantString(property: "network"),
      MoneroMultisigAccountCore.layout(property: "account"),
      MoneroLayoutConst.variantVec(
        MoneroSubIndex.layout(),
        property: "indexes",
      ),
    ], property: property);
  }

  @override
  RctKey getPrivateSpendKey() {
    final spendKey = RCT.zero();
    for (final i in multisigAccount.multisigPrivateKeys) {
      CryptoOps.scAdd(spendKey, i.key, spendKey);
    }
    return spendKey;
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "network": network.name,
      "account": multisigAccount.toLayoutStruct(),
      "indexes": indexes.map((e) => e.toLayoutStruct()).toList(),
    };
  }
}
