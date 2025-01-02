import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';

class WalletRPCCheckReserveProofResponse {
  final bool good;
  final BigInt? spent;
  final BigInt? total;
  WalletRPCCheckReserveProofResponse.fromJson(Map<String, dynamic> json)
      : good = json["good"],
        spent = BigintUtils.tryParse(json["spent"]),
        total = BigintUtils.tryParse(json["total"]);
}

class WalletRPCCheckTxKeyResponse {
  /// Number of block mined after the one with the transaction.
  final int confirmations;

  /// States if the transaction is still in pool or has been added to a block.
  final bool inPool;

  /// Amount of the transaction.
  final BigInt received;
  WalletRPCCheckTxKeyResponse.fromJson(Map<String, dynamic> json)
      : confirmations = IntUtils.parse(json["confirmations"]),
        inPool = json["in_pool"],
        received = BigintUtils.parse(json["received"]);
}

class WalletRPCCheckTxProofResponse {
  /// Number of block mined after the one with the transaction.
  final int confirmations;

  /// States if the inputs proves the transaction.
  final bool good;

  /// States if the transaction is still in pool or has been added to a block.
  final bool inPool;

  /// Amount of the transaction.
  final BigInt received;
  WalletRPCCheckTxProofResponse.fromJson(Map<String, dynamic> json)
      : confirmations = IntUtils.parse(json["confirmations"]),
        inPool = json["in_pool"],
        good = json["good"],
        received = BigintUtils.parse(json["received"]);
}

class WalletRPCCreateAccountResponse {
  /// Index of the new account.
  final int accountIndex;

  /// Address for this account. Base58 representation of the public keys.
  final MoneroAddress address;

  WalletRPCCreateAccountResponse.fromJson(Map<String, dynamic> json)
      : accountIndex = IntUtils.parse(json["account_index"]),
        address = MoneroAddress(json["address"]);
}

class WalletRPCCreateAddressResponse {
  /// Index of the new address under the input account.
  final int accountIndex;

  /// Newly created address. Base58 representation of the public keys.
  final MoneroAddress address;

  /// List of address indices.
  final List<int> addressIndices;

  /// list of addresses.
  final List<MoneroAddress> addresses;

  WalletRPCCreateAddressResponse.fromJson(Map<String, dynamic> json)
      : accountIndex = IntUtils.parse(json["account_index"]),
        address = MoneroAddress(json["address"]),
        addressIndices = (json["address_indices"] as List)
            .map((e) => IntUtils.parse(e))
            .toList(),
        addresses =
            (json["addresses"] as List).map((e) => MoneroAddress(e)).toList();
}

class WalletRPCTransferDescriptionResponse {
  /// The sum of the inputs spent by the transaction in atomic-units.
  final BigInt amountIn;

  /// The sum of the outputs created by the transaction in atomic-units.
  final BigInt amountOut;

  /// The address of the change recipient.
  final MoneroAddress changeAddress;

  /// The amount sent to the change address in atomic-units.
  final BigInt changeAmount;

  /// The number of fake outputs added to single-output transactions. Fake outputs have 0 amount and are sent to a random address.
  final int dummyOutputs;

  /// Arbitrary transaction data in hexadecimal format.
  final String extra;

  /// The fee charged for the transaction in atomic-units.
  final BigInt fee;

  /// payment ID for this transfer.
  final String paymentId;
  final List<WalletRPCRecipientResponse> recipients;

  WalletRPCTransferDescriptionResponse({
    required this.amountIn,
    required this.amountOut,
    required this.changeAddress,
    required this.changeAmount,
    required this.dummyOutputs,
    required this.extra,
    required this.fee,
    required this.paymentId,
    required this.recipients,
  });

  // Factory constructor to create a Transaction instance from JSON
  factory WalletRPCTransferDescriptionResponse.fromJson(
      Map<String, dynamic> json) {
    return WalletRPCTransferDescriptionResponse(
      amountIn: BigintUtils.parse(json['amount_in']),
      amountOut: BigintUtils.parse(json['amount_out']),
      changeAddress: MoneroAddress(json['change_address']),
      changeAmount: BigintUtils.parse(json['change_amount']),
      dummyOutputs: json['dummy_outputs'],
      extra: json['extra'],
      fee: BigintUtils.parse(json['fee']),
      paymentId: json['payment_id'],
      recipients: (json['recipients'] as List<dynamic>)
          .map((recipient) => WalletRPCRecipientResponse.fromJson(recipient))
          .toList(),
    );
  }
}

