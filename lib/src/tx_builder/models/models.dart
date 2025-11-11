part of 'package:monero_dart/src/tx_builder/tx_builder.dart';

class ComputeDestinationKeys extends MoneroSerialization {
  final List<RctKey> amountKeys;
  final List<TxExtra> extras;
  final MoneroPublicKey txPubKey;
  final List<MoneroPublicKey> additionalTxPubKey;
  final List<MoneroPrivateKey> allTxKeys;
  final List<MoneroTxout> outs;
  List<MoneroPublicKey> get destinationPubKeys =>
      outs.map((e) => e.target.getPublicKey()!).toList();
  late final int destinationLength = outs.length;
  List<MoneroTxout> get toRctOuts =>
      outs.map((e) => e.copyWith(amount: BigInt.zero)).toList();
  List<BigInt> get amounts => outs.map((e) => e.amount).toList();
  final BigInt total;
  MoneroPrivateKey get txKey => allTxKeys[0];
  ComputeDestinationKeys(
      {required List<RctKey> amountKeys,
      required List<TxExtra> extras,
      required this.txPubKey,
      required List<MoneroPublicKey> additionalTxPubKey,
      required List<MoneroTxout> outs,
      required List<MoneroPrivateKey> allTxKeys})
      : total = outs.fold(BigInt.zero, (p, c) => p + c.amount),
        amountKeys = amountKeys.map((e) => e.asImmutableBytes).toImutableList,
        extras = extras.immutable,
        additionalTxPubKey = additionalTxPubKey.immutable,
        allTxKeys = allTxKeys.toImutableList,
        outs = outs.immutable;
  factory ComputeDestinationKeys.fromStruct(Map<String, dynamic> json) {
    return ComputeDestinationKeys(
        additionalTxPubKey: json
            .asListBytes("additionalTxPubKey")!
            .map((e) => MoneroPublicKey.fromBytes(e))
            .toList(),
        allTxKeys: json
            .asListBytes("allTxKeys")!
            .map((e) => MoneroPrivateKey.fromBytes(e))
            .toList(),
        amountKeys: json.asListBytes("amountKeys")!,
        extras: json
            .asListOfMap("extras")!
            .map((e) => TxExtra.fromStruct(e))
            .toList(),
        outs: json
            .asListOfMap("outs")!
            .map((e) => MoneroTxout.fromStruct(e))
            .toList(),
        txPubKey: MoneroPublicKey.fromBytes(json.asBytes("txPubKey")));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "amountKeys"),
      MoneroLayoutConst.variantVec(TxExtra.layout(), property: "extras"),
      LayoutConst.fixedBlob32(property: "txPubKey"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "additionalTxPubKey"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "allTxKeys"),
      MoneroLayoutConst.variantVec(MoneroTxout.layout(), property: "outs"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "amountKeys": amountKeys,
      "extras": extras.map((e) => e.toVariantLayoutStruct()).toList(),
      "txPubKey": txPubKey.key,
      "additionalTxPubKey": additionalTxPubKey.map((e) => e.key).toList(),
      "allTxKeys": allTxKeys.map((e) => e.key).toList(),
      "outs": outs.map((e) => e.toLayoutStruct()).toList()
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  List<int> toExtraBytes() {
    return MoneroTransactionHelper.toTxExtra(extras);
  }
}

class ComputeSourceKeys extends MoneroSerialization {
  final KeyV inputSecretKeys;
  final List<TxinToKey> inputs;
  final BigInt total;
  List<BigInt> get amounts => inputs.map((e) => e.amount).toList();
  List<TxinToKey> get toRctInputs =>
      inputs.map((e) => e.copyWith(amount: BigInt.zero)).toList();
  late final int sourcesLength = inputs.length;

