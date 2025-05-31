import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/models/models.dart';

class MoneroTransactionHelper {
  static final BigRational _trxDecimal = BigRational(BigInt.from(10).pow(12));

  static BigInt toPiconero(String amount) {
    final parse = BigRational.parseDecimal(amount);
    return (parse * _trxDecimal).toBigInt();
  }

  static String toXMR(BigInt piconero) {
    final parse = BigRational(piconero);
    return (parse / _trxDecimal).toDecimal(digits: 12);
  }

  static List<TxExtra> extraParsing(List<int> extera,
      {bool errorOnFailedParsingExtras = false}) {
    if (extera.isEmpty) return [];
    int consumed = 0;
    final List<TxExtra> exteras = [];
    while (consumed < extera.length) {
      try {
        final json = TxExtra.layout().deserialize(extera.sublist(consumed));
        consumed += json.consumed;
        final r = TxExtra.fromStruct(json.value);
        exteras.add(r);
      } catch (_) {
        if (errorOnFailedParsingExtras) {
          throw const DartMoneroPluginException(
              "Some transaction extras parsing failed.");
        }
        break;
      }
    }
    return exteras;
  }

  static int _txExtraComparator(TxExtra a, TxExtra b) {
    final int indexA = TxExtraTypes.values.indexOf(a.type);
    final int indexB = TxExtraTypes.values.indexOf(b.type);
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }
    if (indexA != -1) return -1;
    if (indexB != -1) return 1;
    return 0;
  }

  static List<int> toTxExtra(List<TxExtra> extera) {
    final ext = List<TxExtra>.from(extera)..sort(_txExtraComparator);
    final List<int> extBytes =
        ext.expand((e) => e.toVariantSerialize()).toList();

    return extBytes;
  }

  static bool hasSameViewTag(
      {required int? viewTag,
      required List<int> derivation,
      required int outIndex}) {
    if (viewTag == null) return true;
    final hash =
        MoneroCrypto.deriveViewTag(derivation: derivation, outIndex: outIndex);
    return viewTag == hash;
  }

  static RctKey? isAccountOut(
      {required MoneroPrivateKey viewSecretKey,
      required List<int> txPubkey,
      required int outIndex,
      required int? viewTag}) {
    final derivation = MoneroCrypto.generateKeyDerivationBigVar(
            pubkey: txPubkey, secretKey: viewSecretKey.privateKey.secret)
        .asImmutableBytes;
    if (hasSameViewTag(
        viewTag: viewTag, derivation: derivation, outIndex: outIndex)) {
      return derivation;
    }
    return null;
  }

  static TxEpemeralKeyResult generateOutputEpemeralKeys({
    required MoneroPrivateKey txSecretKey,
    required MoneroPublicKey txPublicKey,
    MoneroPrivateKey? changeAddressViewSecretKey,
    required MoneroAddress address,
    required int outIndex,
    MoneroAddress? changeAddr,
    MoneroPrivateKey? additionalSecretKey,
  }) {
    List<int>? additionalTxPubKey;
    if (additionalSecretKey != null) {
      if (address.isSubaddress) {
        additionalTxPubKey =
            RCT.scalarmultKey(address.pubSpendKey, additionalSecretKey.key);
      } else {
        additionalTxPubKey = RCT.scalarmultBase(additionalSecretKey.key);
      }
    }
    List<int> derivation;
    if (address == changeAddr) {
      derivation = MoneroCrypto.generateKeyDerivation(
          pubkey: txPublicKey, secretKey: changeAddressViewSecretKey!);
    } else {
      if (address.isSubaddress && additionalSecretKey != null) {
        derivation = MoneroCrypto.generateKeyDerivationBytes(
            pubkey: address.pubViewKey, secretKey: additionalSecretKey.key);
      } else {
        derivation = MoneroCrypto.generateKeyDerivationBytes(
            pubkey: address.pubViewKey, secretKey: txSecretKey.key);
      }
    }
    final pk = MoneroCrypto.derivePublicKeyVar(
        derivation: derivation,
        outIndex: outIndex,
        basePublicKey: MoneroPublicKey.fromBytes(address.pubSpendKey));
    final amountKey = MoneroCrypto.derivationToScalarVar(
        derivation: derivation, outIndex: outIndex);
    TxoutTarget? key;
    final viewTag =
        MoneroCrypto.deriveViewTag(derivation: derivation, outIndex: outIndex);
    key = TxoutToTaggedKey(key: pk.compressed, viewTag: viewTag);
    return TxEpemeralKeyResult(
        txOut: key,
        amountKey: amountKey,
        additionalTxPubKey: additionalTxPubKey == null
            ? null
            : MoneroPublicKey.fromBytes(additionalTxPubKey));
  }

  static RctKey encryptPaymentId(
      {required List<int> paymentId,

      /// view public key and tx secret key
      /// or
      /// tx public key and view secret key
      required MoneroPublicKey pubKey,
      required MoneroPrivateKey secretKey}) {
    const int hashKeyEncryptedPaymentId = 0x8d;
    List<int> data = MoneroCrypto.generateKeyDerivation(
        pubkey: pubKey, secretKey: secretKey);
    data = [...data, hashKeyEncryptedPaymentId];
    data = QuickCrypto.keccack256Hash(data);
    final List<int> p = paymentId.clone();
    for (int b = 0; b < 8; ++b) {
      p[b] ^= data[b];
    }
    return p;
  }

  /// decode output amount.
  static MoneroLockedOutput? getLockedOutputs(
      {required int realIndex,
      required MoneroTransaction tx,
      required MoneroBaseAccountKeys account}) {
    if (realIndex >= tx.vout.length) {
      throw const DartMoneroPluginException(
          "Invalid transaction output index.");
    }
    final out = tx.vout[realIndex];
    final outPublicKey = out.target.getPublicKeyBytes();
    final additionalPubKeys = tx.additionalPubKeys?.pubKeys;
    if (outPublicKey == null ||
        (additionalPubKeys != null &&
            additionalPubKeys.length != tx.vout.length)) {
      return null;
    }
    final viewTag = out.target.getViewTag();

    final List<List<int>> publicKeys = [
      tx.txPubkeyBytes(),
      if (additionalPubKeys != null) additionalPubKeys[realIndex]
    ];
    for (final p in publicKeys) {
      final derivation = isAccountOut(
          viewSecretKey: account.account.privVkey,
          txPubkey: p,
          viewTag: viewTag,
          outIndex: realIndex);
      if (derivation == null) continue;
      for (final index in account.indexes) {
        final pubKey = MoneroCrypto.derivePublicKeyBytesVar(
            derivation: derivation,
            outIndex: realIndex,
            basePublicKey: account.getSpendPublicKey(index));
        if (BytesUtils.bytesEqual(pubKey, outPublicKey)) {
          final sharedSec = MoneroCrypto.derivationToScalarVar(
              derivation: derivation, outIndex: realIndex);
          final amount = RCTGeneratorUtils.decodeRctVar(
              sig: tx.signature.cast(),
              secretKey: sharedSec,
              outputIndex: realIndex);
          if (amount == null) continue;
          return MoneroLockedOutput(
              amount: amount.$1,
              mask: amount.$2,
              derivation: derivation,
              outputPublicKey: outPublicKey,
              accountIndex: index,
              unlockTime: tx.unlockTime,
              realIndex: realIndex);
        }
      }
    }
    return null;
  }

  /// decode output amount and generate key image.
  static MoneroUnlockedOutput? getUnlockOut({
    required MoneroTransaction tx,
    required MoneroBaseAccountKeys account,
    required int realIndex,
  }) {
    final lockedOut =
        getLockedOutputs(tx: tx, account: account, realIndex: realIndex);
    if (lockedOut == null) return null;
    return toUnlockOutput(account: account, out: lockedOut);
  }

  /// decode output amount and convert to locked payment.
  static MoneroLockedPayment? getLockedPayment(
      {required int realIndex,
      required MoneroTransaction tx,
      required MoneroBaseAccountKeys account,
      required List<BigInt> indices}) {
    final lockedOut =
        getLockedOutputs(realIndex: realIndex, tx: tx, account: account);
    if (lockedOut == null) return null;
    return _toPayment(
            out: lockedOut,
            transaction: tx,
            account: account,
            realIndex: realIndex,
            globalIndex: indices[realIndex])
        .cast<MoneroLockedPayment>();
  }

  /// decode output amount and convert to unlocked payment.
  static MoneroUnLockedPayment? getUnlockedPayment({
    required MoneroTransaction tx,
    required MoneroBaseAccountKeys account,
    required List<BigInt> indices,
    required int realIndex,
  }) {
    final lockedOut = getLockedPayment(
        tx: tx, account: account, indices: indices, realIndex: realIndex);
    if (lockedOut == null) return null;
    return toUnlockPayment(account: account, lockedOut: lockedOut);
  }

  /// convert unlocked payment to multisig payment
  static MoneroUnlockedMultisigPayment toMultisigUnlockedOutput(
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
        accountIndex: unlockedOut.accountIndex,
        unlockTime: unlockedOut.unlockTime,
        realIndex: unlockedOut.realIndex);
    return MoneroUnlockedMultisigPayment(
        output: multisigOut,
        txPubkey: payment.txPubkey,
        paymentId: payment.paymentId,
        encryptedPaymentid: payment.encryptedPaymentid,
        multisigInfos: otherSigners,
        globalIndex: payment.globalIndex);
  }

  /// convert locked output to unlocked output.
  static MoneroUnlockedOutput? toUnlockOutput(
      {required MoneroBaseAccountKeys account,
      required MoneroLockedOutput out}) {
    final RctKey spendKey = account.getPrivateSpendKey();
    final scalarStep1 = MoneroCrypto.deriveSecretKey(
        derivation: out.derivation,
        outIndex: out.realIndex,
        privateSpendKey: spendKey);
    MoneroPrivateKey ephemeralSecretKey;
    MoneroPrivateKey? subSecretKey;
    if (out.accountIndex.isSubaddress) {
      subSecretKey = account.getSubAddressSpendPrivateKey(out.accountIndex);
      ephemeralSecretKey =
          MoneroCrypto.scSecretAdd(a: scalarStep1, b: subSecretKey);
    } else {
      ephemeralSecretKey = scalarStep1;
    }

    // final MoneroPrivateKey ephemeralSecretKey = secretKey;
    MoneroPublicKey ephemeralPublicKey;
    if (account.type.isMultisig) {
      ephemeralPublicKey = MoneroCrypto.derivePublicKey(
          derivation: out.derivation,
          outIndex: out.realIndex,
          basePublicKey: account.account.publicSpendKey);
      if (out.accountIndex.isSubaddress) {
        final subAddrPk = subSecretKey!.publicKey;
        ephemeralPublicKey =
            MoneroCrypto.addPublicKey(ephemeralPublicKey, subAddrPk);
      }
    } else {
      ephemeralPublicKey = ephemeralSecretKey.publicKey;
    }
    assert(BytesUtils.bytesEqual(out.outputPublicKey, ephemeralPublicKey.key),
        "should be equal.");
    if (!BytesUtils.bytesEqual(out.outputPublicKey, ephemeralPublicKey.key)) {
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
        accountIndex: out.accountIndex,
        unlockTime: out.unlockTime,
        realIndex: out.realIndex);
  }

  /// convert locked payment to unlocked payment.
  static MoneroUnLockedPayment? toUnlockPayment(
      {required MoneroBaseAccountKeys account,
      required MoneroLockedPayment lockedOut}) {
    final unlockedOut = toUnlockOutput(account: account, out: lockedOut.output);
    if (unlockedOut == null) return null;
    return MoneroUnLockedPayment(
        output: unlockedOut,
        txPubkey: lockedOut.txPubkey,
        paymentId: lockedOut.paymentId,
        encryptedPaymentid: lockedOut.encryptedPaymentid,
        globalIndex: lockedOut.globalIndex);
  }

  static MoneroPayment _toPayment(
      {required MoneroOutput out,
      required MoneroTransaction transaction,
      required MoneroBaseAccountKeys account,
      required int realIndex,
      required BigInt globalIndex,
      List<MoneroMultisigOutputInfo>? multisigInfos}) {
    final txPubKey = transaction.txPublicKey;
    final paymentId = transaction.txPaymentId;
    List<int>? encryptedPaymentId = transaction.txEncryptedPaymentId;
    if (encryptedPaymentId != null) {
      encryptedPaymentId = MoneroTransactionHelper.encryptPaymentId(
          paymentId: encryptedPaymentId,
          pubKey: txPubKey,
          secretKey: account.account.privateViewKey);
    }
    if (out.type == MoneroOutputType.locked) {
      return MoneroLockedPayment(
          output: out.cast<MoneroLockedOutput>(),
          txPubkey: txPubKey.key,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          globalIndex: globalIndex);
    }
    if (out.type == MoneroOutputType.unlockedMultisig) {
      return MoneroUnlockedMultisigPayment(
          output: out.cast<MoneroUnlockedMultisigOutput>(),
          txPubkey: txPubKey.key,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          multisigInfos: multisigInfos!,
          globalIndex: globalIndex);
    }
    return MoneroUnLockedPayment(
        output: out.cast<MoneroUnlockedOutput>(),
        txPubkey: txPubKey.key,
        paymentId: paymentId,
        encryptedPaymentid: encryptedPaymentId,
        globalIndex: globalIndex);
  }

  static List<SpendablePayment<T>>
      generateFakePaymentOuts<T extends MoneroUnLockedPayment>(
          {required List<T> payments, int fakeOutsLength = 16}) {
    final List<List<OutsEntery>> outs = payments.map((e) {
      return List.generate(fakeOutsLength, (i) {
        return OutsEntery(
            index: e.globalIndex - BigInt.from(i),
            key: CtKey(
                dest: i == 0
                    ? e.output.ephemeralPublicKey
                    : RCT.identity(clone: false),
                mask: RCT.identity(clone: false)));
      }).toList();
    }).toList();
    return List.generate(
        payments.length,
        (i) => SpendablePayment(
            payment: payments[i], outs: outs[i], realOutIndex: 0));
  }

  /// proof
  static MECSignature _createProof({
    required MoneroAddress receiverAddress,
    required MoneroPrivateKey txKey,
    required RctKey sharedKey,
    required RctKey hash,
  }) {
    RctKey pubKey = RCT.zero();
    if (receiverAddress.isSubaddress) {
      pubKey = RCT.scalarmultKeyVar(receiverAddress.pubSpendKey, txKey.key);
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey,
          B: receiverAddress.pubSpendKey,
          d: sharedKey,
          r: txKey.key);
    } else {
      pubKey = txKey.publicKey.key;
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey,
          B: null,
          d: sharedKey,
          r: txKey.key);
    }
  }

  static MECSignature _createProofVar(
      {required MoneroAddress receiverAddress,
      required MoneroPrivateKey txKey,
      required RctKey sharedKey,
      required RctKey hash}) {
    RctKey pubKey = RCT.zero();
    if (receiverAddress.isSubaddress) {
      pubKey = RCT.scalarmultKeyVar(receiverAddress.pubSpendKey, txKey.key);
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey,
          B: receiverAddress.pubSpendKey,
          d: sharedKey,
          r: txKey.key);
    } else {
      pubKey = txKey.publicKey.key;
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey,
          B: null,
          d: sharedKey,
          r: txKey.key);
    }
  }

  static MECSignature _createProofIn(
      {required MoneroAddress senderAddress,
      required MoneroPrivateKey secretKey,
      required RctKey sharedKey,
      required RctKey hash,
      required RctKey pubKey}) {
    if (senderAddress.isSubaddress) {
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: senderAddress.pubViewKey,
          A: pubKey,
          B: senderAddress.pubSpendKey,
          d: sharedKey,
          r: secretKey.key);
    } else {
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: senderAddress.pubViewKey,
          A: pubKey,
          B: null,
          d: sharedKey,
          r: secretKey.key);
    }
  }

  static MECSignature _createProofInVar(
      {required MoneroAddress senderAddress,
      required MoneroPrivateKey secretKey,
      required RctKey sharedKey,
      required RctKey hash,
      required RctKey pubKey}) {
    if (senderAddress.isSubaddress) {
      return MoneroCrypto.generateTxProofVar(
          hash: hash,
          R: senderAddress.pubViewKey,
          A: pubKey,
          B: senderAddress.pubSpendKey,
          d: sharedKey,
          r: secretKey.key);
    } else {
      return MoneroCrypto.generateTxProofVar(
          hash: hash,
          R: senderAddress.pubViewKey,
          A: pubKey,
          B: null,
          d: sharedKey,
          r: secretKey.key);
    }
  }

  static BigInt? _findProofAmountVar(
      {required RCTSignature signature, required RctKey sharedSecret}) {
    final derivation = MoneroCrypto.generateKeyDerivationBytesVar(
        pubkey: sharedSecret, secretKey: RCT.identity(clone: false));
    for (int i = 0; i < signature.signature.outPk.length; i++) {
      final sharedSec = MoneroCrypto.derivationToScalarVar(
          derivation: derivation, outIndex: i);
      final amount = RCTGeneratorUtils.decodeRctVar(
          sig: signature, secretKey: sharedSec, outputIndex: i);
      if (amount != null) return amount.$1;
    }
    return null;
  }

  static BigInt? _findProofAmount(
      {required RCTSignature signature, required RctKey sharedSecret}) {
    final derivation = MoneroCrypto.generateKeyDerivationBytes(
        pubkey: sharedSecret, secretKey: RCT.identity(clone: false));
    for (int i = 0; i < signature.signature.outPk.length; i++) {
      final sharedSec =
          MoneroCrypto.derivationToScalar(derivation: derivation, outIndex: i);
      final amount = RCTGeneratorUtils.decodeRct(
          sig: signature, secretKey: sharedSec, outputIndex: i);
      if (amount != null) return amount.$1;
    }
    return null;
  }

  static MoneroTxProof generateInProof({
    required MoneroTransaction transaction,
    required MoneroAccount account,
    String? message,
    required MoneroAccountIndex index,
  }) {
    final List<int> prefixHash =
        _hashProofMessage(message: message ?? '', transaction: transaction);
    final address =
        MoneroAddress(account.subaddress(index.minor, majorIndex: index.major));
    final txPubKey = transaction.txPublicKey;
    final additional = transaction.additionalPubKeys;
    final secretKey = account.privateViewKey;
    final List<RctKey> sharedSecrets = [];
    RctKey temp = RCT.scalarmultKey(txPubKey.key, secretKey.key);
    sharedSecrets.add(temp.clone());
    final List<MECSignature> sigs = [];
    sigs.add(_createProofIn(
        senderAddress: address,
        secretKey: secretKey,
        sharedKey: sharedSecrets[0],
        hash: prefixHash,
        pubKey: txPubKey.key));
    if (additional != null) {
      for (int i = 0; i < additional.pubKeys.length; i++) {
        final pubkey = additional.pubKeys[i];
        temp = RCT.scalarmultKey(pubkey, secretKey.key);
        sharedSecrets.add(temp.clone());
        sigs.add(_createProofIn(
            senderAddress: address,
            secretKey: secretKey,
            sharedKey: sharedSecrets[i + 1],
            hash: prefixHash,
            pubKey: pubkey));
      }
    }
    final proof = MoneroTxProof(
        sharedSecret:
            sharedSecrets.map((e) => MoneroPublicKey.fromBytes(e)).toList(),
        signatures: sigs,
        version: MoneroTxVersion.v2In);

    final RCTSignature rctSignature = transaction.signature.cast();
    for (final ss in sharedSecrets) {
      final amount =
          _findProofAmount(signature: rctSignature, sharedSecret: ss);
      if (amount != null) return proof;
    }
    throw const DartMoneroPluginException("No funds received in this tx.");
  }

  static MoneroTxProof generateInProofVar(
      {required MoneroTransaction transaction,
      required MoneroAccount account,
      String? message,
      required MoneroAccountIndex index}) {
    final List<int> prefixHash =
        _hashProofMessage(message: message ?? '', transaction: transaction);
    final address =
        MoneroAddress(account.subaddress(index.minor, majorIndex: index.major));
    final txPubKey = transaction.txPublicKey;
    final additional = transaction.additionalPubKeys;
    final secretKey = account.privateViewKey;
    final List<RctKey> sharedSecrets = [];
    RctKey temp = RCT.scalarmultKeyVar(txPubKey.key, secretKey.key);
    sharedSecrets.add(temp.clone());
    final List<MECSignature> sigs = [];
    sigs.add(_createProofInVar(
        senderAddress: address,
        secretKey: secretKey,
        sharedKey: sharedSecrets[0],
        hash: prefixHash,
        pubKey: txPubKey.key));
    if (additional != null) {
      for (int i = 0; i < additional.pubKeys.length; i++) {
        final pubkey = additional.pubKeys[i];
        temp = RCT.scalarmultKeyVar(pubkey, secretKey.key);
        sharedSecrets.add(temp.clone());
        sigs.add(_createProofInVar(
            senderAddress: address,
            secretKey: secretKey,
            sharedKey: sharedSecrets[i + 1],
            hash: prefixHash,
            pubKey: pubkey));
      }
    }
    final proof = MoneroTxProof(
        sharedSecret:
            sharedSecrets.map((e) => MoneroPublicKey.fromBytes(e)).toList(),
        signatures: sigs,
        version: MoneroTxVersion.v2In);

    final RCTSignature rctSignature = transaction.signature.cast();
    for (final ss in sharedSecrets) {
      final amount =
          _findProofAmountVar(signature: rctSignature, sharedSecret: ss);
      if (amount != null) return proof;
    }
    throw const DartMoneroPluginException("No funds received in this tx.");
  }

  static RctKey _hashProofMessage(
      {required MoneroTransaction transaction, String? message}) {
    final messageBytes = StringUtils.toBytes(message ?? '');
    return QuickCrypto.keccack256Hash([
      ...BytesUtils.fromHexString(transaction.getTxHash()),
      ...messageBytes
    ]).asImmutableBytes;
  }

  static MoneroTxProof generateOutProof(
      {required MoneroTransaction transaction,
      required List<MoneroPrivateKey> allTxKeys,
      required MoneroAddress receiverAddress,
      String? message}) {
    final txKey = allTxKeys[0];
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message);
    final inSigLen = allTxKeys.length;
    final List<RctKey> sharedSecret = [];
    RctKey temp = RCT.scalarmultKey(receiverAddress.pubViewKey, txKey.key);
    sharedSecret.add(temp.clone());
    final List<MECSignature> sigs = [];
    sigs.add(_createProof(
        receiverAddress: receiverAddress,
        txKey: txKey,
        sharedKey: sharedSecret[0],
        hash: prefixHash));
    for (int i = 1; i < inSigLen; i++) {
      temp = RCT.scalarmultKey(receiverAddress.pubViewKey, allTxKeys[i].key);
      sharedSecret.add(temp.clone());
      sigs.add(_createProof(
          receiverAddress: receiverAddress,
          txKey: allTxKeys[i],
          sharedKey: sharedSecret[i],
          hash: prefixHash));
    }
    final proof = MoneroTxProof(
        sharedSecret:
            sharedSecret.map((e) => MoneroPublicKey.fromBytes(e)).toList(),
        signatures: sigs,
        version: MoneroTxVersion.v2Out);
    final RCTSignature rctSignature = transaction.signature.cast();
    for (final ss in sharedSecret) {
      final amount =
          _findProofAmount(signature: rctSignature, sharedSecret: ss);
      if (amount != null) return proof;
    }

    throw const DartMoneroPluginException("No funds received in this tx.");
  }

  static MoneroTxProof generateOutProofVar(
      {required MoneroTransaction transaction,
      required List<MoneroPrivateKey> allTxKeys,
      required MoneroAddress receiverAddress,
      String? message}) {
    final txKey = allTxKeys[0];
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message);
    final inSigLen = allTxKeys.length;
    final List<RctKey> sharedSecret = [];
    RctKey temp = RCT.scalarmultKeyVar(receiverAddress.pubViewKey, txKey.key);
    sharedSecret.add(temp.clone());
    final List<MECSignature> sigs = [];
    sigs.add(_createProofVar(
        receiverAddress: receiverAddress,
        txKey: txKey,
        sharedKey: sharedSecret[0],
        hash: prefixHash));
    for (int i = 1; i < inSigLen; i++) {
      temp = RCT.scalarmultKeyVar(receiverAddress.pubViewKey, allTxKeys[i].key);
      sharedSecret.add(temp.clone());
      sigs.add(_createProofVar(
          receiverAddress: receiverAddress,
          txKey: allTxKeys[i],
          sharedKey: sharedSecret[i],
          hash: prefixHash));
    }
    final proof = MoneroTxProof(
        sharedSecret:
            sharedSecret.map((e) => MoneroPublicKey.fromBytes(e)).toList(),
        signatures: sigs,
        version: MoneroTxVersion.v2Out);
    final RCTSignature rctSignature = transaction.signature.cast();
    for (final ss in sharedSecret) {
      final amount =
          _findProofAmountVar(signature: rctSignature, sharedSecret: ss);
      if (amount != null) return proof;
    }

    throw const DartMoneroPluginException("No funds received in this tx.");
  }

  static BigInt? checkProof(
      {required MoneroTransaction transaction,
      required String proofStr,
      String? message,
      required MoneroAddress address}) {
    final txPubKey = transaction.txPublicKey;
    final additional = transaction.additionalPubKeys?.asPublicKeys();
    final proof = MoneroTxProof.fromBase58(proofStr);
    if ((additional?.length ?? 0) + 1 != proof.signatures.length) {
      throw const DartMoneroPluginException(
          "Miss matching length of proof and tx pub keys.");
    }
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message ?? '');
    bool verify = false;
    for (int i = 0; i < proof.signatures.length; i++) {
      final sharedSecret = proof.sharedSecret[i];
      final signature = proof.signatures[i];
      verify |= _checkProof(
          address: address,
          signature: signature,
          txPubKey: i == 0 ? txPubKey : additional![i - 1],
          hash: prefixHash,
          sharedSecret: sharedSecret,
          version: proof.version);
    }
    if (!verify) return null;
    final rctSignature = transaction.signature.cast<RCTSignature>();
    for (final ss in proof.sharedSecret) {
      final amount =
          _findProofAmount(signature: rctSignature, sharedSecret: ss.key);
      if (amount != null) return amount;
    }
    return null;
  }

  static BigInt? checkProofVar(
      {required MoneroTransaction transaction,
      required String proofStr,
      String? message,
      required MoneroAddress address}) {
    final txPubKey = transaction.txPublicKey;
    final additional = transaction.additionalPubKeys?.asPublicKeys();
    final proof = MoneroTxProof.fromBase58(proofStr);
    if ((additional?.length ?? 0) + 1 != proof.signatures.length) {
      throw const DartMoneroPluginException(
          "Miss matching length of proof and tx pub keys.");
    }
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message ?? '');
    bool verify = false;
    for (int i = 0; i < proof.signatures.length; i++) {
      final sharedSecret = proof.sharedSecret[i];
      final signature = proof.signatures[i];
      verify |= _checkProofVar(
          address: address,
          signature: signature,
          txPubKey: i == 0 ? txPubKey : additional![i - 1],
          hash: prefixHash,
          sharedSecret: sharedSecret,
          version: proof.version);
    }
    if (!verify) return null;
    final rctSignature = transaction.signature.cast<RCTSignature>();
    for (final ss in proof.sharedSecret) {
      final amount =
          _findProofAmountVar(signature: rctSignature, sharedSecret: ss.key);
      if (amount != null) return amount;
    }
    return null;
  }

  static bool _checkProof(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required MoneroPublicKey sharedSecret,
      required MoneroTxVersion version}) {
    if (version.isOut) {
      return _checkProofOut(
          address: address,
          signature: signature,
          txPubKey: txPubKey,
          hash: hash,
          sharedSecret: sharedSecret.key,
          version: version);
    }
    return _checkProofIn(
        address: address,
        signature: signature,
        txPubKey: txPubKey,
        hash: hash,
        sharedSecret: sharedSecret.key,
        version: version);
  }

  static bool _checkProofVar(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required MoneroPublicKey sharedSecret,
      required MoneroTxVersion version}) {
    if (version.isOut) {
      return _checkProofOutVar(
          address: address,
          signature: signature,
          txPubKey: txPubKey,
          hash: hash,
          sharedSecret: sharedSecret.key,
          version: version);
    }
    return _checkProofInVar(
        address: address,
        signature: signature,
        txPubKey: txPubKey,
        hash: hash,
        sharedSecret: sharedSecret.key,
        version: version);
  }

  static bool _checkProofOut(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required RctKey sharedSecret,
      required MoneroTxVersion version}) {
    if (address.isSubaddress) {
      return MoneroCrypto.verifyTxProof(
          hash: hash,
          R: txPubKey.key,
          A: address.pubViewKey,
          B: address.pubSpendKey,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProof(
        hash: hash,
        R: txPubKey.key,
        A: address.pubViewKey,
        B: null,
        d: sharedSecret,
        signature: signature,
        version: version.version);
  }

  static bool _checkProofOutVar(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required RctKey sharedSecret,
      required MoneroTxVersion version}) {
    if (address.isSubaddress) {
      return MoneroCrypto.verifyTxProofVar(
          hash: hash,
          R: txPubKey.key,
          A: address.pubViewKey,
          B: address.pubSpendKey,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProofVar(
        hash: hash,
        R: txPubKey.key,
        A: address.pubViewKey,
        B: null,
        d: sharedSecret,
        signature: signature,
        version: version.version);
  }

  static bool _checkProofIn(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required RctKey sharedSecret,
      required MoneroTxVersion version}) {
    if (address.isSubaddress) {
      return MoneroCrypto.verifyTxProof(
          hash: hash,
          R: address.pubViewKey,
          A: txPubKey.key,
          B: address.pubSpendKey,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProof(
        hash: hash,
        R: address.pubViewKey,
        A: txPubKey.key,
        B: null,
        d: sharedSecret,
        signature: signature,
        version: version.version);
  }

  static bool _checkProofInVar(
      {required MoneroAddress address,
      required MECSignature signature,
      required MoneroPublicKey txPubKey,
      required RctKey hash,
      required RctKey sharedSecret,
      required MoneroTxVersion version}) {
    if (address.isSubaddress) {
      return MoneroCrypto.verifyTxProofVar(
          hash: hash,
          R: address.pubViewKey,
          A: txPubKey.key,
          B: address.pubSpendKey,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProofVar(
        hash: hash,
        R: address.pubViewKey,
        A: txPubKey.key,
        B: null,
        d: sharedSecret,
        signature: signature,
        version: version.version);
  }
}