class WalletRPCRecipientResponse {
  /// The public address of the recipient.
  final MoneroAddress address;

  /// The amount sent to the recipient in atomic-units.
  final BigInt amount;

  WalletRPCRecipientResponse({
    required this.address,
    required this.amount,
  });

  // Factory constructor to create a Recipient instance from JSON
  factory WalletRPCRecipientResponse.fromJson(Map<String, dynamic> json) {
    return WalletRPCRecipientResponse(
      address: MoneroAddress(json['address']),
      amount: BigintUtils.parse(json['amount']),
    );
  }
}

class WalletRPCDescribeTransferResponse {
  /// The descriptions of the transfer
  final List<WalletRPCTransferDescriptionResponse> desc;

  /// The number of inputs in the ring (1 real output + the number of decoys from the blockchain) (Unless dealing with pre rct outputs, this field is ignored on mainnet).
  final int ringSize;

  /// The number of blocks before the monero can be spent (0 for no lock).
  final int unlockTime;
  WalletRPCDescribeTransferResponse.fromJson(Map<String, dynamic> json)
      : desc = (json["desc"] as List)
            .map((e) => WalletRPCTransferDescriptionResponse.fromJson(e))
            .toList(),
        unlockTime = IntUtils.parse(json["unlock_time"]),
        ringSize = IntUtils.parse(json["ring_size"]);
}

class WalletRPCEstimateTxSizeAndWeightResponse {
  final int size;
  final int weight;

  WalletRPCEstimateTxSizeAndWeightResponse.fromJson(Map<String, dynamic> json)
      : size = IntUtils.parse(json["size"]),
        weight = IntUtils.parse(json["weight"]);
}

class WalletRPCExchangeMultisigKeysResponse {
  final MoneroAddress address;
  final String multisigInfo;

  WalletRPCExchangeMultisigKeysResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        multisigInfo = json["multisig_info"];
}

class WalletRPCExportKeyImageResponse {
  final String keyImage;
  final String signature;

  WalletRPCExportKeyImageResponse.fromJson(Map<String, dynamic> json)
      : keyImage = json["key_image"],
        signature = json["signature"];
}

class WalletRPCExportKeyImagesResponse {
  final List<WalletRPCExportKeyImageResponse> signedKeyImages;
  final int offset;

  WalletRPCExportKeyImagesResponse.fromJson(Map<String, dynamic> json)
      : signedKeyImages = (json["signed_key_images"] as List)
            .map((e) => WalletRPCExportKeyImageResponse.fromJson(e))
            .toList(),
        offset = IntUtils.parse(json["offset"]);
}

class WalletRPCGenerateFromKeysResponse {
  final MoneroAddress address;
  final String info;

  WalletRPCGenerateFromKeysResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        info = json["info"];
}

class WalletRPCGetAccountTagsResponse {
  /// Filter tag.
  final String? tag;

  /// Label for the tag.
  final String? label;

  ///  List of tagged account indices.
  final List<int> accounts;

  WalletRPCGetAccountTagsResponse.fromJson(Map<String, dynamic> json)
      : tag = json["tag"],
        label = json["label"],
        accounts = (json["accounts"] as List?)
                ?.map((e) => IntUtils.parse(e))
                .toList() ??
            [];
}

class WalletRPCSubAddressAcountResponse {
  /// Index of the account.
  final int accountIndex;

  /// Balance of the account (locked or unlocked).
  final BigInt balance;

  /// address.
  final MoneroAddress baseAddress;

  /// Label of the account.
  final String? label;

  /// Tag for filtering accounts.
  final String? tag;

  /// unsigned int; Unlocked balance for the account.
  final BigInt unlockedBalance;
  const WalletRPCSubAddressAcountResponse(
      {required this.accountIndex,
      required this.balance,
      required this.baseAddress,
      required this.label,
      required this.tag,
      required this.unlockedBalance});
  WalletRPCSubAddressAcountResponse.fromJson(Map<String, dynamic> json)
      : accountIndex = IntUtils.parse(json["account_index"]),
        label = json["label"],
        tag = json["tag"],
        unlockedBalance = BigintUtils.parse(json["unlocked_balance"]),
        balance = BigintUtils.parse(json["balance"]),
        baseAddress = MoneroAddress(json["base_address"]);
}

