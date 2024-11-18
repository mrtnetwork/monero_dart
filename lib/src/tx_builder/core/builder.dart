part of 'package:monero_dart/src/tx_builder/tx_builder.dart';

abstract class MoneroTxBuilder<T extends SpendablePayment>
    extends MoneroSerialization {
  final ComputeSourceKeys sourceKeys;
  final ComputeDestinationKeys destinationKeys;
  final MoneroTransaction transaction;
  final List<TxDestination> destinations;
  final List<T> sources;
  final TxDestination? change;
  late final BigInt fee = sourceKeys.total - destinationKeys.total;
  BigInt get totalInput => sourceKeys.total;
  BigInt get totalOutput => sourceKeys.total;
  String get feeAsXMR => MoneroTransactionHelper.toXMR(fee);
  String get totalInputAsXMR => MoneroTransactionHelper.toXMR(totalInput);
  String get totalOutputAsXMR => MoneroTransactionHelper.toXMR(totalOutput);
  String get txId => transaction.getTxHash();
  MoneroTransaction getFinalTx();
  MoneroTxProof generateProof(
      {required MoneroAddress receiverAddress, required String? message}) {
    return MoneroTransactionHelper.generateOutProof(
        transaction: transaction,
        allTxKeys: destinationKeys.allTxKeys,
        receiverAddress: receiverAddress,
        message: message ?? '');
  }

  MoneroTxBuilder(
      {required this.sourceKeys,
      required this.destinationKeys,
      required this.transaction,
      required this.destinations,
      required this.sources,
      required this.change});

  BigInt weight() {
    final size = BigInt.from(transaction.serialize().length);
    final signature = transaction.signature.cast<RCTSignature>();
    final clawback = RCTGeneratorUtils.weightClawBack(signature);
    return size + BigInt.from(clawback);
  }

  static RctKey _createTxSecretKeySeed({
    required RctKey entropy,
    required List<SpendablePayment> sources,
    String domain = "multisig_tx_privkeys_seed",
  }) {
    final List<int> data = [
      ...domain.codeUnits,
      ...entropy,
      ...sources.map((e) => e.payment.keyImage).expand((e) => e)
    ];
    return QuickCrypto.keccack256Hash(data).asImmutableBytes;
  }

  static List<MoneroPrivateKey> _makeTxSecretKeys(
      {required RctKey seed,
      required int length,
      String domain = "multisig_tx_privkeys"}) {
    final data = [seed, QuickCrypto.keccack256Hash(domain.codeUnits)];

    final List<MoneroPrivateKey> secretKeys = [];
    for (int i = 0; i < length; i++) {
      final hash = RCT.hashToScalarKeys(data);
      data[1] = hash;
      secretKeys.add(MoneroPrivateKey.fromBytes(hash));
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

  static ComputeSourceKeys _computeSourceKeys(
      {required List<SpendablePayment> sources}) {
    final List<TxinToKey> inputs = sources.map((e) {
      return TxinToKey(
          amount: e.payment.output.amount,
          keyOffsets: absoluteOutputOffsetsToRelative(
              e.outs.map((i) => i.index).toList()),
          keyImage: e.payment.keyImage);
    }).toList();
    final inputSecretKeys =
        sources.map((e) => e.payment.output.ephemeralSecretKey).toList();
    return ComputeSourceKeys._(
        inputSecretKeys: inputSecretKeys, inputs: inputs);
  }

  static ComputeDestinationKeys _computeDestinationKeys(
      {required MoneroBaseAccountKeys account,
      required List<TxDestination> destinations,
      required ComputeSourceKeys sources,
      required BigInt fee,
      TxDestination? change,
      required RctKey txSeed}) {
    final List<TxDestination> currentDestinations = [
      ...destinations,
      if (change != null) change
    ];
    final addresses = currentDestinations.map((e) => e.address).toList();
    if (addresses.toSet().length != addresses.length) {
      throw const DartMoneroPluginException(
          "Invalid transaction: multiple outputs cannot be sent to the same address.");
    }
    final BigInt inAmounts = sources.total;
    final BigInt outAmounts =
        currentDestinations.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount);
    if (inAmounts != outAmounts + fee) {
      throw const DartMoneroPluginException(
          "Transaction validation failed: The sum of input amounts does not match the sum of output amounts plus the transaction fee. Ensure the inputs cover all outputs and the required fee.");
    }

    final cl = TxDestinationInfo(
        destinations: currentDestinations, changeAddr: change?.address);
    final txKeys = _makeTxSecretKeys(
        seed: txSeed,
        length: cl.needAdditionalTxkeys ? currentDestinations.length + 1 : 1);
    final txKey = txKeys[0];
    final List<RctKey> amountKeys = [];
    final List<TxExtra> extras = [];
    final unknowDsts =
        currentDestinations.where((e) => e.address != change?.address);
    if (unknowDsts.length == 1) {
      final dst = unknowDsts.elementAt(0);
      List<int> paymentId = List<int>.filled(8, 0);
      if (dst.address.type == XmrAddressType.integrated) {
        paymentId = dst.address.cast<MoneroIntegratedAddress>().paymentId;
      }
      paymentId = MoneroTransactionHelper.encryptPaymentId(
          paymentId: paymentId,
          pubKey: unknowDsts.first.address.pubViewKey,
          secretKey: txKey);
      final extra = TxExtraNonce.encryptedPaymentId(paymentId);
      extras.add(extra);
    } else if (currentDestinations
        .any((e) => e.address.type == XmrAddressType.integrated)) {
      throw const MoneroCryptoException(
          "Integrated address detected in multi-transfer transaction.");
    }
    final MoneroPublicKey txPubKey = cl.getTxPubKey(txKey);

    final List<MoneroTxout> vouts = [];
    extras.add(TxExtraPublicKey(txPubKey));
    List<MoneroPrivateKey>? additionalTxSecretKeys;
    final List<MoneroPublicKey> additionalTxPubKey = [];
    if (cl.needAdditionalTxkeys) {
      additionalTxSecretKeys = txKeys.sublist(1);
    }
    for (int outIndex = 0; outIndex < currentDestinations.length; outIndex++) {
      final dest = currentDestinations[outIndex];
      final key = MoneroTransactionHelper.generateOutputEpemeralKeys(
        txSecretKey: txKey,
        address: dest.address,
        outIndex: outIndex,
        changeAddr: change?.address,
        changeAddressViewSecretKey: account.account.privateViewKey,
        txPublicKey: txPubKey,
        additionalSecretKey: additionalTxSecretKeys?[outIndex],
      );
      vouts.add(MoneroTxout(amount: dest.amount, target: key.txOut));
      amountKeys.add(key.amountKey);
      if (additionalTxSecretKeys != null) {
        additionalTxPubKey.add(key.additionalTxPubKey!);
      }
    }
    if (additionalTxPubKey.isNotEmpty) {
      extras.add(TxExtraAdditionalPubKeys(additionalTxPubKey));
    }
    return ComputeDestinationKeys(
        amountKeys: amountKeys,
        extras: extras,
        txPubKey: txPubKey,
        additionalTxPubKey: additionalTxPubKey,
        outs: vouts,
        allTxKeys: txKeys);
  }

  static RCTSignature _buildSignature(
      {required ComputeDestinationKeys destinationKeys,
      required ComputeSourceKeys sourceKeys,
      required List<SpendablePayment> sources,
      required BigInt fee,
      KeyV? aResult,
      bool isMultisig = false,
      bool fakeSignature = false}) {
    final List<int> index = sources.map((e) => e.realOutIndex).toList();
    final CtKeyV inSk =
        sources.map((e) => e.payment.output.toSecretKey).toList();
    final List<MoneroPublicKey> destinationPubKeys =
        destinationKeys.destinationPubKeys;

    final CtKeyM mixRing = List.generate(sources.length, (i) {
      return List.generate(
          sources[i].outs.length, (n) => sources[i].outs[n].key);
    });
    final List<BigInt> inamounts = sourceKeys.amounts;
    final List<BigInt> outamounts = destinationKeys.amounts;
    final BigInt fee = sourceKeys.total - destinationKeys.total;
    final inputs = sourceKeys.toRctInputs;
    final outs = destinationKeys.toRctOuts;
    final extra = destinationKeys.toExtraBytes();
    final tx = MoneroTransactionPrefix(vin: inputs, vout: outs, extra: extra);
    final txHash = tx.getTranactionPrefixHash();
    final CtKeyV outSk = List.generate(
        outs.length, (_) => CtKey(dest: RCT.zero(), mask: RCT.zero()));
    if (fakeSignature) {
      return RCTGeneratorUtils.genFakeRctSimple(
          message: txHash,
          inSk: inSk,
          destinations: destinationPubKeys.map((e) => e.key).toList(),
          inamounts: inamounts,
          outamounts: outamounts,
          txnFee: fee,
          mixRing: mixRing,
          amountKeys: destinationKeys.amountKeys,
          index: index,
          outSk: outSk,
          createLinkable: !isMultisig,
          aResult: aResult);
    }
    return RCTGeneratorUtils.genRctSimple(
        message: txHash,
        inSk: inSk,
        destinations: destinationPubKeys.map((e) => e.key).toList(),
        inamounts: inamounts,
        outamounts: outamounts,
        txnFee: fee,
        mixRing: mixRing,
        amountKeys: destinationKeys.amountKeys,
        index: index,
        outSk: outSk,
        createLinkable: !isMultisig,
        aResult: aResult);
  }

  static MoneroTransaction _buildTx(
      {required ComputeDestinationKeys destinationKeys,
      required ComputeSourceKeys sourceKeys,
      required RCTSignature signature}) {
    final extra = destinationKeys.toExtraBytes();
    return MoneroTransaction(
        vin: sourceKeys.toRctInputs,
        vout: destinationKeys.toRctOuts,
        extra: extra,
        signature: signature);
  }
}