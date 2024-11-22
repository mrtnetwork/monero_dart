import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/account/account.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:monero_dart/src/crypto/multisig/multisig.dart';
import 'package:monero_dart/src/crypto/ringct/utils/generator.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
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

  static RctKey? inOuttoAccFast(
      {required MoneroPrivateKey viewSecretKey,
      required MoneroPublicKey txPubkey,
      required int outIndex,
      required int? viewTag}) {
    final derivation = MoneroCrypto.generateKeyDerivationFast(
            pubkey: txPubkey, secretKey: viewSecretKey)
        .asImmutableBytes;
    if (hasSameViewTag(
        viewTag: viewTag, derivation: derivation, outIndex: outIndex)) {
      return derivation;
    }
    return null;
  }

  static RctKey? inOuttoAcc({
    required MoneroPrivateKey viewSecretKey,
    required MoneroPublicKey publicSpendKey,
    required MoneroPublicKey txPubkey,
    required MoneroPublicKey outPublicKey,
    required int outIndex,
    required int? viewTag,
  }) {
    final derivation = inOuttoAccFast(
        viewSecretKey: viewSecretKey,
        txPubkey: txPubkey,
        outIndex: outIndex,
        viewTag: viewTag);
    if (derivation != null) {
      final pubKey = MoneroCrypto.derivePublicKeyFast(
          derivation: derivation,
          outIndex: outIndex,
          basePublicKey: publicSpendKey);
      if (pubKey == outPublicKey) {
        return derivation;
      }
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
        additionalTxPubKey = RCT.scalarmultKey_(
            address.pubSpendKey.compressed, additionalSecretKey.key);
      } else {
        additionalTxPubKey = RCT.scalarmultBase_(additionalSecretKey.key);
      }
    }
    List<int> derivation;
    if (address == changeAddr) {
      derivation = MoneroCrypto.generateKeyDerivation(
          pubkey: txPublicKey, secretKey: changeAddressViewSecretKey!);
    } else {
      if (address.isSubaddress && additionalSecretKey != null) {
        derivation = MoneroCrypto.generateKeyDerivation(
            pubkey: address.pubViewKey, secretKey: additionalSecretKey);
      } else {
        derivation = MoneroCrypto.generateKeyDerivation(
            pubkey: address.pubViewKey, secretKey: txSecretKey);
      }
    }
    final pk = MoneroCrypto.derivePublicKey(
        derivation: derivation,
        outIndex: outIndex,
        basePublicKey:
            MoneroPublicKey.fromBytes(address.pubSpendKey.compressed));
    final amountKey = MoneroCrypto.derivationToScalar(
        derivation: derivation, outIndex: outIndex);
    TxoutTarget? key;
    final viewTag =
        MoneroCrypto.deriveViewTag(derivation: derivation, outIndex: outIndex);
    key = TxoutToTaggedKey(key: pk, viewTag: viewTag);
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

  static MECSignature _createProof({
    required MoneroAddress receiverAddress,
    required MoneroPrivateKey txKey,
    required RctKey sharedKey,
    required RctKey hash,
  }) {
    RctKey pubKey = RCT.zero();
    if (receiverAddress.isSubaddress) {
      RCT.scalarmultKey(pubKey, receiverAddress.pubSpendKey.key, txKey.key);
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey.key,
          B: receiverAddress.pubSpendKey.key,
          d: sharedKey,
          r: txKey.key);
    } else {
      pubKey = txKey.publicKey.key;
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: pubKey,
          A: receiverAddress.pubViewKey.key,
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
          R: senderAddress.pubViewKey.key,
          A: pubKey,
          B: senderAddress.pubSpendKey.key,
          d: sharedKey,
          r: secretKey.key);
    } else {
      return MoneroCrypto.generateTxProof(
          hash: hash,
          R: senderAddress.pubViewKey.key,
          A: pubKey,
          B: null,
          d: sharedKey,
          r: secretKey.key);
    }
  }

  static BigInt? _findProofAmount(
      {required RCTSignature signature, required RctKey sharedSecret}) {
    final derivation = MoneroCrypto.generateKeyDerivationBytes(
        pubkey: sharedSecret, secretKey: RCT.identity(clone: false));
    for (int i = 0; i < signature.signature.outPk.length; i++) {
      final sharedSec =
          MoneroCrypto.derivationToScalar(derivation: derivation, outIndex: i);
      final amount = RCTGeneratorUtils.decodeRct_(
          sig: signature, secretKey: sharedSec, outputIndex: i);
      if (amount != null) return amount;
    }
    return null;
  }

  static MoneroTxProof generateInProof({
    required MoneroTransaction transaction,
    required MoneroAccount account,
    required String message,
    required MoneroAccountIndex index,
  }) {
    final List<int> prefixHash =
        _hashProofMessage(message: message, transaction: transaction);
    final address =
        MoneroAddress(account.subaddress(index.minor, majorIndex: index.major));
    final txPubKey = transaction.getTxExtraPubKey();
    final additional = transaction.getTxAdditionalPubKeys();
    final secretKey = account.privateViewKey;
    final List<RctKey> sharedSecrets = [];
    final RctKey temp = RCT.zero();
    RCT.scalarmultKey(temp, txPubKey.key, secretKey.key);
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
        final pubkey = additional.pubKeys[i].key;
        RCT.scalarmultKey(temp, pubkey, secretKey.key);
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

  static RctKey _hashProofMessage({
    required MoneroTransaction transaction,
    required String message,
  }) {
    final messageBytes = StringUtils.toBytes(message);
    return QuickCrypto.keccack256Hash([
      ...BytesUtils.fromHexString(transaction.getTxHash()),
      ...messageBytes
    ]).asImmutableBytes;
  }

  static MoneroTxProof generateOutProof(
      {required MoneroTransaction transaction,
      required List<MoneroPrivateKey> allTxKeys,
      required MoneroAddress receiverAddress,
      required String message}) {
    final txKey = allTxKeys[0];
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message);
    final inSigLen = allTxKeys.length;
    final RctKey temp = RCT.zero();
    final List<RctKey> sharedSecret = [];
    RCT.scalarmultKey(temp, receiverAddress.pubViewKey.key, txKey.key);
    sharedSecret.add(temp.clone());
    final List<MECSignature> sigs = [];
    sigs.add(_createProof(
        receiverAddress: receiverAddress,
        txKey: txKey,
        sharedKey: sharedSecret[0],
        hash: prefixHash));
    for (int i = 1; i < inSigLen; i++) {
      RCT.scalarmultKey(temp, receiverAddress.pubViewKey.key, allTxKeys[i].key);
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

  static BigInt? checkProof(
      {required MoneroTransaction transaction,
      required String proofStr,
      required String message,
      required MoneroAddress address}) {
    final txPubKey = transaction.getTxExtraPubKey();
    final additional = transaction.getTxAdditionalPubKeys();
    final proof = MoneroTxProof.fromBase58(proofStr);
    if ((additional?.pubKeys.length ?? 0) + 1 != proof.signatures.length) {
      throw const DartMoneroPluginException(
          "Miss matching length of proof and tx pub keys.");
    }
    final prefixHash =
        _hashProofMessage(transaction: transaction, message: message);
    bool verify = false;
    for (int i = 0; i < proof.signatures.length; i++) {
      final sharedSecret = proof.sharedSecret[i];
      final signature = proof.signatures[i];
      verify |= _checkProof(
          address: address,
          signature: signature,
          txPubKey: i == 0 ? txPubKey : additional!.pubKeys[i - 1],
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
          A: address.pubViewKey.key,
          B: address.pubSpendKey.key,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProof(
        hash: hash,
        R: txPubKey.key,
        A: address.pubViewKey.key,
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
          R: address.pubViewKey.key,
          A: txPubKey.key,
          B: address.pubSpendKey.key,
          d: sharedSecret,
          signature: signature,
          version: version.version);
    }
    return MoneroCrypto.verifyTxProof(
        hash: hash,
        R: address.pubViewKey.key,
        A: txPubKey.key,
        B: null,
        d: sharedSecret,
        signature: signature,
        version: version.version);
  }

  /// decode output amount.
  static MoneroLockedOutput? getLockedOutputs({
    // required MoneroTxout out,
    required int realIndex,
    required MoneroTransaction tx,
    required MoneroBaseAccountKeys account,
    // required MoneroAccountIndex index,
  }) {
    if (realIndex >= tx.vout.length) {
      throw const DartMoneroPluginException(
          "Invalid transaction output index.");
    }
    final out = tx.vout[realIndex];
    final outPublicKey = out.target.getPublicKey();
    final additionalPubKeys = tx.getTxAdditionalPubKeys();
    if (outPublicKey == null ||
        additionalPubKeys != null &&
            additionalPubKeys.pubKeys.length != tx.vout.length) {
      return null;
    }
    final viewTag = out.target.getViewTag();

    final List<MoneroPublicKey> publicKeys = [
      tx.getTxExtraPubKey(),
      if (additionalPubKeys != null) additionalPubKeys.pubKeys[realIndex]
    ];
    for (final p in publicKeys) {
      final derivation = inOuttoAccFast(
          viewSecretKey: account.account.privVkey,
          txPubkey: p,
          viewTag: viewTag,
          outIndex: realIndex);
      if (derivation == null) continue;
      for (final index in account.indexes) {
        final pubKey = MoneroCrypto.derivePublicKeyFast(
          derivation: derivation,
          outIndex: realIndex,
          basePublicKey: account.getSpendPublicKey(index),
        );
        if (pubKey == outPublicKey) {
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
        accountindex: unlockedOut.accountIndex,
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
  static MoneroUnlockedOutput? toUnlockOutput({
    required MoneroBaseAccountKeys account,
    required MoneroLockedOutput out,
  }) {
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
        accountindex: out.accountIndex,
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
          output: out.cast<MoneroLockedOutput>(),
          txPubkey: txPubKey,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          globalIndex: globalIndex);
    }
    if (out.type == MoneroOutputType.unlockedMultisig) {
      return MoneroUnlockedMultisigPayment(
          output: out.cast<MoneroUnlockedMultisigOutput>(),
          txPubkey: txPubKey,
          paymentId: paymentId,
          encryptedPaymentid: encryptedPaymentId,
          multisigInfos: multisigInfos!,
          globalIndex: globalIndex);
    }
    return MoneroUnLockedPayment(
        output: out.cast<MoneroUnlockedOutput>(),
        txPubkey: txPubKey,
        paymentId: paymentId,
        encryptedPaymentid: encryptedPaymentId,
        globalIndex: globalIndex);
  }
}
