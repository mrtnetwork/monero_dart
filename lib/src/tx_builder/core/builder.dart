part of 'package:monero_dart/src/tx_builder/tx_builder.dart';

class _MonerTxBuilderConst {
  static TxEpemeralKeyResult generateOutputFakeEpemeralKeys({
    required ED25519MoneroPrivateKey txSecretKey,
    required ED25519MoneroPublicKey txPublicKey,
    ED25519MoneroPrivateKey? changeAddressViewSecretKey,
    required MoneroAddress address,
    required int outIndex,
    MoneroAddress? changeAddr,
    ED25519MoneroPrivateKey? additionalSecretKey,
  }) {
    final fakePk = fakePubKey;
    final key = TxoutToTaggedKey(key: fakePk.toBytes(), viewTag: 12);
    return TxEpemeralKeyResult(
      txOut: key,
      amountKey: fakeScalar,
      additionalTxPubKey: additionalSecretKey == null ? null : fakePk,
    );
  }

  static const BuBytes fakeScalar = BuBytes.unsafe([
    217,
    248,
    239,
    166,
    21,
    112,
    173,
    84,
    251,
    236,
    216,
    211,
    54,
    75,
    152,
    97,
    1,
    120,
    150,
    129,
    61,
    38,
    241,
    241,
    35,
    105,
    92,
    123,
    47,
    16,
    5,
    13,
  ]);
  static ED25519MoneroPublicKey get fakePubKey =>
      ED25519MoneroPublicKey.fromBytes(
        BytesUtils.fromHexString(
          "5540ce412a435b535772cf0f8aa8686ae4bd948931304b401188171627d75a4c",
        ),
      );
}

