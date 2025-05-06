part of 'package:monero_dart/src/tx_builder/tx_builder.dart';

class MoneroMultisigTxBuilder
    extends MoneroTxBuilder<SpendablePayment<MoneroUnlockedMultisigPayment>> {
  final KeyV _cachedW;
  final List<CLSAGContext> contexts;
  final List<MoneroPublicKey> signers;
  final int threshold;
  final MoneroMultisigSignedInfo _multisigInfo;
  List<MoneroPublicKey> _currentSigners;
  bool get isReady => _currentSigners.length == threshold;

  MoneroMultisigTxBuilder._({
    required super.sourceKeys,
    required super.destinationKeys,
    required super.transaction,
    required super.destinations,
    required super.sources,
    required super.change,
    required List<MoneroPublicKey> signers,
    required this.contexts,
    required KeyV cachedW,
    required this.threshold,
    required List<MoneroPublicKey> currentSigner,
    required MoneroMultisigSignedInfo multisigInfo,
  })  : _cachedW = cachedW.map((e) => e.asImmutableBytes).toImutableList,
        signers = signers.immutable,
        _currentSigners = currentSigner.immutable,
        _multisigInfo = multisigInfo;
  factory MoneroMultisigTxBuilder.deserialize(List<int> bytes,
      {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return MoneroMultisigTxBuilder.fromStruct(decode);
  }
  factory MoneroMultisigTxBuilder.fromStruct(Map<String, dynamic> json) {
    final sourceKeys = ComputeSourceKeys.fromStruct(json.asMap("sourceKeys"));
    final destinationKeys =
        ComputeDestinationKeys.fromStruct(json.asMap("destinationKeys"));
    final tx = MoneroTransaction.fromStruct(json.asMap("transaction"));
    final change = json.mybeAs<MoneroTxDestination, Map<String, dynamic>>(
        key: "change",
        onValue: (e) {
          return MoneroTxDestination.fromStruct(e);
        });
    final List<MoneroTxDestination> destinations = json
        .asListOfMap("destinations")!
        .map((e) => MoneroTxDestination.fromStruct(e))
        .toList();
    final List<SpendablePayment<MoneroUnlockedMultisigPayment>> sources = json
        .asListOfMap("sources")!
        .map((e) =>
            SpendablePayment<MoneroUnlockedMultisigPayment>.fromStruct(e))
        .toList();
    final List<MoneroPublicKey> signers = json
        .asListBytes("signers")!
        .map((e) => MoneroPublicKey.fromBytes(e))
        .toList();
    final List<MoneroPublicKey> currentSigners = json
        .asListBytes("currentSigners")!
        .map((e) => MoneroPublicKey.fromBytes(e))
        .toList();
    final MoneroMultisigSignedInfo multisigInfo =
        MoneroMultisigSignedInfo.fromStruct(json.asMap("multisigInfo"));
    final int threshold = json.as("threshold");
    final KeyV cachedW = json.asListBytes("cachedW")!;
    final newTx = reConstroctTx(
        destinationKeys: destinationKeys,
        sourceKeys: sourceKeys,
        sources: sources,
        destinations: destinations,
        signature: tx.signature.cast<RCTSignature>());
    if (newTx.item1.getTxHash() != tx.getTxHash()) {
      throw const MoneroCryptoException("transaction verification failed.");
    }
    return MoneroMultisigTxBuilder._(
        sourceKeys: sourceKeys,
        destinationKeys: destinationKeys,
        transaction: newTx.item1,
        destinations: destinations,
        currentSigner: currentSigners,
        sources: sources,
        change: change,
        contexts: newTx.item2,
        cachedW: cachedW,
        signers: signers,
        threshold: threshold,
        multisigInfo: multisigInfo);
  }

  static Layout<Map<String, dynamic>> layout(
      {String? property, MoneroTransaction? transaction}) {
    return LayoutConst.struct([
      ComputeSourceKeys.layout(property: "sourceKeys"),
      ComputeDestinationKeys.layout(property: "destinationKeys"),
      MoneroTransaction.layout(
          property: "transaction",
          transaction: transaction,
          forcePrunable: true),
      MoneroLayoutConst.variantVec(MoneroTxDestination.layout(),
          property: "destinations"),
      MoneroLayoutConst.variantVec(SpendablePayment.layout(),
          property: "sources"),
      LayoutConst.optional(MoneroTxDestination.layout(), property: "change"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "cachedW"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "signers"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "currentSigners"),
      MoneroLayoutConst.varintInt(property: "threshold"),
      MoneroMultisigSignedInfo.layout(property: "multisigInfo")
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "sourceKeys": sourceKeys.toLayoutStruct(),
      "destinationKeys": destinationKeys.toLayoutStruct(),
      "transaction": transaction.toLayoutStruct(),
      "destinations": destinations.map((e) => e.toLayoutStruct()).toList(),
      "sources": sources.map((e) => e.toLayoutStruct()).toList(),
      "change": change?.toLayoutStruct(),
      "cachedW": _cachedW,
      "signers": signers.map((e) => e.key).toList(),
      "threshold": threshold,
      "currentSigners": _currentSigners.map((e) => e.key).toList(),
      "multisigInfo": _multisigInfo.toLayoutStruct()
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, transaction: transaction);
  }

  static MultisigSignatureResponse buildSignature({
    required ComputeDestinationKeys destinationKeys,
    required ComputeSourceKeys sourceKeys,
    required List<SpendablePayment<MoneroUnlockedMultisigPayment>> sources,
    required BigInt fee,
    bool fakeTx = false,
  }) {
    final KeyV a = List.generate(sources.length, (_) => RCT.zero());
    final signature = MoneroTxBuilder._buildSignature(
        destinationKeys: destinationKeys,
        sourceKeys: sourceKeys,
        sources: sources,
        fakeTx: fakeTx,
        isMultisig: true,
        fee: fee,
        aResult: a);
    final message =
        RCTGeneratorUtils.getPreMlsagHash(signature).asImmutableBytes;
    final List<Clsag> clsags = [];
    final List<CLSAGContext> clsagContext = [];
    final KeyV cachedW = List.generate(sources.length, (_) => RCT.zero());
    for (int i = 0; i < sources.length; i++) {
      final ringSize = signature.signature.mixRing![i].length;
      final RctKey I = sources[i].payment.keyImage;
      final int l = sources[i].realOutIndex;
      final KeyV s = List.generate(ringSize, (i) {
        if (i == l) return RCT.zero();
        return RCT.skGen_();
      });
      final RctKey cOffset = signature.rctSigPrunable!.pseudoOuts[i];
      final KeyV p = List.generate(ringSize, (j) {
        return signature.signature.mixRing![i][j].dest;
      });
      final KeyV cNoneZero = List.generate(ringSize, (j) {
        return signature.signature.mixRing![i][j].mask;
      });
      RctKey D = RCT.zero();
      final RctKey z = RCT.zero();
      CryptoOps.scSub(z, sources[i].payment.output.mask, a[i]);
      final RctKey hL =
          RCT.hashToP3Bytes(signature.signature.mixRing![i][l].dest);
      D = RCT.scalarmultKey(hL, z);
      final clsag = Clsag(
          s: s,
          c1: RCT.zero(),
          d: RCT.scalarmultKey(D, RCTConst.invEight),
          i: I);
      clsags.add(clsag);
      final context = CLSAGContext.init(
          p, cNoneZero, cOffset, message, I, D, l, s, kAlphaComponents);
      clsagContext.add(context);
      final mu = context.getMu();
      CryptoOps.scMul(cachedW[i], mu.item1, sourceKeys.inputSecretKeys[i]);
      CryptoOps.scMulAdd(cachedW[i], mu.item2, z, cachedW[i]);
    }
    ClsagPrunable pronable = signature.rctSigPrunable!.cast<ClsagPrunable>();
    pronable = pronable.copyWith(clsag: clsags);
    final updatedSignature =
        RCTSignature(signature: signature.signature, rctSigPrunable: pronable);
    return MultisigSignatureResponse(
        context: clsagContext, wCached: cachedW, signature: updatedSignature);
  }

  factory MoneroMultisigTxBuilder(
      {required MoneroMultisigAccountKeys account,
      required List<MoneroTxDestination> destinations,
      required List<SpendablePayment<MoneroUnlockedMultisigPayment>> sources,
      required List<MoneroPublicKey> signers,
      required BigInt fee,
      bool fakeTx = false,
      MoneroTxDestination? change}) {
    sources =
        List<SpendablePayment<MoneroUnlockedMultisigPayment>>.from(sources)
          ..sort((a, b) =>
              BytesUtils.compareBytes(b.payment.keyImage, a.payment.keyImage));
    sources = sources.immutable;
    final multisigAccount = account.multisigAccount;
    if (signers.contains(multisigAccount.multisigSignerPubKey)) {
      throw const DartMoneroPluginException(
          "Signer list must exclude the owner's public key.");
    }
    if (signers.length + 1 != multisigAccount.threshold) {
      throw const DartMoneroPluginException(
          "The combined total of signers and the owner must equal the required threshold.");
    }
    for (final i in signers) {
      if (!multisigAccount.signers.contains(i)) {
        throw const DartMoneroPluginException(
            "Invalid signer: The specified signer is not recognized in the multisig account.");
      }
    }
    for (final i in sources) {
      final multisigInfos = i.payment.multisigInfos
          .where((e) => e.signer != multisigAccount.multisigSignerPubKey)
          .where((e) => signers.contains(e.signer));
      if (multisigInfos.length + 1 != multisigAccount.threshold) {
        throw const DartMoneroPluginException(
            "Some multisig details are missing to meet the required threshold.");
      }
    }

    final seed = MoneroTxBuilder._createTxSecretKeySeed(
        sources: sources, fakeTx: fakeTx);
    final sourceKeys = MoneroTxBuilder._computeSourceKeys(
      sources: sources,
    );
    final destinationKeys = MoneroTxBuilder._computeDestinationKeys(
        account: account,
        destinations: destinations,
        sources: sourceKeys,
        change: change,
        txSeed: seed,
        fee: fee,
        fakeTx: fakeTx);
    final signature = MoneroMultisigTxBuilder.buildSignature(
        destinationKeys: destinationKeys,
        sourceKeys: sourceKeys,
        sources: sources,
        fakeTx: fakeTx,
        fee: fee);
    final transaction = MoneroMultisigTxBuilder.buildTx(
        sourceKeys: sourceKeys,
        destinationKeys: destinationKeys,
        sources: sources,
        signature: signature.signature);
    final builder = MoneroMultisigTxBuilder._(
        sourceKeys: sourceKeys,
        destinationKeys: destinationKeys,
        transaction: transaction,
        cachedW: signature.wCached,
        contexts: signature.context,
        change: change,
        destinations: destinations,
        sources: sources,
        signers: signers,
        currentSigner: [multisigAccount.multisigSignerPubKey],
        threshold: multisigAccount.threshold,
        multisigInfo: MoneroMultisigSignedInfo.initial(
            signingKeys: account.multisigAccount.multisigPrivateKeys
                .map((e) => e.publicKey)
                .toList(),
            sourceLength: sourceKeys.sourcesLength));
    if (!fakeTx) {
      builder._init();
    }
    return builder;
  }
  static MoneroTransaction buildTx(
      {required ComputeDestinationKeys destinationKeys,
      required ComputeSourceKeys sourceKeys,
      required List<SpendablePayment> sources,
      required RCTSignature signature}) {
    final inputs = sourceKeys.toRctInputs;
    final outs = destinationKeys.toRctOuts;
    final extra = destinationKeys.toExtraBytes();
    return MoneroTransaction(
        vin: inputs, vout: outs, extra: extra, signature: signature);
  }

  static int kAlphaComponents = 2;

  static Tuple<MoneroTransaction, List<CLSAGContext>> reConstroctTx(
      {required ComputeDestinationKeys destinationKeys,
      required ComputeSourceKeys sourceKeys,
      required List<SpendablePayment<MoneroUnlockedMultisigPayment>> sources,
      required List<MoneroTxDestination> destinations,
      required RCTSignature signature}) {
    final inAmout = sourceKeys.total;
    final List<BigInt> outAmounts = destinationKeys.amounts;
    final BigInt outAmout = destinationKeys.total;
    final BigInt fee = inAmout - outAmout;
    final inputs = sourceKeys.toRctInputs;
    final outs = destinationKeys.toRctOuts;
    final extra = destinationKeys.toExtraBytes();
    final txHash =
        MoneroTransactionPrefix(vin: inputs, vout: outs, extra: extra)
            .getTranactionPrefixHash();
    final KeyV amountMasks = [];
    final List<EcdhInfo> ecdhInfos = [];
    final List<CtKey> outPk = [];
    for (int i = 0; i < destinationKeys.outs.length; i++) {
      final destination = destinationKeys.outs[i].target.getPublicKey()!;
      final amountMask =
          RCT.genCommitmentMask(destinationKeys.amountKeys[i]).asImmutableBytes;
      amountMasks.add(amountMask);
      final amountBytes = RCT.d2h(outAmounts[i]);
      final RctKey outMask = RCT.addKeys2_(amountMask, amountBytes, RCTConst.h);
      final ecdh = RCT.ecdhEncode(
          EcdhTuple(
              mask: RCT.zero(),
              amount: amountBytes,
              version: EcdhInfoVersion.v2),
          destinationKeys.amountKeys[i]);
      ecdhInfos.add(ecdh);
      outPk.add(CtKey(dest: destination.key, mask: outMask));
    }
    final List<BulletproofPlus> bpp = [];
    final List<Bulletproof> bp = [];
    final prunable =
        signature.cast<RCTSignature>().rctSigPrunable!.cast<ClsagPrunable>();
    final KeyV v = List.generate(destinationKeys.outs.length,
        (i) => RCT.scalarmultKey(outPk[i].mask, RCTConst.invEight));
    final bulletproofPlus = prunable.cast<RctSigPrunableBulletproofPlus>();
    final proof = bulletproofPlus.bulletproofPlus[0];
    bpp.add(proof.copyWith(v: v));
    final CtKeyM mixRing =
        sources.map((s) => s.outs.map((e) => e.key).toList()).toList();
    final KeyV pseudoOuts = signature.rctSigPrunable!.pseudoOuts;
    final sig = RCTGeneratorUtils.buildSignature(
        type: RCTType.rctTypeBulletproofPlus,
        ecdh: ecdhInfos,
        txnFee: fee,
        outPk: outPk,
        message: txHash,
        mixRing: mixRing,
        rangeSig: [],
        mgs: [],
        bulletProofPlus: bpp,
        bulletProof: bp,
        clsag: [],
        pseudoOuts: pseudoOuts);
    final message = RCTGeneratorUtils.getPreMlsagHash(sig).asImmutableBytes;
    final List<Clsag> clsags = [];
    final List<CLSAGContext> clsagContext = [];
    for (int i = 0; i < sources.length; i++) {
      final ringSize = sig.signature.mixRing![i].length;
      final RctKey I = sources[i].payment.keyImage;
      final int l = sources[i].realOutIndex;
      final KeyV s = prunable.clsag[i].s;
      final RctKey cOffset = sig.rctSigPrunable!.pseudoOuts[i];
      final KeyV p = List.generate(ringSize, (j) {
        return sig.signature.mixRing![i][j].dest;
      });
      final KeyV cNoneZero = List.generate(ringSize, (j) {
        return sig.signature.mixRing![i][j].mask;
      });
      final clsag = Clsag(s: s, c1: RCT.zero(), d: prunable.clsag[i].d, i: I);
      clsags.add(clsag);
      final RctKey D = RCT.scalarmultKey(prunable.clsag[i].d, RCTConst.eight);
      final context = CLSAGContext.init(
          p, cNoneZero, cOffset, message, I, D, l, s, kAlphaComponents);
      clsagContext.add(context);
    }
    final updatedSignature = sig.copyWith(
        rctSigPrunable:
            sig.rctSigPrunable!.cast<ClsagPrunable>().copyWith(clsag: clsags));
    final tx = MoneroTransaction(
        vin: inputs, vout: outs, extra: extra, signature: updatedSignature);
    return Tuple(tx, clsagContext);
  }

  void _nextPartialSing(
      {required KeyM totalAlphaG,
      required KeyM totalAlphaH,
      required KeyM alpha,
      required RctKey x,
      required KeyV c0,
      required KeyV s}) {
    for (int i = 0; i < contexts.length; i++) {
      final sContext = contexts[i];
      final RctKey alphaCombined = RCT.zero();
      final RctKey c = RCT.zero();
      sContext.combineAlphaAndComputeChallenge(
          totalAlphaG: totalAlphaG[i],
          totalAlphaH: totalAlphaH[i],
          alpha: alpha[i],
          alphaCombinedR: alphaCombined,
          c0R: c0[i],
          cR: c);
      final mu = sContext.getMu();
      final RctKey w = RCT.zero();
      CryptoOps.scMul(w, mu.item1, x);
      CryptoOps.scAdd(s[i], s[i], alphaCombined);
      CryptoOps.scMulSub(s[i], c, w, s[i]);
    }
  }

  MoneroTransaction _finalizeTx({required KeyV s, required KeyV c0}) {
    final sig = transaction.signature.cast<RCTSignature>();
    ClsagPrunable prunable = sig.rctSigPrunable!.cast<ClsagPrunable>();
    final List<Clsag> updatedClsag = [];
    for (int i = 0; i < contexts.length; i++) {
      final cslag = prunable.clsag[i];
      final newS = cslag.s.clone();
      newS[sources[i].realOutIndex] = s[i];
      final newClsag = Clsag(s: newS, c1: c0[i], d: cslag.d, i: cslag.i);
      updatedClsag.add(newClsag);
    }

    prunable = prunable.copyWith(clsag: updatedClsag);
    return transaction.copyWith(
        signature:
            RCTSignature(signature: sig.signature, rctSigPrunable: prunable));
  }

  void _firstPartialSign(
      {required int index,
      required KeyV totalAlphaG,
      required KeyV totalAlphaH,
      required KeyV alpha,
      required RctKey c0,
      required RctKey s}) {
    final RctKey c = RCT.zero();
    final RctKey alphaCombined = RCT.zero();
    final clsagContext = contexts[index];
    clsagContext.combineAlphaAndComputeChallenge(
        totalAlphaG: totalAlphaG,
        totalAlphaH: totalAlphaH,
        alpha: alpha,
        alphaCombinedR: alphaCombined,
        c0R: c0,
        cR: c);
    CryptoOps.scMulSub(s, c, _cachedW[index], alphaCombined);
  }

  void _init() {
    final KeyV allUsedL = [];
    for (int j = 0; j < sourceKeys.sourcesLength; j++) {
      final List<MoneroMultisigOutputInfo> otherSignersInfo = sources[j]
          .payment
          .multisigInfos
          .where((e) => signers.contains(e.signer))
          .toList();
      final KeyV alpha = List.generate(
          MoneroMultisigTxBuilder.kAlphaComponents, (_) => RCT.zero());
      for (int m = 0; m < MoneroMultisigTxBuilder.kAlphaComponents; m++) {
        final kLRki = MoneroMultisigUtils.getMultisigCompositeKLRki(
            outPubKey: sources[j].payment.output.outputPublicKey,
            keyImage: sources[j].payment.keyImage,
            newUsedL: _multisigInfo.l[j],
            usedL: allUsedL,
            threshHold: threshold,
            infos: otherSignersInfo);
        alpha[m] = kLRki.k;
        _multisigInfo.totalAlphaG[j][m] = kLRki.L;
        _multisigInfo.totalAlphaH[j][m] = kLRki.R;
      }
      _firstPartialSign(
          index: j,
          totalAlphaG: _multisigInfo.totalAlphaG[j],
          totalAlphaH: _multisigInfo.totalAlphaH[j],
          alpha: alpha,
          c0: _multisigInfo.c0[j],
          s: _multisigInfo.s[j]);
    }
  }

  void sign({
    required MoneroMultisigAccountKeys account,
    required List<MoneroPrivateKey> multisigNonces,
  }) {
    final MoneroMultisigAccount multisigAccount = account.multisigAccount;
    if (isReady) {
      throw const DartMoneroPluginException("transaction is ready.");
    }
    if (!signers.contains(multisigAccount.multisigSignerPubKey)) {
      throw const DartMoneroPluginException(
          "Transaction does not contains your account signer.");
    }
    if (_currentSigners.contains(multisigAccount.multisigSignerPubKey)) {
      throw const DartMoneroPluginException(
          "Account already signed the transaction.");
    }
    final RctKey secretKey = RCT.zero();
    final KeyM nonces = List.generate(sources.length,
        (_) => List.generate(kAlphaComponents, (_) => RCT.zero()));
    final List<MoneroPrivateKey> usedNonces = [];
    for (int s = 0; s < nonces.length; s++) {
      for (int j = 0; j < kAlphaComponents; j++) {
        MoneroPrivateKey? nonce;
        for (final n in multisigNonces) {
          if (usedNonces.contains(n)) continue;
          if (BytesUtils.isContains(
              _multisigInfo.l[s], n.publicKey.compressed)) {
            nonce = n;
            usedNonces.add(nonce);
            break;
          }
        }
        if (nonce != null) {
          nonces[s][j] = nonce.key.clone();
        } else {
          throw const DartMoneroPluginException("Miss match nonces.");
        }
      }
    }
    for (final signer in multisigAccount.multisigPrivateKeys) {
      final pubKey = signer.publicKey;
      if (!_multisigInfo.signingKeys.contains(pubKey)) {
        CryptoOps.scAdd(secretKey, secretKey, signer.key);
        _multisigInfo.signingKeys.add(pubKey);
      }
    }
    _nextPartialSing(
        totalAlphaG: _multisigInfo.totalAlphaG,
        totalAlphaH: _multisigInfo.totalAlphaH,
        alpha: nonces,
        x: secretKey,
        c0: _multisigInfo.c0,
        s: _multisigInfo.s);
    _currentSigners = [
      ..._currentSigners,
      multisigAccount.multisigSignerPubKey
    ];
  }

  @override
  MoneroTransaction getFinalTx() {
    if (!isReady) {
      throw const DartMoneroPluginException(
          "Transaction is not ready. some signature missing.");
    }
    return _finalizeTx(s: _multisigInfo.s, c0: _multisigInfo.c0);
  }
}
