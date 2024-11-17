import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/address/address/address.dart';
import 'package:monero_dart/src/api/models/models.dart';
import 'package:monero_dart/src/crypto/models/ec_signature.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:monero_dart/src/crypto/ringct/utils/generator.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/models/transaction/signature/signature.dart';
import 'package:monero_dart/src/models/transaction/transaction/output.dart';
import 'package:monero_dart/src/models/transaction/transaction/extra.dart';
import 'package:monero_dart/src/models/transaction/transaction/transaction.dart';
import 'package:monero_dart/src/network/config.dart';

class MoneroTransactionHelper {
  static final BigRational _trxDecimal = BigRational(BigInt.from(10).pow(12));

  /// Converts a string amount to SUN (smallest unit in Tron).
  static BigInt toXMR(String amount) {
    final parse = BigRational.parseDecimal(amount);
    return (parse * _trxDecimal).toBigInt();
  }

  /// Converts a bigint sun to trx with decimal.
  static String fromXMR(BigInt amount) {
    final parse = BigRational(amount);
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

  static RctKey? inOuttoAcc({
    required MoneroPrivateKey viewSecretKey,
    required MoneroPublicKey publicSpendKey,
    required MoneroPublicKey txPubkey,
    required MoneroPublicKey outPublicKey,
    required int outIndex,
    required int? viewTag,
  }) {
    final derivation = MoneroCrypto.generateKeyDerivationFast(
            pubkey: txPubkey, secretKey: viewSecretKey)
        .asImmutableBytes;
    if (hasSameViewTag(
        viewTag: viewTag, derivation: derivation, outIndex: outIndex)) {
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
}

class MoneroTxVersion {
  final String name;
  final int version;
  const MoneroTxVersion._({required this.name, this.version = 1});
  static const MoneroTxVersion v1In = MoneroTxVersion._(name: "InProofV1");
  static const MoneroTxVersion v1Out = MoneroTxVersion._(name: "OutProofV1");
  static const MoneroTxVersion v2In =
      MoneroTxVersion._(name: "InProofV2", version: 2);
  static const MoneroTxVersion v2Out =
      MoneroTxVersion._(name: "OutProofV2", version: 2);
  static const List<MoneroTxVersion> values = [v1In, v1Out, v2In, v2Out];
  static MoneroTxVersion fromBase58(String proof) {
    return values.firstWhere(
      (e) => proof.startsWith(e.name),
      orElse: () => throw DartMoneroPluginException("Invalid proof version.",
          details: {"proof": proof}),
    );
  }

  bool get isOut =>
      this == MoneroTxVersion.v1Out || this == MoneroTxVersion.v2Out;
}

class MoneroTxProof {
  final MoneroTxVersion version;
  static const int lenght = 96;
  final List<MoneroPublicKey> sharedSecret;
  final List<MECSignature> signatures;
  factory MoneroTxProof(
      {required List<MoneroPublicKey> sharedSecret,
      required List<MECSignature> signatures,
      required MoneroTxVersion version}) {
    if (sharedSecret.isEmpty || sharedSecret.length != signatures.length) {
      throw const DartMoneroPluginException("Invalid proof data provided.");
    }
    return MoneroTxProof._(
        sharedSecret: sharedSecret, signatures: signatures, version: version);
  }
  MoneroTxProof._(
      {required List<MoneroPublicKey> sharedSecret,
      required List<MECSignature> signatures,
      required this.version})
      : sharedSecret = sharedSecret.toImutableList,
        signatures = signatures.toImutableList;
  factory MoneroTxProof.fromBase58(String proof) {
    try {
      final version = MoneroTxVersion.fromBase58(proof);
      final b58 = proof.substring(version.name.length);
      final decode = Base58XmrDecoder.decode(b58);
      if (decode.length < lenght || decode.length % lenght != 0) {
        throw DartMoneroPluginException("Invalid proof data.",
            details: {"proof": proof});
      }
      final List<MoneroPublicKey> sharedSecret = [];
      final List<MECSignature> signatures = [];
      final sigLen = decode.length ~/ lenght;
      for (int i = 0; i < sigLen; i++) {
        final int start = lenght * i;
        final part = decode.sublist(start, start + lenght);
        sharedSecret.add(MoneroPublicKey.fromBytes(part.sublist(0, 32)));
        signatures.add(MECSignature.fromBytes(part.sublist(32)));
      }
      return MoneroTxProof._(
          sharedSecret: sharedSecret, signatures: signatures, version: version);
    } on DartMoneroPluginException {
      rethrow;
    } catch (e) {
      throw DartMoneroPluginException("Invalid proof data.",
          details: {"proof": proof});
    }
  }

  String toBase58() {
    String result = MoneroConst.proofOutV2Prefix;
    for (int i = 0; i < signatures.length; i++) {
      result += Base58XmrEncoder.encode(sharedSecret[i].key);
      result += Base58XmrEncoder.encode(signatures[i].toBytes());
    }
    return result;
  }
}
