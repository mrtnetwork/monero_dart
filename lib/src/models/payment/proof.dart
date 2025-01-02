import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/crypto.dart';
import 'package:monero_dart/src/exception/exception.dart';

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
    String result = version.name;
    for (int i = 0; i < signatures.length; i++) {
      result += Base58XmrEncoder.encode(sharedSecret[i].key);
      result += Base58XmrEncoder.encode(signatures[i].toBytes());
    }
    return result;
  }
}
