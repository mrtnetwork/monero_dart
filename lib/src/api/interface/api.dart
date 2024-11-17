part of 'package:monero_dart/src/api/api.dart';

abstract class MoneroApiInterface {
  abstract final QuickMoneroProvider provider;

  List<MoneroLockedOutput> watchTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account});

  List<MoneroUnlockedOutput> unlockTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account});

  /// Read transactions outputs for watch only wallets.
  List<MoneroLockedPayment> watchTransactipnsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account});

  /// Read transaction outputs for watch only wallets.
  Future<List<MoneroLockedPayment>> watchTxHashesPayments(
      {required List<String> txHashes, required MoneroBaseAccountKeys account});

  /// read transactions outputs and retrive keyimage.
  List<MoneroUnLockedPayment> unlockTransactionsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account});

  /// read transactions outputs and retrive keyimage.
  Future<List<MoneroUnLockedPayment>> unlockTxHashesPayments(
      {required List<String> txHashes, required MoneroBaseAccountKeys account});

  List<MoneroUnlockedMultisigPayment> unlockMultisigPayments(
      {required MoneroMultisigAccountKeys account,
      required List<UnlockMultisigOutputRequest> payments});

  Future<MoneroRctTxBuilder> createTransfer({
    required MoneroBaseAccountKeys account,
    required List<MoneroUnLockedPayment> payments,
    required List<TxDestination> destinations,
    required MoneroAddress changeAddress,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  });

  Future<MoneroMultisigTxBuilder> createMultisigTransfer({
    required MoneroBaseAccountKeys account,
    required List<MoneroUnlockedMultisigPayment> payments,
    required List<TxDestination> destinations,
    required MoneroAddress changeAddress,
    required List<MoneroPublicKey> signers,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  });
}