class WalletRPCGetAccountsResponse {
  final List<WalletRPCSubAddressAcountResponse> subaddressAccounts;
  final BigInt totalBalance;
  final BigInt totalUnlockedBalance;
  WalletRPCGetAccountsResponse.fromJson(Map<String, dynamic> json)
      : subaddressAccounts = (json["subaddress_accounts"] as List)
            .map((e) => WalletRPCSubAddressAcountResponse.fromJson(e))
            .toList(),
        totalBalance = BigintUtils.parse(json["total_balance"]),
        totalUnlockedBalance =
            BigintUtils.parse(json["total_unlocked_balance"]);
}

class WalletRPCAddressResponse {
  /// The (sub)address represented in base58.
  final MoneroAddress address;

  /// Label of the (sub)address
  final String label;

  /// index of the (sub)address.
  final int addressIndex;

  /// states if the (sub)address has already received funds
  final bool used;
  WalletRPCAddressResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        label = json["label"],
        addressIndex = IntUtils.parse(json["address_index"]),
        used = json["used"];
}

class WalletRPCAddressBookResponse {
  /// Public address of the entry
  final MoneroAddress address;

  /// Description of this address entry
  final String description;

  final int index;

  final String paymentId;
  WalletRPCAddressBookResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        description = json["description"],
        index = IntUtils.parse(json["index"]),
        paymentId = json["payment_id"];
}

class WalletRPCGetAddressResponse {
  final MoneroAddress address;
  final List<WalletRPCAddressResponse> addresses;
  WalletRPCGetAddressResponse.fromJson(Map<String, dynamic> json)
      : addresses = (json["addresses"] as List)
            .map((e) => WalletRPCAddressResponse.fromJson(e))
            .toList(),
        address = MoneroAddress(json["address"]);
}

class WalletRPCSubAddressIndexResponse {
  final int major;
  final int minor;
  WalletRPCSubAddressIndexResponse.fromJson(Map<String, dynamic> json)
      : major = IntUtils.parse(json["major"]),
        minor = IntUtils.parse(json["minor"]);
  Map<String, dynamic> toJson() {
    return {"major": major, "minor": minor};
  }
}

class WalletRPCSubAddressBalanceInformationResponse {
  final int accountIndex;

  /// Index of the subaddress in the account
  final int addressIndex;

  /// Address at this index. Base58 representation of the public keys.
  final MoneroAddress address;

  /// Balance for the subaddress (locked or unlocked).
  final BigInt balance;

  /// Unlocked balance for the subaddress.
  final BigInt unlockedBalance;

  /// Label for the subaddress.
  final String label;

  /// Number of unspent outputs available for the subaddress.
  final int numUnspentOutputs;
  final int timeToUnlock;
  final int blocksToUnlock;
  WalletRPCSubAddressBalanceInformationResponse.fromJson(
      Map<String, dynamic> json)
      : accountIndex = IntUtils.parse(json["account_index"]),
        addressIndex = IntUtils.parse(json["address_index"]),
        address = MoneroAddress(json["address"]),
        balance = BigintUtils.parse(json["balance"]),
        unlockedBalance = BigintUtils.parse(json["unlocked_balance"]),
        label = json["label"],
        numUnspentOutputs = IntUtils.parse(json["num_unspent_outputs"]),
        timeToUnlock = IntUtils.parse(json["time_to_unlock"]),
        blocksToUnlock = IntUtils.parse(json["blocks_to_unlock"]);
}

class WalletRPCGetBalanceResponse {
  /// The total balance of the current monero-wallet-rpc in session.
  final BigInt balance;

  /// Unlocked funds are those funds that are sufficiently deep enough in the Monero blockchain to be considered safe to spend.
  final BigInt unlockedBalance;

  /// True if importing multisig data is needed for returning a correct balance.
  final bool multisiImportNeeded;

  /// Time (in seconds) before balance is safe to spend.
  final int timeToUnlock;

  /// Number of blocks before balance is safe to spend.
  final int blocksToUnlock;