  ComputeSourceKeys._({
    required KeyV inputSecretKeys,
    required List<TxinToKey> inputs,
  })  : total =
            inputs.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount).asUint64,
        inputSecretKeys = inputSecretKeys
            .map((e) => e.asImmutableBytes.exc(32))
            .toImutableList,
        inputs = inputs.immutable;
  factory ComputeSourceKeys.fromStruct(Map<String, dynamic> json) {
    return ComputeSourceKeys._(
      inputSecretKeys: json.asListBytes("inputSecretKeys")!,
      inputs: json
          .asListOfMap("inputs")!
          .map((e) => TxinToKey.fromStruct(e))
          .toList(),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "inputSecretKeys"),
      MoneroLayoutConst.variantVec(TxinToKey.layout(), property: "inputs"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "inputSecretKeys": inputSecretKeys,
      "inputs": inputs.map((e) => e.toLayoutStruct()).toList(),
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class MoneroMultisigSignedInfo extends MoneroSerialization {
  final KeyM l;
  final List<MoneroPublicKey> signingKeys;
  final KeyM totalAlphaG;
  final KeyM totalAlphaH;
  final KeyV c0;
  final KeyV s;

  factory MoneroMultisigSignedInfo.initial(
      {required List<MoneroPublicKey> signingKeys, required int sourceLength}) {
    final KeyM totalAlphaG = List.generate(
        sourceLength,
        (i) => List.generate(
            MoneroMultisigTxBuilder.kAlphaComponents, (_) => RCT.zero()));
    final KeyM totalAlphaH = List.generate(
        sourceLength,
        (i) => List.generate(
            MoneroMultisigTxBuilder.kAlphaComponents, (_) => RCT.zero()));
    final KeyV s = List.generate(sourceLength, (_) => RCT.zero());
    final KeyV c0 = List.generate(sourceLength, (_) => RCT.zero());
    return MoneroMultisigSignedInfo(
        l: List.generate(sourceLength, (_) => []),
        signingKeys: signingKeys,
        totalAlphaG: totalAlphaG,
        totalAlphaH: totalAlphaH,
        c0: c0,
        s: s);
  }

  MoneroMultisigSignedInfo(
      {required this.l,
      required this.signingKeys,
      required KeyM totalAlphaG,
      required KeyM totalAlphaH,
      required KeyV c0,
      required KeyV s})
      : totalAlphaG = totalAlphaG.toImutableList,
        totalAlphaH = totalAlphaH.toImutableList,
        c0 = c0.toImutableList,
        s = s.toImutableList;
  factory MoneroMultisigSignedInfo.fromStruct(Map<String, dynamic> json) {
    return MoneroMultisigSignedInfo(
        l: json.asListOfListBytes("l")!,
        signingKeys: json
            .asListBytes("signingKeys")!
            .map((e) => MoneroPublicKey.fromBytes(e))
            .toList(),
        totalAlphaG: json.asListOfListBytes("totalAlphaG")!,
        totalAlphaH: json.asListOfListBytes("totalAlphaH")!,
        c0: json.asListBytes("c0")!,
        s: json.asListBytes("s")!);
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(
          MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32()),
          property: "l"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "signingKeys"),
      MoneroLayoutConst.variantVec(
          MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32()),
          property: "totalAlphaG"),
      MoneroLayoutConst.variantVec(
          MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32()),
          property: "totalAlphaH"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "c0"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "s"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "l": l,
      "signingKeys": signingKeys.map((e) => e.key).toList(),
      "totalAlphaG": totalAlphaG,
      "totalAlphaH": totalAlphaH,
      "c0": c0,
      "s": s
    };
  }
}

class MultisigSignatureResponse {
  final List<CLSAGContext> context;
  final KeyV wCached;
  final RCTSignature signature;
  const MultisigSignatureResponse(
      {required this.context, required this.wCached, required this.signature});
}

class TxDestinationInfo {
  final int stdAddressesCount;
  final int subAddressesCount;
  final MoneroAddress? singleDestionation;
  MoneroPublicKey getTxPubKey(MoneroPrivateKey txSecretKey) {
    RctKey txPubKey;

    if (singleDestionation != null) {
      txPubKey =
          RCT.scalarmultKey(singleDestionation!.pubSpendKey, txSecretKey.key);
    } else {
      txPubKey = RCT.scalarmultBase(txSecretKey.key);
    }
    return MoneroPublicKey.fromBytes(txPubKey);
  }

  bool get needAdditionalTxkeys =>
      subAddressesCount > 0 && (stdAddressesCount > 0 || subAddressesCount > 1);

  const TxDestinationInfo._(
      {required this.stdAddressesCount,
      required this.subAddressesCount,
      required this.singleDestionation});

  factory TxDestinationInfo(
      {required List<MoneroTxDestination> destinations,
      required MoneroAddress? changeAddr}) {
    int stdaddresses = 0;
    int subaddresses = 0;
    MoneroAddress? singleSubaddress;
    final List<MoneroAddress> destAddresses = [];
    for (final i in destinations) {
      if (changeAddr != null && i.address == changeAddr) {
        continue;
      }
      if (!destAddresses.contains(i.address)) {
        destAddresses.add(i.address);
        if (i.address.type == XmrAddressType.subaddress) {
          ++subaddresses;
          singleSubaddress = i.address;
        } else {
          ++stdaddresses;
        }
      }
    }
    return TxDestinationInfo._(
        stdAddressesCount: stdaddresses,
        subAddressesCount: subaddresses,
        singleDestionation:
            stdaddresses == 0 && subaddresses == 1 ? singleSubaddress : null);
  }
}
