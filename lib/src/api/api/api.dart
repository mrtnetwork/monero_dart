part of 'package:monero_dart/src/api/api.dart';

class MoneroApi extends MoneroApiInterface with MoneroApiUtils {
  @override
  final QuickMoneroProvider provider;
  MoneroApi(MoneroProvider provider) : provider = QuickMoneroProvider(provider);
  @override
  Future<MoneroMultisigTxBuilder> createMultisigTransfer({
    required MoneroBaseAccountKeys account,
    required List<MoneroUnlockedMultisigPayment> payments,
    required List<TxDestination> destinations,
    required MoneroAddress changeAddress,
    required List<MoneroPublicKey> signers,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  }) async {
    if (payments.toSet().length != payments.length) {
      throw const DartMoneroPluginException(
          "Multiple payment with same keyimage detected.");
    }
    final outAmounts =
        destinations.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount);
    final inAmounts =
        payments.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
    if (outAmounts >= inAmounts) {
      throw const DartMoneroPluginException(
          "output amounts exceed the total input amount and the fee.");
    }
    if (!account.type.isMultisig) {
      throw const DartMoneroPluginException("Account is not a valid multisig.");
    }
    if (payments.isEmpty) {
      throw const DartMoneroPluginException(
          "No payment details were provided.");
    }

