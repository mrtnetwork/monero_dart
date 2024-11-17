part of 'package:monero_dart/src/api/api.dart';

class MoneroFeePrority {
  final String name;
  final int index;
  const MoneroFeePrority._({required this.name, required this.index});
  static const MoneroFeePrority defaultPriority =
      MoneroFeePrority._(name: "default", index: 0);
  static const MoneroFeePrority low = MoneroFeePrority._(name: "Low", index: 1);
  static const MoneroFeePrority medium =
      MoneroFeePrority._(name: "Medium", index: 2);
  static const MoneroFeePrority high =
      MoneroFeePrority._(name: "High", index: 3);

  @override
  String toString() {
    return "MoneroFeePrority.$name";
  }
}

class MoneroApi extends MoneroApiInterface with MoneroApiUtils {
  @override
  final QuickMoneroProvider provider;
  MoneroApi(this.provider);
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
  Future<MoneroRctTxBuilder> createTransfer({
    required MoneroBaseAccountKeys account,
    required List<MoneroUnLockedPayment> payments,
    required List<TxDestination> destinations,
    required MoneroAddress changeAddress,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  }) async {
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
        destinations: [...destinations, change],
        sources: spendablePayment,
        fee: baseFee.fee,
        fakeSignature: true);
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
      required MoneroBaseAccountKeys account}) async {
    final transactions = await provider.getTxes(txHashes: txHashes);
    return unlockTransactionsPayments(
        transactions: transactions, account: account);
  }

  @override
  List<MoneroUnlockedMultisigPayment> unlockMultisigPayments(
      {required MoneroMultisigAccountKeys account,
      required List<UnlockMultisigOutputRequest> payments}) {
    return payments
        .map((e) => _toMultisigUnlockedOutput(
            account: account,
            payment: e.payment,
            multisigInfos: e.multisigInfos))
        .toList();
  }

  @override
  List<MoneroUnLockedPayment> unlockTransactionsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account}) {
    final List<MoneroUnLockedPayment> outputs = [];
    for (final tx in transactions) {
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

  List<MoneroUnlockedOutput> unlockSingleOutput(
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
}