  /// balance information for each subaddress in an account.
  final List<WalletRPCSubAddressBalanceInformationResponse> perSubAddress;

  WalletRPCGetBalanceResponse.fromJson(Map<String, dynamic> json)
      : balance = BigintUtils.parse(json["balance"]),
        unlockedBalance = BigintUtils.parse(json["unlocked_balance"]),
        multisiImportNeeded = json["multisig_import_needed"],
        timeToUnlock = IntUtils.parse(json["time_to_unlock"]),
        blocksToUnlock = IntUtils.parse(json["blocks_to_unlock"]),
        perSubAddress = (json["per_subaddress"] as List)
            .map((e) =>
                WalletRPCSubAddressBalanceInformationResponse.fromJson(e))
            .toList();
}

class WalletRPCPaymentResponse {
  /// Payment ID matching one of the input ID
  final String paymentId;

  /// Transaction hash used as the transaction ID.
  final String txHash;

  /// Amount for this payment.
  final BigInt amount;

  /// Height of the block that first confirmed this payment.
  final BigInt blockHeight;

  /// Time (in block height) until this payment is safe to spend.
  final BigInt unlockTIme;
  final WalletRPCSubAddressIndexResponse subaddrIndex;

  /// Address receiving the payment; Base58 representation of the public keys.
  final MoneroAddress address;

  final bool? locked;
  WalletRPCPaymentResponse.fromJson(Map<String, dynamic> json)
      : paymentId = json["payment_id"],
        txHash = json["tx_hash"],
        amount = BigintUtils.parse(json["amount"]),
        blockHeight = BigintUtils.parse(json["block_height"]),
        unlockTIme = BigintUtils.parse(json["unlock_time"]),
        subaddrIndex =
            WalletRPCSubAddressIndexResponse.fromJson(json["subaddr_index"]),
        address = MoneroAddress(json["address"]),
        locked = json["locked"];
}

class WalletRPCTransferDestinationResponse {
  /// Amount transferred to this destination.
  final BigInt amount;

  /// Address for this destination. Base58 representation of the public keys.
  final MoneroAddress address;
  WalletRPCTransferDestinationResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        amount = BigintUtils.parse(json["amount"]);
}

class WalletRPCTransferResponse {
  /// Address that transferred the funds. Base58 representation of the public keys.
  final MoneroAddress address;

  /// Amount of this transfer.
  final BigInt amount;

  /// Individual amounts if multiple where received.
  final List<BigInt> amounts;

  /// Number of block mined since the block containing this transaction
  /// (or block height at which the transaction should be added to a block if not yet confirmed)
  final int confirmations;

  /// True if the key image(s) for the transfer have been seen before.
  final bool doubleSpendSeen;

  /// Transaction fee for this transfer.
  final BigInt fee;

  /// Height of the first block that confirmed this transfer.
  final BigInt height;
  final bool locked;

  /// Note about this transfer.
  final String note;

  /// Payment ID for this transfer.
  final String paymentId;
  final WalletRPCSubAddressIndexResponse subaddrIndex;
  final List<WalletRPCSubAddressIndexResponse> subaddrIndices;

  /// Number of confirmations needed for the amount received to
  /// be lower than the accumulated block reward (or close to that).
  final int suggestedConfirmationsThreshold;

  /// POSIX timestamp for the block that confirmed this transfer (or timestamp submission if not mined yet).
  final BigInt timestamp;

  /// Transaction ID of this transfer (same as input TXID).
  final String txid;

  /// Type of transfer, one of the following: "in", "out", "pending", "failed", "pool"
  final String type;

  /// unsigned int; Number of blocks until transfer is safely spendable.
  final int unlockTime;

  /// transfer destinations: (only for outgoing transactions)
  final List<WalletRPCTransferDestinationResponse>? destinations;

  WalletRPCTransferResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        destinations = (json["destinations"] as List?)
            ?.map((e) => WalletRPCTransferDestinationResponse.fromJson(e))
            .toList(),
        amount = BigintUtils.parse(json["amount"]),
        amounts = (json["amounts"] as List?)
                ?.map((e) => BigintUtils.parse(e))
                .toList() ??
            [],
        confirmations = json["confirmations"],
        doubleSpendSeen = json["double_spend_seen"],
        fee = BigintUtils.parse(json["fee"]),
        height = BigintUtils.parse(json["height"]),
        locked = json["locked"],
        note = json["note"],
        paymentId = json["payment_id"],
        subaddrIndex =
            WalletRPCSubAddressIndexResponse.fromJson(json["subaddr_index"]),
        subaddrIndices = (json["subaddr_indices"] as List<dynamic>)
            .map((e) => WalletRPCSubAddressIndexResponse.fromJson(e))
            .toList(),
        suggestedConfirmationsThreshold =
            IntUtils.parse(json["suggested_confirmations_threshold"]),
        timestamp = BigintUtils.parse(json["timestamp"]),
        txid = json["txid"],
        type = json["type"],
        unlockTime = IntUtils.parse(json["unlock_time"]);
}

class WalletRPCTransferByTxIdResponse {
  /// payment information
  final WalletRPCTransferResponse transfer;

