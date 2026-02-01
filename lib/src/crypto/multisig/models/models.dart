import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/types/types.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

class MultisigLR extends MoneroSerialization {
  final RctKey l;
  final RctKey r;
  MultisigLR({required RctKey l, required RctKey r})
    : l = l.asImmutableBytes,
      r = r.asImmutableBytes;

  factory MultisigLR.fromStruct(Map<String, dynamic> json) {
    return MultisigLR(l: json.asBytes("l"), r: json.asBytes("r"));
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "l"),
      LayoutConst.fixedBlob32(property: "r"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"l": l, "r": r};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class MultisigKLRKI extends MoneroSerialization {
  final RctKey k;
  final RctKey L;
  final RctKey R;
  final RctKey ki;
  factory MultisigKLRKI.fromStruct(Map<String, dynamic> json) {
    return MultisigKLRKI(
      k: json.asBytes("k"),
      L: json.asBytes("L"),
      R: json.asBytes("R"),
      ki: json.asBytes("ki"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "k"),
      LayoutConst.fixedBlob32(property: "L"),
      LayoutConst.fixedBlob32(property: "R"),
      LayoutConst.fixedBlob32(property: "ki"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"k": k, "L": L, "R": R, "ki": ki};
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  MultisigKLRKI({
    required RctKey k,
    required RctKey L,
    required RctKey R,
    required RctKey ki,
  }) : k = k.asImmutableBytes,
       L = L.asImmutableBytes,
       R = R.asImmutableBytes,
       ki = ki.asImmutableBytes;
}

class MoneroMultisigOutputInfo extends MoneroSerialization {
  final MoneroPublicKey signer;
  final List<MultisigLR> lr;
  final List<RctKey> partialKeyImages;

  MoneroMultisigOutputInfo({
    required this.signer,
    required List<MultisigLR> lr,
    required List<RctKey> partialKeyImages,
  }) : lr = lr.immutable,
       partialKeyImages =
           partialKeyImages
               .map(
                 (e) => e.asImmutableBytes.exc(
                   length: 32,
                   operation: "MoneroMultisigOutputInfo",
                   reason: "Invalid key image bytes length.",
                 ),
               )
               .toImutableList;
  factory MoneroMultisigOutputInfo.fromStruct(Map<String, dynamic> json) {
    return MoneroMultisigOutputInfo(
      signer: MoneroPublicKey.fromBytes(json.asBytes("signer")),
      lr: json.asListOfMap("lr")!.map((e) => MultisigLR.fromStruct(e)).toList(),
      partialKeyImages: json.asListBytes("partialKeyImages")!,
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "signer"),
      MoneroLayoutConst.variantVec(MultisigLR.layout(), property: "lr"),
      MoneroLayoutConst.variantVec(
        LayoutConst.fixedBlob32(),
        property: "partialKeyImages",
      ),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "signer": signer.key,
      "lr": lr.map((e) => e.toLayoutStruct()).toList(),
      "partialKeyImages": partialKeyImages,
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class MoneroMultisigInfo extends MoneroSerialization {
  final MoneroMultisigOutputInfo info;
  final List<MoneroPrivateKey> nonces;
  MoneroMultisigInfo({
    required this.info,
    required List<MoneroPrivateKey> nonces,
  }) : nonces = nonces.immutable;
  factory MoneroMultisigInfo.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroMultisigInfo.fromStruct(decode);
  }

  factory MoneroMultisigInfo.fromStruct(Map<String, dynamic> json) {
    return MoneroMultisigInfo(
      info: MoneroMultisigOutputInfo.fromStruct(json.asMap("info")),
      nonces:
          json
              .asListBytes("nonces")!
              .map((e) => MoneroPrivateKey.fromBytes(e))
              .toList(),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroMultisigOutputInfo.layout(property: "info"),
      MoneroLayoutConst.variantVec(
        LayoutConst.fixedBlob32(),
        property: "nonces",
      ),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "info": info.toLayoutStruct(),
      "nonces": nonces.map((e) => e.key).toList(),
    };
  }
}
