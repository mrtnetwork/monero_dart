part of 'package:monero_dart/src/api/api.dart';

mixin MoneroApiUtils on MoneroApiInterface {
  MoneroLockedOutput? _getLockedOutputs(
      {required MoneroTxout out,
      required int realIndex,
      required MoneroTransaction tx,
      required MoneroBaseAccountKeys account,
      required MoneroAccountIndex index}) {
    final outPublicKey = out.target.getPublicKey();
    if (outPublicKey == null) {
      return null;
    }
    final viewTag = out.target.getViewTag();
    final additionalPubKeys = tx.getTxAdditionalPubKeys();
    final List<MoneroPublicKey> publicKeys = [
      tx.getTxExtraPubKey(),
      if (additionalPubKeys != null) additionalPubKeys.pubKeys[realIndex]
    ];
    for (final p in publicKeys) {
      final derivation = MoneroTransactionHelper.inOuttoAcc(
          publicSpendKey: account.getSpendPublicKey(index),
          viewSecretKey: account.account.privVkey,
          txPubkey: p,
          outPublicKey: outPublicKey,
          viewTag: viewTag,
          outIndex: realIndex);
      if (derivation == null) continue;
      final sharedSec = MoneroCrypto.derivationToScalarFast(
          derivation: derivation, outIndex: realIndex);
      final mask = RCT.zero();

      final amount = RCTGeneratorUtils.decodeRct_(
          sig: tx.signature.cast(),
          secretKey: sharedSec,
          outputIndex: realIndex,
          mask: mask);
      if (amount == null) continue;
      return MoneroLockedOutput(
          amount: amount,
          mask: mask,
          derivation: derivation,
          outputPublicKey: outPublicKey,
          accountIndex: index);
    }
    return null;
  }

  MoneroUnlockedOutput? _getUnlockOut(
      {required MoneroTransaction tx,
      required MoneroBaseAccountKeys account,
      required MoneroAccountIndex index,
      required int realIndex,
      required MoneroTxout out}) {
    final lockedOut = _getLockedOutputs(
        tx: tx, account: account, index: index, realIndex: realIndex, out: out);
    if (lockedOut == null) return null;
    return _toUnlockOutput(
        account: account, out: lockedOut, realIndex: realIndex);
  }

  MoneroLockedPayment? _getLockedPayment(
      {required MoneroTxout out,
      required int realIndex,
      required MoneroTransaction tx,
      required MoneroBaseAccountKeys account,
      required MoneroAccountIndex index,
      required List<BigInt> indices}) {
    final lockedOut = _getLockedOutputs(
        out: out, realIndex: realIndex, tx: tx, account: account, index: index);
    if (lockedOut == null) return null;
    return _toPayment(
        out: lockedOut,
        transaction: tx,
        account: account,
        index: index,
        realIndex: realIndex,
        globalIndex: indices[realIndex]) as MoneroLockedPayment;
  }

  MoneroUnLockedPayment? _getUnlockedPayment(
      {required MoneroTransaction tx,
      required MoneroBaseAccountKeys account,
      required MoneroAccountIndex index,
      required List<BigInt> indices,
      required int outIndex,
      required MoneroTxout out}) {
    final lockedOut = _getLockedPayment(
        tx: tx,
        account: account,
        index: index,
        indices: indices,
        realIndex: outIndex,
        out: out);
    if (lockedOut == null) return null;
    return _toUnlockPayment(account: account, lockedOut: lockedOut);
  }

  MoneroUnlockedMultisigPayment _toMultisigUnlockedOutput(
      {required MoneroMultisigAccountKeys account,
      required MoneroUnLockedPayment payment,
      required List<MoneroMultisigOutputInfo> multisigInfos}) {
    final MoneroUnlockedOutput unlockedOut = payment.output;
    final multisigAccount = account.multisigAccount;
    if (multisigInfos.map((e) => e.signer).toSet().length !=
        multisigInfos.length) {
      throw const DartMoneroPluginException(
          "Duplicate multisig info provided.");
    }
    final signer = multisigAccount.multisigSignerPubKey;
    for (final i in multisigInfos) {
      if (!multisigAccount.signers.contains(i.signer)) {
        throw const DartMoneroPluginException(
            "Invalid multisig info. signer does not exist.");
      }
    }
    final ownerMultisigInfo = multisigInfos.firstWhere(
        (e) => e.signer == signer,
        orElse: () =>
            multisigAccount.generateMultisigInfo(payment.output).info);
    final otherSigners =
        multisigInfos.where((e) => e.signer != signer).toList();

    if (otherSigners.length + 1 < account.multisigAccount.threshold) {
      throw const DartMoneroPluginException(
          "Some multisig output info missing.");
    }

    final multisigKeyImage =
        MoneroMultisigUtils.generateMultisigCompositeKeyImage(
            infos: otherSigners,
            keyImage: unlockedOut.keyImage,
            exclude: ownerMultisigInfo.partialKeyImages.clone());

    final multisigOut = MoneroUnlockedMultisigOutput(
      amount: unlockedOut.amount,
      derivation: unlockedOut.derivation,
      ephemeralSecretKey: unlockedOut.ephemeralSecretKey,
      ephemeralPublicKey: unlockedOut.ephemeralPublicKey,
      multisigKeyImage: multisigKeyImage,
      keyImage: unlockedOut.keyImage,
      mask: unlockedOut.mask,
      outputPublicKey: unlockedOut.outputPublicKey,
      accountindex: unlockedOut.accountIndex,
    );
    return MoneroUnlockedMultisigPayment(
        output: multisigOut,
        txPubkey: payment.txPubkey,
        paymentId: payment.paymentId,
        encryptedPaymentid: payment.encryptedPaymentid,
        index: payment.index,
        multisigInfos: otherSigners,
        globalIndex: payment.globalIndex);
  }

  MoneroUnlockedOutput? _toUnlockOutput(
      {required MoneroBaseAccountKeys account,
      required MoneroLockedOutput out,
      required int realIndex}) {
    // final out = lockedOut.output;
    final RctKey spendKey = account.getPrivateSpendKey();
    final scalarStep1 = MoneroCrypto.deriveSecretKey(
        derivation: out.derivation,
        outIndex: realIndex,
        privateSpendKey: spendKey);
    MoneroPrivateKey secretKey;
    MoneroPrivateKey? subSecretKey;
    if (out.accountIndex.isSubaddress) {
      subSecretKey = account.getSubAddressSpendPrivateKey(out.accountIndex);
      secretKey = MoneroCrypto.scSecretAdd(a: scalarStep1, b: subSecretKey);
    } else {
      secretKey = scalarStep1;
    }

    final MoneroPrivateKey ephemeralSecretKey = secretKey;
    MoneroPublicKey ephemeralPublicKey;
    if (account.type.isMultisig) {
      ephemeralPublicKey = MoneroCrypto.derivePublicKey(
          derivation: out.derivation,
          outIndex: realIndex,
          basePublicKey: account.account.publicSpendKey);
      if (out.accountIndex.isSubaddress) {
        final subAddrPk = subSecretKey!.publicKey;
        ephemeralPublicKey =
            MoneroCrypto.addPublicKey(ephemeralPublicKey, subAddrPk);
      }
    } else {
      ephemeralPublicKey = ephemeralSecretKey.publicKey;
    }
    assert(out.outputPublicKey == ephemeralPublicKey, "should be equal.");
    if (out.outputPublicKey != ephemeralPublicKey) {
      return null;
    }
    final keyImage = MoneroCrypto.generateKeyImage(
        pubkey: ephemeralPublicKey, secretKey: ephemeralSecretKey);
    return MoneroUnlockedOutput(
        amount: out.amount,
        derivation: out.derivation,
        ephemeralPublicKey: ephemeralPublicKey.key,
        ephemeralSecretKey: ephemeralSecretKey.key,
        keyImage: keyImage,
        mask: out.mask,
        outputPublicKey: out.outputPublicKey,
        accountindex: out.accountIndex);
  }

  MoneroUnLockedPayment? _toUnlockPayment(
      {required MoneroBaseAccountKeys account,
      required MoneroLockedPayment lockedOut}) {
    final out = lockedOut.output;
    final RctKey spendKey = account.getPrivateSpendKey();
    final scalarStep1 = MoneroCrypto.deriveSecretKey(
        derivation: out.derivation,
        outIndex: lockedOut.index,
        privateSpendKey: spendKey);
    MoneroPrivateKey secretKey;
    MoneroPrivateKey? subSecretKey;
    if (out.accountIndex.isSubaddress) {
      subSecretKey = account.getSubAddressSpendPrivateKey(out.accountIndex);
      secretKey = MoneroCrypto.scSecretAdd(a: scalarStep1, b: subSecretKey);
    } else {
      secretKey = scalarStep1;
    }

    final MoneroPrivateKey ephemeralSecretKey = secretKey;
    MoneroPublicKey ephemeralPublicKey;
    if (account.type.isMultisig) {
      ephemeralPublicKey = MoneroCrypto.derivePublicKey(
          derivation: out.derivation,
          outIndex: lockedOut.index,
          basePublicKey: account.account.publicSpendKey);
      if (out.accountIndex.isSubaddress) {
        final subAddrPk = subSecretKey!.publicKey;
        ephemeralPublicKey =
            MoneroCrypto.addPublicKey(ephemeralPublicKey, subAddrPk);
      }
    } else {
      ephemeralPublicKey = ephemeralSecretKey.publicKey;
    }
    assert(out.outputPublicKey == ephemeralPublicKey, "should be equal.");
    if (out.outputPublicKey != ephemeralPublicKey) {
      return null;
    }
    final keyImage = MoneroCrypto.generateKeyImage(
        pubkey: ephemeralPublicKey, secretKey: ephemeralSecretKey);
    final outInfo = MoneroUnlockedOutput(
        amount: out.amount,
        derivation: out.derivation,
        ephemeralPublicKey: ephemeralPublicKey.key,
        ephemeralSecretKey: ephemeralSecretKey.key,
        keyImage: keyImage,
        mask: out.mask,
        outputPublicKey: out.outputPublicKey,
        accountindex: out.accountIndex);
    return MoneroUnLockedPayment(
        output: outInfo,
        txPubkey: lockedOut.txPubkey,
        paymentId: lockedOut.paymentId,
        encryptedPaymentid: lockedOut.encryptedPaymentid,
        index: lockedOut.index,
        globalIndex: lockedOut.globalIndex);
  }

  MoneroPayment _toPayment(
      {required MoneroOutput out,
      required MoneroTransaction transaction,
      required MoneroBaseAccountKeys account,
      required MoneroAccountIndex index,
      required int realIndex,
      required BigInt globalIndex,
      List<MoneroMultisigOutputInfo>? multisigInfos}) {
    final txPubKey = transaction.getTxExtraPubKey();
    final paymentId = transaction.getTxPaymentId();
    List<int>? encryptedPaymentId = transaction.getTxEncryptedPaymentId();
    if (encryptedPaymentId != null) {
      encryptedPaymentId = MoneroTransactionHelper.encryptPaymentId(
          paymentId: encryptedPaymentId,
          pubKey: txPubKey,
          secretKey: account.account.privateViewKey);
    }
    if (out.type == MoneroOutputType.locked) {
      return MoneroLockedPayment(
          output: out as MoneroLockedOutput,
          txPubkey: txPubKey,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          index: realIndex,
          globalIndex: globalIndex);
    }
    if (out.type == MoneroOutputType.unlockedMultisig) {
      return MoneroUnlockedMultisigPayment(
          output: out as MoneroUnlockedMultisigOutput,
          txPubkey: txPubKey,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          index: realIndex,
          multisigInfos: multisigInfos!,
          globalIndex: globalIndex);
    }
    return MoneroUnLockedPayment(
        output: out as MoneroUnlockedOutput,
        txPubkey: txPubKey,
        paymentId: paymentId,
        encryptedPaymentid: encryptedPaymentId,
        index: realIndex,
        globalIndex: globalIndex);
  }

  BigInt _getBaseFee(
      DaemonGetEstimateFeeResponse baseFee, MoneroFeePrority priority) {
    if (priority.index >= baseFee.fees.length) {
      throw const DartMoneroPluginException(
          "Failed to determine base fee based on your priority.");
    }
    if (priority.index == 0) return baseFee.fee;
    return baseFee.fees[priority.index];
  }

  TxDestination _getChange({
    required List<TxDestination> destinations,
    required MoneroAddress change,
    required BigInt inamount,
    required BigInt fee,
  }) {
    final outAmounts =
        destinations.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount) + fee;

    final changeAmount = inamount - outAmounts;
    if (changeAmount.isNegative) {
      throw const DartMoneroPluginException(
          "output amounts exceed the total input amount and the fee.");
    }
    return TxDestination(amount: changeAmount, address: change);
  }

  BigInt _calcuateFee(
      {required BigInt weight,
      required DaemonGetEstimateFeeResponse baseFee,
      required MoneroFeePrority priority}) {
    BigInt fee = _getBaseFee(baseFee, priority);
    fee = weight * fee;
    fee = (fee + baseFee.quantizationMask - BigInt.one) ~/
        baseFee.quantizationMask *
        baseFee.quantizationMask;
    return fee;
  }
}
