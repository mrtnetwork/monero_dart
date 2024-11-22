part of 'package:monero_dart/src/api/api.dart';

abstract class MoneroApiInterface {
  abstract final QuickMoneroProvider provider;

  /// Observes and decodes transaction outputs for a watch-only wallet.
  ///
  /// This method processes a list of transactions to identify and extract
  /// locked outputs relevant to the provided account's keys. It is suitable
  /// for watch-only wallets, allowing monitoring of incoming funds or changes.
  ///
  /// Note: Since watch-only wallets lack private spend keys, this method
  /// cannot generate key images for the identified outputs, which are necessary
  /// for spending or marking outputs as spent.
  ///
  /// Parameters:
  /// - [transactions] : A list of Monero transactions to analyze.
  /// - [account] : The base account keys (view and spend keys) used for
  ///   identifying relevant outputs.
  List<MoneroLockedOutput> watchTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account});

  /// Observes and decodes transaction outputs based on transaction hashes for a watch-only wallet.
  ///
  /// This method fetches and processes transactions using the provided hashes to identify
  /// and decode outputs relevant to the specified account. It is designed for watch-only
  /// wallets, enabling tracking of transaction outputs without access to the private spend key.
  ///
  /// Note: As this is a watch-only operation, it cannot generate key images for the
  /// identified outputs. Key images are required for spending or marking outputs as spent.
  ///
  /// Parameters:
  /// - [txHashes] : A list of transaction hashes to fetch and analyze.
  /// - [account] : The base account keys (view and spend keys) used for identifying
  ///   relevant outputs.
  Future<List<MoneroLockedOutput>> watchTxHashesOutputs(
      {required List<String> txHashes, required MoneroBaseAccountKeys account});

  /// Decodes transaction amounts and generates key images for the provided transactions.
  ///
  /// This method processes a list of transactions to identify outputs associated with the
  /// specified account and generates key images for those outputs. It is suitable for
  /// fully accessible wallets that possess both the private view and private spend keys.
  ///
  /// Parameters:
  /// - [transactions] : A list of Monero transactions to analyze and decode.
  /// - [account] : The base account keys (view and spend keys) used for identifying
  ///   relevant outputs and generating key images.
  List<MoneroUnlockedOutput> unlockTransactionOutputs(
      {required List<MoneroTransaction> transactions,
      required MoneroBaseAccountKeys account});

  /// Decodes transaction amounts and generates key images for the specified transaction hashes.
  ///
  /// This method retrieves and processes transactions using their hashes, identifying outputs
  /// associated with the provided account and generating key images. It is particularly useful
  /// for mempool transactions, allowing you to track and prepare outputs for potential spending
  /// even before they are confirmed in a block.
  ///
  /// Parameters:
  /// - [txHashes] : A list of transaction hashes to fetch, decode, and analyze.
  /// - [account] : The base account keys (view and spend keys) used for identifying
  ///   relevant outputs and generating key images.
  Future<List<MoneroUnlockedOutput>> unlockTxHashesOutputs(
      {required List<String> txHashes, required MoneroBaseAccountKeys account});

  /// Reads and extracts transaction payments for watch-only wallets.
  ///
  /// This method processes a list of transactions to identify and retrieve payment-related
  /// information for the specified account. It is designed for watch-only wallets, enabling
  /// the monitoring of payments without requiring the private spend key.
  ///
  /// A payment differs from an output in that it includes additional metadata, such as:
  /// - The `outPublicKey`, representing the unique public key of the output.
  /// - The `paymentId`, if one is present in the transaction.
  /// - The `globalIndex` of the output within the blockchain.
  /// - The output details themselves.
  ///
  /// Parameters:
  /// - [transactions] : A list of [MoneroTransactionWithOutputIndeces], containing the transactions
  ///   and associated output indices to analyze.
  /// - [account] : The base account keys (view and spend keys) used to identify relevant payments.
  ///
  List<MoneroLockedPayment> watchTransactipnsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account});

  /// Reads transaction outputs and retrieves payments for watch-only wallets.
  ///
  /// This method fetches transactions from the blockchain using their hashes, identifies
  /// relevant outputs, and extracts payment information associated with the specified account.
  /// It is intended for monitoring purposes in watch-only wallets.
  ///
  /// Note:
  /// - The transactions must be confirmed in a block or present in the transaction pool.
  /// - This method retrieves the transactions and attempts to unlock the associated outputs,
  ///   but may not work as expected in some cases. For reliable output unlocking, use
  ///   [unlockTxHashesOutputs].
  ///
  /// Parameters:
  /// - [txHashes] : A list of transaction hashes to fetch and analyze.
  /// - [account] : The base account keys (view and spend keys) used for identifying relevant
  ///   payments.
  ///
  /// Returns:
  /// - A [Future] that resolves to a list of [MoneroLockedPayment], representing the payments
  ///   associated with the provided account, including output metadata and payment-specific details.
  Future<List<MoneroLockedPayment>> watchTxHashesPayments(
      {required List<String> txHashes, required MoneroBaseAccountKeys account});

  /// Reads transaction outputs and retrieves key images for unlocked payments.
  ///
  /// This method processes a list of transactions to identify outputs associated with the
  /// specified account, generate key images, and prepare unlocked payments ready for use
  /// in the transaction builder. It is suitable for wallets with access to the private spend key,
  /// enabling the construction of transactions.
  ///
  /// Additionally, the method can optionally clean up outputs that are already spent,
  /// ensuring only unspent payments are returned.
  ///
  /// Parameters:
  /// - [transactions] : A list of [MoneroTransactionWithOutputIndeces], containing the transactions
  ///   and their output indices to analyze.
  /// - [account] : The base account keys (view and spend keys) used for identifying outputs
  ///   and generating key images.
  /// - [cleanUpSpent] : A [bool] flag (default: `false`) indicating whether to exclude outputs
  ///   that have already been spent.
  Future<List<MoneroUnLockedPayment>> unlockTransactionsPayments(
      {required List<MoneroTransactionWithOutputIndeces> transactions,
      required MoneroBaseAccountKeys account,
      bool cleanUpSpent = false});

  /// Reads transaction outputs and retrieves key images for unlocked payments.
  ///
  /// This method fetches transactions from the blockchain using their hashes, to identify outputs associated with the
  /// specified account, generate key images, and prepare unlocked payments ready for use
  /// in the transaction builder. It is suitable for wallets with access to the private spend key,
  /// enabling the construction of transactions.
  ///
  /// Additionally, the method can optionally clean up outputs that are already spent,
  /// ensuring only unspent payments are returned.
  ///
  /// Parameters:
  /// - [txHashes] : A list of transaction hashes to fetch and analyze.
  /// - [account] : The base account keys (view and spend keys) used for identifying outputs
  ///   and generating key images.
  /// - [cleanUpSpent] : A [bool] flag (default: `false`) indicating whether to exclude outputs
  ///   that have already been spent.
  Future<List<MoneroUnLockedPayment>> unlockTxHashesPayments(
      {required List<String> txHashes,
      required MoneroBaseAccountKeys account,
      bool cleanUpSpent = false});

  /// Converts unlocked payments to multisig unlocked payments for use with the transaction builder.
  ///
  /// This method takes a list of unlocked payments and transforms them into multisig-compatible
  /// unlocked payments for accounts operating in a multisignature (multisig) configuration.
  /// It is designed to work with wallets using multisig account keys, enabling transaction creation
  /// in a collaborative setting.
  ///
  /// Additionally, the method can optionally clean up already spent outputs, ensuring only
  /// unspent multisig payments are included in the result.
  ///
  /// Parameters:
  /// - [account]: The [MoneroMultisigAccountKeys] containing the multisig account keys used for
  ///   processing and identifying outputs.
  /// - [payments]: A list of [UnlockMultisigOutputRequest], representing the unlocked payments
  ///   to be converted into multisig unlocked payments.
  /// - [cleanUpSpent]: A [bool] flag (default: `false`) indicating whether to exclude outputs
  ///   that have already been spent.
  Future<List<MoneroUnlockedMultisigPayment>> unlockMultisigPayments(
      {required MoneroMultisigAccountKeys account,
      required List<UnlockMultisigOutputRequest> payments,
      bool cleanUpSpent = false});

  /// Creates and signs a Ring Confidential Transaction (RingCT) for transferring funds.
  ///
  /// This method facilitates the creation of a Monero transfer by selecting inputs (unlocked payments),
  /// specifying destinations, and signing the resulting transaction. It prepares a complete transaction
  /// ready for broadcasting to the Monero network.
  ///
  /// Parameters:
  /// - [account] : The [MoneroBaseAccountKeys] containing the view and spend keys for signing
  ///   the transaction and identifying associated outputs.
  /// - [payments] : A list of [MoneroUnLockedPayment] representing the inputs to be used for
  ///   the transaction. These payments must be unlocked and available for spending.
  /// - [destinations] : A list of [MoneroTxDestination] specifying the recipients and the amounts
  ///   to transfer.
  /// - [changeAddress] : A [MoneroAddress] specifying the address where any remaining balance
  ///   (change) should be sent.
  /// - [priority] : An optional [MoneroFeePrority] (default: `MoneroFeePrority.defaultPriority`)
  ///   that determines the transaction fee priority. Higher priorities result in faster confirmation
  ///   but incur higher fees.
  Future<MoneroRctTxBuilder> createTransfer({
    required MoneroBaseAccountKeys account,
    required List<MoneroUnLockedPayment> payments,
    required List<MoneroTxDestination> destinations,
    required MoneroAddress changeAddress,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  });

  /// Creates a multisignature (multisig) Ring Confidential Transaction (RingCT) for transferring funds.
  ///
  /// This method facilitates the creation of a Monero multisig transfer by utilizing multisig-compatible
  /// inputs (unlocked payments), specifying destinations, and preparing the transaction for signing by
  /// multiple parties. The resulting transaction can be collaboratively signed by all required participants.
  ///
  /// Parameters:
  /// - [account] : The [MoneroMultisigAccountKeys] containing the view and spend keys for identifying
  ///   associated outputs and preparing the transaction.
  /// - [payments] : A list of [MoneroUnlockedMultisigPayment] representing the inputs to be used
  ///   for the transaction. These payments must be multisig-compatible and unlocked.
  /// - [destinations] : A list of [MoneroTxDestination] specifying the recipients and the amounts to transfer.
  /// - [changeAddress] : A [MoneroAddress] specifying the address where any remaining balance
  ///   (change) should be sent.
  /// - [signers] : A list of [MoneroPublicKey] representing the public keys of the multisig signers
  ///   required for transaction signing.
  /// - [priority] : An optional [MoneroFeePrority] (default: `MoneroFeePrority.defaultPriority`)
  ///   that determines the transaction fee priority. Higher priorities result in faster confirmation
  ///   but incur higher fees.
  Future<MoneroMultisigTxBuilder> createMultisigTransfer({
    required MoneroMultisigAccountKeys account,
    required List<MoneroUnlockedMultisigPayment> payments,
    required List<MoneroTxDestination> destinations,
    required MoneroAddress changeAddress,
    required List<MoneroPublicKey> signers,
    MoneroFeePrority priority = MoneroFeePrority.defaultPriority,
  });

  /// Cleans up spent payments by checking their status and removing any spent payments from the list.
  ///
  /// This method iterates through the list of payments, checks whether each payment has already been
  /// spent, and removes those that are marked as spent. It helps ensure that only unspent payments
  /// remain in the list, optimizing the transaction preparation process.
  ///
  /// The method is generic and works with any type that extends [MoneroUnLockedPayment],
  /// allowing it to be used for both standard and multisig payments.
  Future<List<T>> cleanUpSpent<T extends MoneroUnLockedPayment>(
      List<T> payments);

  List<MoneroUnlockedOutput> unlockSingleTxOutputs(
      {required MoneroTransaction transaction,
      required MoneroBaseAccountKeys account});
}