    final baseFee = await provider.baseFee();
    TxDestination change = _getChange(
      destinations: destinations,
      change: changeAddress,
      inamount: inAmounts,
      fee: _getBaseFee(baseFee, priority),
    );
    List<SpendablePayment<MoneroUnlockedMultisigPayment>> spendablePayment =
        provider.generateFakePaymentOuts(payments: payments);
    final estimateTx = MoneroMultisigTxBuilder(
        account: account as MoneroMultisigAccountKeys,
        destinations: [...destinations, change],
        sources: spendablePayment,
        fee: baseFee.fee,
        signers: signers,
        fakeSignature: true);
    final BigInt fee = _calcuateFee(
        baseFee: baseFee, weight: estimateTx.weight(), priority: priority);
    change = _getChange(
        destinations: destinations,
        change: changeAddress,
        inamount: inAmounts,
        fee: fee);
    spendablePayment =
        await provider.generatePaymentOutputs(payments: payments);
    return MoneroMultisigTxBuilder(
        account: account,
        destinations: destinations,
        sources: spendablePayment,
        fee: fee,
        change: change,
        signers: signers,
        fakeSignature: false);
  }

  @override
  Future<MoneroRctTxBuilder> createTransfer(
      {required MoneroBaseAccountKeys account,
      required List<MoneroUnLockedPayment> payments,
      required List<TxDestination> destinations,
      required MoneroAddress changeAddress,
      MoneroFeePrority priority = MoneroFeePrority.defaultPriority}) async {
    if (payments.toSet().length != payments.length) {
      throw const DartMoneroPluginException(
          "Multiple payment with same keyimage detected.");
    }
    if (payments.length > MoneroConst.bulletproofPlussMaxOutputs) {
      throw const DartMoneroPluginException("to many outputs.");
    }
    final outAmounts =
        destinations.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount);
    final inAmounts =
        payments.fold<BigInt>(BigInt.zero, (p, c) => p + c.output.amount);
    if (outAmounts >= inAmounts) {
      throw const DartMoneroPluginException(
          "output amounts exceed the total input amount and the fee.");
    }
    final baseFee = await provider.baseFee();
    TxDestination change = _getChange(
        destinations: destinations,
        change: changeAddress,
        inamount: inAmounts,
        fee: _getBaseFee(baseFee, priority));
    List<SpendablePayment> spendablePayment =
        provider.generateFakePaymentOuts(payments: payments);
    MoneroRctTxBuilder tx = MoneroRctTxBuilder(
        account: account,
        destinations: destinations,
        sources: spendablePayment,
        fee: baseFee.fee,
        fakeSignature: true,
        change: change);
    final BigInt fee =
        _calcuateFee(baseFee: baseFee, weight: tx.weight(), priority: priority);
    change = _getChange(
      destinations: destinations,
      change: changeAddress,
      inamount: inAmounts,
      fee: fee,
    );
    spendablePayment =
        await provider.generatePaymentOutputs(payments: payments);
    tx = MoneroRctTxBuilder(
        account: account,
        destinations: destinations,
        sources: spendablePayment,
        fee: fee,
        change: change,
        fakeSignature: false);
    return tx;
  }

  @override
  Future<List<MoneroUnLockedPayment>> unlockTxHashesPayments(
      {required List<String> txHashes,
      required MoneroBaseAccountKeys account,
      bool cleanUpSpent = false}) async {
    final transactions = await provider.getTxes(txHashes: txHashes);
    return unlockTransactionsPayments(
        transactions: transactions,
        account: account,
        cleanUpSpent: cleanUpSpent);
  }

  @override
  Future<List<MoneroUnlockedMultisigPayment>> unlockMultisigPayments(
      {required MoneroMultisigAccountKeys account,
      required List<UnlockMultisigOutputRequest> payments,
      bool cleanUpSpent = false}) async {
    List<MoneroUnlockedMultisigPayment> multisigPayments = payments
        .map((e) => _toMultisigUnlockedOutput(
            account: account,
            payment: e.payment,
            multisigInfos: e.multisigInfos))
        .toList();

    if (cleanUpSpent) {
      multisigPayments = await this.cleanUpSpent(multisigPayments);
    }
    return multisigPayments;
  }

  @override
  Future<List<MoneroUnLockedPayment>> unlockTransactionsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account,
      bool cleanUpSpent = false}) async {
    final List<MoneroUnLockedPayment> outputs = [];
    for (final tx in transactions) {
      if (!tx.hasIndices) continue;
      for (final index in account.indexes) {
        for (int i = 0; i < tx.transaction.vout.length; i++) {
          final txOutputs = _getUnlockedPayment(
              tx: tx.transaction,
              account: account,
              index: index,
              out: tx.transaction.vout[i],
              outIndex: i,
              indices: tx.outputIndices);
          if (txOutputs == null) continue;
          outputs.add(txOutputs);
          break;
        }
      }
    }
    if (cleanUpSpent) {
      return this.cleanUpSpent(outputs);
    }
    return outputs;
  }

  @override
  Future<List<MoneroLockedPayment>> watchTxHashesPayments(
      {required List<String> txHashes,
      required MoneroBaseAccountKeys account}) async {
    final transactions = await provider.getTxes(txHashes: txHashes);
    return watchTransactipnsPayments(
        transactions: transactions, account: account);
  }

  @override
  List<MoneroLockedPayment> watchTransactipnsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account}) {
    final List<MoneroLockedPayment> outputs = [];
    for (final tx in transactions) {
      if (!tx.hasIndices) continue;
      for (final index in account.indexes) {
        for (int i = 0; i < tx.transaction.vout.length; i++) {
          final txOutputs = _getLockedPayment(
              tx: tx.transaction,
              account: account,
              index: index,
              out: tx.transaction.vout[i],
              realIndex: i,
              indices: tx.outputIndices);
          if (txOutputs == null) continue;
          outputs.add(txOutputs);
          break;
        }
      }
    }
    return outputs;
  }

  @override
  List<MoneroUnlockedOutput> unlockTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account}) {
    final List<MoneroUnlockedOutput> outputs = [];
    for (final tx in transactions) {
      for (final index in account.indexes) {
        for (int i = 0; i < tx.vout.length; i++) {
          final txOutputs = _getUnlockOut(
              tx: tx,
              account: account,
              index: index,
              out: tx.vout[i],
              realIndex: i);
          if (txOutputs == null) continue;
          outputs.add(txOutputs);
          break;
        }
      }
    }
    return outputs;
  }

  /// unlock signle tx outputs.
  @override
  List<MoneroUnlockedOutput> unlockSingleTxOutputs(
      {required MoneroTransaction transaction,
      required MoneroBaseAccountKeys account}) {
    final List<MoneroUnlockedOutput> outputs = [];
    for (final index in account.indexes) {
      for (int i = 0; i < transaction.vout.length; i++) {
        final txOutputs = _getUnlockOut(
            tx: transaction,
            account: account,
            index: index,
            out: transaction.vout[i],
            realIndex: i);
        if (txOutputs == null) continue;
        outputs.add(txOutputs);
        break;
      }
    }
    return outputs;
  }

  @override
  Future<List<MoneroLockedOutput>> watchTxHashesOutputs(
      {required List<String> txHashes,
      required MoneroBaseAccountKeys account}) async {
    final txes = await provider.getTxes(txHashes: txHashes);
    return watchTransactionOutputs(
        transactions: txes.map((e) => e.transaction).toList(),
        account: account);
  }

  @override
  List<MoneroLockedOutput> watchTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account}) {
    final List<MoneroLockedOutput> outputs = [];
    for (final tx in transactions) {
      for (final index in account.indexes) {
        for (int i = 0; i < tx.vout.length; i++) {
          final txOutputs = _getLockedOutputs(
              tx: tx,
              account: account,
              index: index,
              out: tx.vout[i],
              realIndex: i);
          if (txOutputs == null) continue;
          outputs.add(txOutputs);
          break;
        }
      }
    }
    return outputs;
  }

  @override
  Future<List<T>> cleanUpSpent<T extends MoneroUnLockedPayment>(
      List<T> payments) async {
    final keyImages = payments.map((e) => e.keyImageAsHex).toList();
    final status = await provider.keyImageSpends(keyImages);
    final List<T> unspentPayments = [];
    for (int i = 0; i < payments.length; i++) {
      if (status.spentStatus[i].isUnspent) {
        unspentPayments.add(payments[i]);
      }
    }
    return unspentPayments;
  }

  /// unlock transaction
  @override
  Future<List<MoneroUnlockedOutput>> unlockTxHashesOutputs(
      {required List<String> txHashes,
      required MoneroBaseAccountKeys account}) async {
    if (txHashes.isEmpty) return [];
    final txes = await provider.getTxes(txHashes: txHashes);
    return txes
        .map((e) =>
            unlockSingleTxOutputs(transaction: e.transaction, account: account)
                .toList())
        .expand((e) => e)
        .toList();
  }
}
