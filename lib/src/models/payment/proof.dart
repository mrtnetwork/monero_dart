import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';

class MoneroTxVersion {
  final String name;
  final int version;
  const MoneroTxVersion._({required this.name, this.version = 1});
  static const MoneroTxVersion v1In = MoneroTxVersion._(name: "InProofV1");
  static const MoneroTxVersion v1Out = MoneroTxVersion._(name: "OutProofV1");
  static const MoneroTxVersion v2In = MoneroTxVersion._(
    name: "InProofV2",
    version: 2,
  );
  static const MoneroTxVersion v2Out = MoneroTxVersion._(
    name: "OutProofV2",
    version: 2,
  );
  static const List<MoneroTxVersion> values = [v1In, v1Out, v2In, v2Out];
  // static MoneroTxVersion? fromBase58(String proof) {
  //   return
  // }

  bool get isOut =>
      this == MoneroTxVersion.v1Out || this == MoneroTxVersion.v2Out;
}

class MoneroTxProof {
  final MoneroTxVersion version;
  static const int lenght = 96;
  final List<MoneroPublicKey> sharedSecret;
  final List<MECSignature> signatures;
  static bool isValidProof(String base58) {
    final version = MoneroTxVersion.values.firstWhereNullable(
      (e) => base58.startsWith(e.name),
    );
    if (version == null) return false;
    final b58 = base58.substring(version.name.length);
    if (b58.length < lenght) return false;
    try {
      final decoded = Base58XmrDecoder.decode(
        base58.substring(version.name.length),
      );

      return _decodeProof(decoded, version) != null;
    } catch (_) {
      return false;
    }
  }

  factory MoneroTxProof({
    required List<MoneroPublicKey> sharedSecret,
    required List<MECSignature> signatures,
    required MoneroTxVersion version,
  }) {
    if (sharedSecret.isEmpty || sharedSecret.length != signatures.length) {
      throw const DartMoneroPluginException("Invalid proof data provided.");
    }
    return MoneroTxProof._(
      sharedSecret: sharedSecret,
      signatures: signatures,
      version: version,
    );
  }
  MoneroTxProof._({
    required List<MoneroPublicKey> sharedSecret,
    required List<MECSignature> signatures,
    required this.version,
  }) : sharedSecret = sharedSecret.toImutableList,
       signatures = signatures.toImutableList;

  static MoneroTxProof? _decodeProof(
    List<int> proofBytes,
    MoneroTxVersion version,
  ) {
    try {
      if (proofBytes.length < lenght || proofBytes.length % lenght != 0) {
        return null;
      }
      final List<MoneroPublicKey> sharedSecret = [];
      final List<MECSignature> signatures = [];
      final sigLen = proofBytes.length ~/ lenght;
      for (int i = 0; i < sigLen; i++) {
        final int start = lenght * i;
        final part = proofBytes.sublist(start, start + lenght);
        sharedSecret.add(MoneroPublicKey.fromBytes(part.sublist(0, 32)));
        signatures.add(MECSignature.fromBytes(part.sublist(32)));
      }
      return MoneroTxProof._(
        sharedSecret: sharedSecret,
        signatures: signatures,
        version: version,
      );
    } catch (e) {
      return null;
    }
  }

  factory MoneroTxProof.fromBase58(String proof) {
    try {
      final version = MoneroTxVersion.values.firstWhereNullable(
        (e) => proof.startsWith(e.name),
      );
      if (version == null) {
        throw DartMoneroPluginException(
          "Invalid proof data.",
          details: {"proof": proof},
        );
      }

      final b58 = proof.substring(version.name.length);
      final proofBytes = Base58XmrDecoder.decode(b58);

      final decodeProof = _decodeProof(proofBytes, version);
      if (decodeProof == null) {
        throw DartMoneroPluginException(
          "Invalid proof data.",
          details: {"proof": proof},
        );
      }
      return decodeProof;
    } on BaseDartMoneroPluginException {
      rethrow;
    } catch (e) {
      throw DartMoneroPluginException(
        "Invalid proof data.",
        details: {"proof": proof},
      );
    }
  }

  String toBase58() {
    String result = version.name;
    for (int i = 0; i < signatures.length; i++) {
      result += Base58XmrEncoder.encode(sharedSecret[i].key);
      result += Base58XmrEncoder.encode(signatures[i].toBytes());
    }
    return result;
  }
}