abstract class MoneroTxBuilder<T extends SpendablePayment>
    extends MoneroSerialization {
  final ComputeSourceKeys sourceKeys;
  final ComputeDestinationKeys destinationKeys;
  final MoneroTransaction transaction;
  final List<MoneroTxDestination> destinations;
  final List<T> sources;
  final MoneroTxDestination? change;
  late final BigInt fee = sourceKeys.total - destinationKeys.total;
  BigInt get totalInput => sourceKeys.total;
  BigInt get totalOutput => destinationKeys.total;
  String get feeAsXMR => MoneroTransactionHelper.toXMR(fee);
  String get totalInputAsXMR => MoneroTransactionHelper.toXMR(totalInput);
  String get totalOutputAsXMR => MoneroTransactionHelper.toXMR(totalOutput);
  String get txId => transaction.getTxHash();
  MoneroTransaction getFinalTx();
  MoneroTxProof? generateProofVar({
    required MoneroAddress receiverAddress,
    String? message,
  }) {
    return MoneroTransactionHelper.generateOutProof(
      transaction: transaction,
      allTxKeys: destinationKeys.allTxKeys,
      receiverAddress: receiverAddress,
      message: message,
    );
  }

  MoneroTxProof? generateProof({
    required MoneroAddress receiverAddress,
    String? message,
  }) {
    return MoneroTransactionHelper.generateOutProof(
      transaction: transaction,
      allTxKeys: destinationKeys.allTxKeys,
      receiverAddress: receiverAddress,
      message: message,
    );
  }

  MoneroTxProof? generateInProof({
    required MoneroAccount account,
    required MoneroSubIndex index,
    String? message,
  }) {
    return MoneroTransactionHelper.generateInProof(
      transaction: transaction,
      message: message,
      account: account,
      index: index,
    );
  }

  MoneroTxProof? generateInProofVar({
    required MoneroAccount account,
    required MoneroSubIndex index,
    String? message,
  }) {
    return MoneroTransactionHelper.generateInProof(
      transaction: transaction,
      message: message,
      account: account,
      index: index,
    );
  }

  MoneroTxBuilder({
    required this.sourceKeys,
    required this.destinationKeys,
    required this.transaction,
    required this.destinations,
    required this.sources,
    required this.change,
  });

  BigInt weight() {
    final size = BigInt.from(transaction.serialize().length);
    final signature = transaction.signature.cast<RCTSignature>();
    final clawback = RCTGeneratorUtils.weightClawBack(signature);
    return size + BigInt.from(clawback);
  }

  static RctKey _createTxSecretKeySeed({
    required List<SpendablePayment<MoneroUnLockedPayment>> sources,
    String domain = "multisig_tx_privkeys_seed",
    required bool fakeTx,
  }) {
    if (fakeTx) return _MonerTxBuilderConst.fakeScalar;
    final entropy = RCT.skGen();
    final List<int> data = [
      ...domain.codeUnits,
      ...entropy,
      ...sources.map((e) => e.payment.keyImage).expand((e) => e.keyImage),
    ];
    return QuickCrypto.keccak256Hash(data).asImmutableBytes;
  }

  static List<ED25519MoneroPrivateKey> _makeTxSecretKeys({
    required RctKey seed,
    required int length,
    String domain = "multisig_tx_privkeys",
    required bool fakeTx,
  }) {
    if (fakeTx) {
      return List.filled(
        length,
        ED25519MoneroPrivateKey.fromBytes(_MonerTxBuilderConst.fakeScalar),
      );
    }
    final data = [seed, QuickCrypto.keccak256Hash(domain.codeUnits)];

    final List<ED25519MoneroPrivateKey> secretKeys = [];
    for (int i = 0; i < length; i++) {
      final hash = RCT.hashToScalarKeys(data);
      data[1] = hash;
      secretKeys.add(ED25519MoneroPrivateKey.fromBytes(hash));
    }
    return secretKeys.immutable;
  }

  static List<BigInt> absoluteOutputOffsetsToRelative(List<BigInt> off) {
    final List<BigInt> res = List.from(off);
    if (res.isEmpty) {
      return res;
    }
    res.sort();
    for (int i = res.length - 1; i > 0; i--) {
      res[i] -= res[i - 1];
    }

    return res;
  }

  static ComputeSourceKeys _computeSourceKeys({
    required List<SpendablePayment<MoneroUnLockedPayment>> sources,
  }) {
    final List<TxinToKey> inputs =
        sources.map((e) {
          final outs = e.outs.map((i) => i.index).toList();
          return TxinToKey(
            amount: e.payment.output.amount,
            keyOffsets: absoluteOutputOffsetsToRelative(outs),
            keyImage: e.payment.keyImage,
          );
        }).toList();
    final inputSecretKeys =
        sources.map((e) => e.payment.output.ephemeralSecretKey).toList();
    return ComputeSourceKeys._(
      inputSecretKeys: inputSecretKeys,
      inputs: inputs,
    );
  }

  static ComputeDestinationKeys _computeDestinationKeys({
    required MoneroBaseAccountKeys account,
    required List<MoneroTxDestination> destinations,
    required List<TxExtra> extraNonces,
    required ComputeSourceKeys sources,
    required BigInt fee,
    MoneroTxDestination? change,
    required RctKey txSeed,
    required bool fakeTx,
  }) {
    final List<MoneroTxDestination> currentDestinations = [
      ...destinations,
      if (change != null) change,
    ];
    if (currentDestinations.length == 1) {
      currentDestinations.add(
        MoneroTxDestination(
          amount: BigInt.zero,
          address: MoneroAccountAddress.fromPubKeys(
            pubSpendKey: RCT.pkGen(),
            pubViewKey: RCT.pkGen(),
          ),
        ),
      );
    }
    final addresses = currentDestinations.map((e) => e.address).toList();
    if (addresses.toSet().length != addresses.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid transaction: multiple outputs cannot be sent to the same address.",
      );
    }
    final BigInt inAmounts = sources.total;
    final BigInt outAmounts = currentDestinations.fold<BigInt>(
      BigInt.zero,
      (p, c) => p + c.amount,
    );
    if (inAmounts != outAmounts + fee) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Transaction validation failed: The sum of input amounts does not match the sum of output amounts plus the transaction fee. Ensure the inputs cover all outputs and the required fee.",
        details: {
          "inAmounts": inAmounts.toString(),
          "output_plus_fee": (outAmounts + fee).toString(),
          "remind": (inAmounts - (outAmounts + fee)).toString(),
        },
      );
    }

    final cl = TxDestinationInfo(
      destinations: currentDestinations,
      changeAddr: change?.address,
    );
    final txKeys = _makeTxSecretKeys(
      seed: txSeed,
      length: cl.needAdditionalTxkeys ? currentDestinations.length + 1 : 1,
      fakeTx: fakeTx,
    );
    final txKey = txKeys[0];
    final List<RctKey> amountKeys = [];
    final List<TxExtra> extras = [];
    final unknowDsts = currentDestinations.where(
      (e) => e.address != change?.address,
    );
    if (unknowDsts.length == 1) {
      final dst = unknowDsts.elementAt(0);
      List<int> paymentId = List<int>.filled(8, 0);
      if (!fakeTx) {
        if (dst.address.type == XmrAddressType.integrated) {
          paymentId = dst.address.cast<MoneroIntegratedAddress>().paymentId;
        }
        paymentId = MoneroTransactionHelper.encryptPaymentId(
          paymentId: paymentId,
          pubKey: unknowDsts.first.address.publicViewKey,
          secretKey: txKey,
        );
      }
      final extra = TxExtraNonce.encryptedPaymentId(paymentId);
      extras.add(extra);
    } else if (currentDestinations.any(
      (e) => e.address.type == XmrAddressType.integrated,
    )) {
      throw BuError(
        MoneroErrorType.crypto,
        "Integrated address detected in multi-transfer transaction.",
      );
    }
    final ED25519MoneroPublicKey txPubKey =
        fakeTx ? _MonerTxBuilderConst.fakePubKey : cl.getTxPubKey(txKey);

    final List<MoneroTxout> vouts = [];
    extras.add(TxExtraPublicKey(txPubKey.toBytes()));
    List<ED25519MoneroPrivateKey>? additionalTxSecretKeys;
    final List<ED25519MoneroPublicKey> additionalTxPubKey = [];
    if (cl.needAdditionalTxkeys) {
      additionalTxSecretKeys = txKeys.sublist(1);
    }
    for (int outIndex = 0; outIndex < currentDestinations.length; outIndex++) {
      final dest = currentDestinations[outIndex];
      TxEpemeralKeyResult key;
      if (fakeTx) {
        key = _MonerTxBuilderConst.generateOutputFakeEpemeralKeys(
          txSecretKey: txKey,
          address: dest.address,
          outIndex: outIndex,
          changeAddr: change?.address,
          changeAddressViewSecretKey: account.account.privateViewKey,
          txPublicKey: txPubKey,
          additionalSecretKey: additionalTxSecretKeys?[outIndex],
        );
      } else {
        key = MoneroTransactionHelper.generateOutputEpemeralKeys(
          txSecretKey: txKey,
          address: dest.address,
          outIndex: outIndex,
          changeAddr: change?.address,
          changeAddressViewSecretKey: account.account.privateViewKey,
          txPublicKey: txPubKey,
          additionalSecretKey: additionalTxSecretKeys?[outIndex],
        );
      }
      vouts.add(MoneroTxout(amount: dest.amount, target: key.txOut));
      amountKeys.add(key.amountKey);
      if (additionalTxSecretKeys != null) {
        additionalTxPubKey.add(key.additionalTxPubKey!);
      }
    }
    if (additionalTxPubKey.isNotEmpty) {
      extras.add(
        TxExtraAdditionalPubKeys(
          additionalTxPubKey.map((e) => e.toBytes()).toList(),
        ),
      );
    }
    return ComputeDestinationKeys(
      amountKeys: amountKeys,
      extras: [...extraNonces, ...extras],
      txPubKey: txPubKey,
      additionalTxPubKey: additionalTxPubKey,
      outs: vouts,
      allTxKeys: txKeys,
    );
  }

  static RCTSignature _buildSignature({
    required ComputeDestinationKeys destinationKeys,
    required ComputeSourceKeys sourceKeys,
    required List<SpendablePayment<MoneroUnLockedPayment>> sources,
    required BigInt fee,
    KeyV? aResult,
    bool isMultisig = false,
    bool fakeTx = false,
    bool fast = false,
  }) {
    final List<int> index = sources.map((e) => e.realOutIndex).toList();
    final CtKeyV inSk =
        sources.map((e) => e.payment.output.toSecretKey).toList();
    final List<ED25519MoneroPublicKey> destinationPubKeys =
        destinationKeys.destinationPubKeys;

    final CtKeyM mixRing = List.generate(sources.length, (i) {
      return List.generate(
        sources[i].outs.length,
        (n) => sources[i].outs[n].key,
      );
    });
    final List<BigInt> inamounts = sourceKeys.amounts;
    final List<BigInt> outamounts = destinationKeys.amounts;
    final BigInt fee = sourceKeys.total - destinationKeys.total;
    if (fee.isNegative) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid transaction fee $fee: destination amounts exceed source amounts.",
      );
    }
    final inputs = sourceKeys.toRctInputs;
    final outs = destinationKeys.toRctOuts;
    final extra = destinationKeys.toExtraBytes();
    final tx = MoneroTransactionPrefix(vin: inputs, vout: outs, extra: extra);
    final txHash =
        fakeTx ? _MonerTxBuilderConst.fakeScalar : tx.getTranactionPrefixHash();
    final CtKeyV outSk = List.generate(
      outs.length,
      (_) => CtKey(dest: RCT.zero(), mask: RCT.zero()),
    );
    if (fakeTx) {
      return RCTGeneratorUtils.genFakeRctSimple(
        message: txHash,
        inSk: inSk,
        destinations: destinationPubKeys.map((e) => e.toBytes()).toList(),
        inamounts: inamounts,
        outamounts: outamounts,
        txnFee: fee,
        mixRing: mixRing,
        amountKeys: destinationKeys.amountKeys,
        index: index,
        outSk: outSk,
        createLinkable: !isMultisig,
        aResult: aResult,
      );
    }
    if (fast) {
      return RCTGeneratorUtils.genRctSimple(
        message: txHash,
        inSk: inSk,
        destinations: destinationPubKeys.map((e) => e.toBytes()).toList(),
        inamounts: inamounts,
        outamounts: outamounts,
        txnFee: fee,
        mixRing: mixRing,
        amountKeys: destinationKeys.amountKeys,
        index: index,
        outSk: outSk,
        createLinkable: !isMultisig,
        aResult: aResult,
      );
    }
    return RCTGeneratorUtils.genRctSimple(
      message: txHash,
      inSk: inSk,
      destinations: destinationPubKeys.map((e) => e.toBytes()).toList(),
      inamounts: inamounts,
      outamounts: outamounts,
      txnFee: fee,
      mixRing: mixRing,
      amountKeys: destinationKeys.amountKeys,
      index: index,
      outSk: outSk,
      createLinkable: !isMultisig,
      aResult: aResult,
    );
  }

  static MoneroTransaction _buildTx({
    required ComputeDestinationKeys destinationKeys,
    required ComputeSourceKeys sourceKeys,
    required RCTSignature signature,
  }) {
    final extra = destinationKeys.toExtraBytes();
    return MoneroTransaction(
      vin: sourceKeys.toRctInputs,
      vout: destinationKeys.toRctOuts,
      extra: extra,
      signature: signature,
    );
  }
}