  /// If the list length is > 1 then multiple outputs where received in this transaction, each of which has its own transfer
  final List<WalletRPCTransferResponse> transfers;
  WalletRPCTransferByTxIdResponse.fromJson(Map<String, dynamic> json)
      : transfer = WalletRPCTransferResponse.fromJson(json["transfer"]),
        transfers = (json["transfers"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [];
}

class WalletRPCGetTransfersResponse {
  final List<WalletRPCTransferResponse> inTransfers;

  final List<WalletRPCTransferResponse> outTransfers;

  final List<WalletRPCTransferResponse> pendingTransfers;

  final List<WalletRPCTransferResponse> failedTransfers;

  final List<WalletRPCTransferResponse> poolTransfers;

  WalletRPCGetTransfersResponse.fromJson(Map<String, dynamic> json)
      : inTransfers = (json["in"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [],
        outTransfers = (json["out"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [],
        pendingTransfers = (json["pending"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [],
        failedTransfers = (json["failed"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [],
        poolTransfers = (json["pool"] as List?)
                ?.map((e) => WalletRPCTransferResponse.fromJson(e))
                .toList() ??
            [];
}

class WalletRPCSignedKeyImagesParam {
  final String keyImage;
  final String signature;
  const WalletRPCSignedKeyImagesParam(
      {required this.keyImage, required this.signature});
  Map<String, dynamic> toJson() {
    return {"key_image": keyImage, "signature": signature};
  }
}

class WalletRPCImportKeyImagesResponse {
  final BigInt height;
  final BigInt spent;
  final BigInt unspent;
  WalletRPCImportKeyImagesResponse.fromJson(Map<String, dynamic> json)
      : height = BigintUtils.parse(json["height"]),
        spent = BigintUtils.parse(json["spent"]),
        unspent = BigintUtils.parse(json["unspent"]);
}

enum IncommingTransferType { available, unavailable }

class WalletRPCIncommingTransferResponse {
  /// Amount of this transfer
  final BigInt amount;

  /// Mostly internal use, can be ignored by most users.
  final int globalIndex;

  /// Key image for the incoming transfer's unspent output.
  final String keyImage;

  /// Indicates if this transfer has been spent.
  final bool spent;
  final WalletRPCSubAddressIndexResponse? subAddrIndex;
  final int? mSubAddrIndex;

  /// Several incoming transfers may share the same hash if they were in the same transaction.
  final String txHash;

  /// has the output been frozen by freeze.
  final bool? frozen;

  /// is the output spendable.
  final bool? unlocked;
  final BigInt? blockHeight;

  /// public key of our owned output.
  final String? pubKey;
  final int? txSize;
  WalletRPCIncommingTransferResponse.fromJson(Map<String, dynamic> json)
      : amount = BigintUtils.parse(json["amount"]),
        globalIndex = IntUtils.parse(json["global_index"]),
        keyImage = json["key_image"],
        spent = json["spent"],
        subAddrIndex = (json["subaddr_index"] is int)
            ? null
            : WalletRPCSubAddressIndexResponse.fromJson(json["subaddr_index"]),
        mSubAddrIndex = (json["subaddr_index"] is int)
            ? IntUtils.parse(json["subaddr_index"])
            : null,
        txHash = json["tx_hash"],
        frozen = json["frozen"],
        unlocked = json["unlocked"],
        blockHeight = BigintUtils.tryParse(json["block_height"]),
        pubKey = json["pubkey"],
        txSize = json["tx_size"];
}

class WalletRPCIsMultisigResponse {
  final bool multisig;
  final bool ready;
  final int threshhold;
  final int total;
  WalletRPCIsMultisigResponse.fromJson(Map<String, dynamic> json)
      : multisig = json["multisig"],
        ready = json["ready"],
        threshhold = IntUtils.parse(json["threshold"]),
        total = IntUtils.parse(json["total"]);
}

class WalletRPCValidateAddressResponse {
  /// True if the input address is a valid Monero address.
  final bool valid;

  /// True if the given address is an integrated address.
  final bool integrated;

  /// True if the given address is a subaddress
  final bool subaddress;

  /// Specifies which of the three Monero networks (mainnet, stagenet, and testnet) the address belongs to
  final String nettype;

  /// Address which the OpenAlias-formatted address points to, if given.
  final String openaliasAddress;
  WalletRPCValidateAddressResponse.fromJson(Map<String, dynamic> json)
      : valid = json["valid"],
        integrated = json["integrated"],
        subaddress = json["subaddress"],
        nettype = json["nettype"],
        openaliasAddress = json["openalias_address"];
}

class WalletRPCMakeIntegratedAddressResponse {
  final MoneroAddress integratedAddress;
  final String paymentId;

  WalletRPCMakeIntegratedAddressResponse.fromJson(Map<String, dynamic> json)
      : integratedAddress = MoneroAddress(json["integrated_address"]),
        paymentId = json["payment_id"];
}

class WalletRPCMakeMultisigResponse {
  /// multisig wallet address.
  final MoneroAddress address;

  /// Multisig string to share with peers to create the multisig wallet (extra step for N-1/N wallets).
  final String multisigInfo;

  WalletRPCMakeMultisigResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        multisigInfo = json["multisig_info"];
}

class WalletRPCParseUriResponse {
  /// Wallet address
  final MoneroAddress address;

  /// Integer amount to receive, in atomic-units (0 if not provided)
  final BigInt amount;

  /// 16 characters hex encoded.
  final String? paymentId;

  /// Name of the payment recipient (empty if not provided)
  final String recipientName;

  /// Description of the reason for the tx (empty if not provided)
  final String txDescription;
  WalletRPCParseUriResponse.fromJson(Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        paymentId = json["payment_id"],
        recipientName = json["recipient_name"],
        txDescription = json["tx_description"],
        amount = BigintUtils.parse(json["amount"]);
}

class WalletRPCRefreshResponse {
  /// Number of new blocks scanned.
  final int blocksFetched;

  /// States if transactions to the wallet have been found in the blocks.
  final bool receivedMoney;

  WalletRPCRefreshResponse.fromJson(Map<String, dynamic> json)
      : blocksFetched = IntUtils.parse(json["blocks_fetched"]),
        receivedMoney = json["received_money"];
}

class WalletRPCRestoreDeterministicWalletResponse {
  final MoneroAddress address;
  final String info;
  final String seed;
  final bool wasDeprecated;
  WalletRPCRestoreDeterministicWalletResponse.fromJson(
      Map<String, dynamic> json)
      : address = MoneroAddress(json["address"]),
        info = json["info"],
        seed = json["seed"],
        wasDeprecated = json["was_deprecated"];
}

class WalletRPCSignMultisigResponse {
  /// Multisig transaction in hex format.
  final String txDataHex;

  /// array of string; List of transaction Hash.
  final List<String> txHashList;
  WalletRPCSignMultisigResponse.fromJson(Map<String, dynamic> json)
      : txDataHex = json["tx_data_hex"],
        txHashList = (json["tx_hash_list"] as List).cast();
}

class WalletRPCSignTransferResponse {
  /// Set of signed tx to be used for submitting transfer.
  final String signedTxSet;

  /// The tx hashes of every transaction.
  final List<String> txHashList;

  /// The tx raw data of every transaction.
  final List<String> txRawList;
  final List<String> txKeyList;
  WalletRPCSignTransferResponse.fromJson(Map<String, dynamic> json)
      : signedTxSet = json["signed_txset"],
        txHashList = (json["tx_hash_list"] as List).cast(),
        txRawList = (json["tx_raw_list"] as List?)?.cast() ?? [],
        txKeyList = (json["tx_key_list"] as List?)?.cast() ?? [];
}

class WalletRPCSplitIntegratedAddressResponse {
  /// States if the address is a subaddress
  final bool isSubAddress;
  final MoneroAddress standardAddress;
  final String payment;

  WalletRPCSplitIntegratedAddressResponse.fromJson(Map<String, dynamic> json)
      : isSubAddress = json["is_subaddress"],
        standardAddress = MoneroAddress(json["standard_address"]),
        payment = json["payment"];
}

class WalletRPCSweepResponse {
  /// The tx hashes of every transaction.
  final List<String> txHashList;

  /// The transaction keys for every transaction.
  final List<String> txKeyList;

  /// The amount transferred for every transaction.
  final List<BigInt> amountList;

  /// The amount of fees paid for every transaction.
  final List<BigInt> feeList;

  /// Metric used for adjusting fee.
  final List<BigInt> weightList;

  /// The tx as hex string for every transaction.
  final List<String> txBlobList;

  /// List of transaction metadata needed to relay the transactions later.
  final List<String> txMetadataList;

  /// The set of signing keys used in a multisig transaction (empty for non-multisig).
  final String? multisigTxSet;

  /// Set of unsigned tx for cold-signing purposes.
  final String? unsignedTxSet;

  /// Key images of spent outputs.
  final List<WalletRPCSpentKeyImagesResponse> spentKeyImagesList;

  /// Constructor
  WalletRPCSweepResponse({
    required this.txHashList,
    required this.txKeyList,
    required this.amountList,
    required this.feeList,
    required this.weightList,
    required this.txBlobList,
    required this.txMetadataList,
    this.multisigTxSet,
    this.unsignedTxSet,
    required this.spentKeyImagesList,
  });

  Map<String, dynamic> toJson() {
    return {
      "tx_hash_list": txHashList,
      "tx_key_list": txKeyList,
      "amount_list": amountList,
      "fee_list": feeList,
      "weight_list": weightList,
      "tx_blob_list": txBlobList,
      "tx_metadata_list": txMetadataList,
      "multisig_txset": multisigTxSet,
      "unsigned_txset": unsignedTxSet,
      "spent_key_images_list":
          spentKeyImagesList.map((e) => e.toJson()).toList(),
    };
  }

  factory WalletRPCSweepResponse.fromJson(Map<String, dynamic> json) {
    return WalletRPCSweepResponse(
      txHashList: List<String>.from(json["tx_hash_list"] ?? []),
      txKeyList: List<String>.from(json["tx_key_list"] ?? []),
      amountList: (json["amount_list"] as List?)
              ?.map((e) => BigintUtils.parse(e))
              .toList() ??
          [],
      feeList: (json["fee_list"] as List?)
              ?.map((e) => BigintUtils.parse(e))
              .toList() ??
          [],
      weightList: (json["weight_list"] as List?)
              ?.map((e) => BigintUtils.parse(e))
              .toList() ??
          [],
      txBlobList: List<String>.from(json["tx_blob_list"] ?? []),
      txMetadataList: List<String>.from(json["tx_metadata_list"] ?? []),
      multisigTxSet: json["multisig_txset"],
      unsignedTxSet: json["unsigned_txset"],
      spentKeyImagesList: (json["spent_key_images_list"] as List?)
              ?.map((e) => WalletRPCSpentKeyImagesResponse.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WalletRPCSpentKeyImagesResponse {
  final List<String> keyImages;
  WalletRPCSpentKeyImagesResponse.fromJson(Map<String, dynamic> json)
      : keyImages = (json["key_images"] as List?)?.cast() ?? [];
  Map<String, dynamic> toJson() {
    return {"key_images": keyImages};
  }
}

class WalletRPCSweepSingleResponse {
  /// The tx hashes of every transaction.
  final String txHash;

  /// The transaction keys for every transaction.
  final String txKey;

  /// The amount transferred for every transaction.
  final BigInt amount;

  /// The amount of fees paid for every transaction.
  final BigInt fee;

  /// Metric used to calculate transaction fee.
  final BigInt weight;

  /// The tx as hex string for every transaction.
  final String txBlob;

  /// List of transaction metadata needed to relay the transactions later.
  final String txMetadata;

  /// The set of signing keys used in a multisig transaction (empty for non-multisig).
  final String? multisigTxSet;

  /// Set of unsigned tx for cold-signing purposes.
  final String? unsignedTxSet;

  /// Key images of spent outputs.
  final WalletRPCSpentKeyImagesResponse spentKeyImages;

  /// Constructor
  WalletRPCSweepSingleResponse({
    required this.txHash,
    required this.txKey,
    required this.amount,
    required this.fee,
    required this.weight,
    required this.txBlob,
    required this.txMetadata,
    this.multisigTxSet,
    this.unsignedTxSet,
    required this.spentKeyImages,
  });

  Map<String, dynamic> toJson() {
    return {
      "tx_hash": txHash,
      "tx_key": txKey,
      "amount": amount.toString(),
      "fee": fee.toString(),
      "weight": weight.toString(),
      "tx_blob": txBlob,
      "tx_metadata": txMetadata,
      "multisig_txset": multisigTxSet,
      "unsigned_txset": unsignedTxSet,
      "spent_key_images": spentKeyImages.toJson(),
    };
  }

  factory WalletRPCSweepSingleResponse.fromJson(Map<String, dynamic> json) {
    return WalletRPCSweepSingleResponse(
      txHash: json["tx_hash"],
      txKey: json["tx_key"],
      amount: BigintUtils.parse(json["amount"]),
      fee: BigintUtils.parse(json["fee"]),
      weight: BigintUtils.parse(json["weight"]),
      txBlob: json["tx_blob"],
      txMetadata: json["tx_metadata"],
      multisigTxSet: json["multisig_txset"],
      unsignedTxSet: json["unsigned_txset"],
      spentKeyImages: WalletRPCSpentKeyImagesResponse.fromJson(
          json["spent_key_images"] ?? {}),
    );
  }
}

class WalletRPCTransferDestinationParam {
  /// Destination public address.
  final MoneroAddress address;

  /// Amount to send to each destination, in atomic-units.
  final BigInt amount;
  const WalletRPCTransferDestinationParam(
      {required this.address, required this.amount});
  Map<String, dynamic> toJson() {
    return {"address": address.address, "amount": amount.toString()};
  }
}

class WalletRPCAmountsByDestResponse {
  final List<BigInt> amounts;
  WalletRPCAmountsByDestResponse.fromJson(Map<String, dynamic> json)
      : amounts = (json["amounts"] as List?)
                ?.map((e) => BigintUtils.parse(e))
                .toList() ??
            [];
}

class WalletRPCTransferMoneroResponse {
  /// Amount transferred for the transaction.
  final BigInt amount;

  /// Amounts transferred per destination.
  final WalletRPCAmountsByDestResponse? amountsByDest;

  /// Integer value of the fee charged for the txn
  final BigInt fee;

  /// Set of multisig transactions in the process of being signed (empty for non-multisig).
  final String multisigTxSet;

  /// Raw transaction represented as hex string, if get_tx_hex is true.
  final String? txBlob;

  /// String for the publically searchable transaction hash.
  final String txHash;

  /// String for the transaction key if get_tx_key is true, otherwise, blank string.
  final String? txKey;

  /// Set of transaction metadata needed to relay this transfer later, if get_tx_metadata is true.
  final String? txMetadata;

  /// String. Set of unsigned tx for cold-signing purposes.
  final String unsignedTxSet;

  final BigInt? weight;

  final WalletRPCSpentKeyImagesResponse? spentKeyImages;
  WalletRPCTransferMoneroResponse.fromJson(Map<String, dynamic> json)
      : amount = BigintUtils.parse(json["amount"]),
        amountsByDest = json["amounts_by_dest"] == null
            ? null
            : WalletRPCAmountsByDestResponse.fromJson(
                json["amounts_by_dest"] ?? {}),
        fee = BigintUtils.parse(json["fee"]),
        multisigTxSet = json["multisig_txset"],
        txBlob = json["tx_blob"],
        txHash = json["tx_hash"],
        txKey = json["tx_key"],
        txMetadata = json["tx_metadata"],
        unsignedTxSet = json["unsigned_txset"],
        weight = BigintUtils.parse(json["weight"]),
        spentKeyImages = json["spent_key_images"] == null
            ? null
            : WalletRPCSpentKeyImagesResponse.fromJson(
                json["spent_key_images"]);
}
