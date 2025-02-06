import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/exception/exception.dart';
import 'package:monero_dart/src/helper/extension.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

import 'signature.dart';

abstract class RctSigPrunable extends MoneroSerialization {
  const RctSigPrunable();
  abstract final List<RctKey> pseudoOuts;
  factory RctSigPrunable.fromStruct(Map<String, dynamic> json, RCTType type) {
    switch (type) {
      case RCTType.rctTypeBulletproofPlus:
        return RctSigPrunableBulletproofPlus.fromStruct(json);
      case RCTType.rctTypeBulletproof:
        return RctSigPrunableBulletproof.fromStruct(json);
      case RCTType.rctTypeBulletproof2:
        return RctSigPrunableBulletproof2.fromStruct(json);
      case RCTType.rctTypeCLSAG:
        return RctSigPrunableCLSAG.fromStruct(json);
      case RCTType.rctTypeSimple:
      case RCTType.rctTypeFull:
        return RctSigPrunableRangeSigs.fromStruct(json);
      default:
        throw DartMoneroPluginException("Invalid RCT type.",
            details: {"type": type.toString()});
    }
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property,
      required RCTType type,
      required int outputLength,
      required int inputLength,
      required int mixinLength}) {
    switch (type) {
      case RCTType.rctTypeNull:
        return LayoutConst.noArgs(property: property);
      case RCTType.rctTypeBulletproofPlus:
        return RctSigPrunableBulletproofPlus.layout(
            inputLength: inputLength,
            mixinLength: mixinLength,
            property: property);
      case RCTType.rctTypeBulletproof:
        return RctSigPrunableBulletproof.layout(
            inputLength: inputLength,
            mixinLength: mixinLength,
            property: property);
      case RCTType.rctTypeBulletproof2:
        return RctSigPrunableBulletproof2.layout(
            inputLength: inputLength,
            mixinLength: mixinLength,
            property: property);
      case RCTType.rctTypeCLSAG:
        return RctSigPrunableCLSAG.layout(
            inputLength: inputLength,
            mixinLength: mixinLength,
            property: property);
      case RCTType.rctTypeSimple:
      case RCTType.rctTypeFull:
        return RctSigPrunableRangeSigs.layout(
            outputLength: outputLength,
            mixinLength: mixinLength,
            type: type,
            inputLength: inputLength,
            property: property);
      default:
        throw DartMoneroPluginException("Invalid RCT type.",
            details: {"type": type.toString()});
    }
  }

  T cast<T extends RctSigPrunable>() {
    if (this is! T) {
      throw DartMoneroPluginException("RctSigPrunable casting failed.",
          details: {"expected": "$T", "type": runtimeType.toString()});
    }
    return this as T;
  }
}

abstract class ClsagPrunable extends RctSigPrunable {
  const ClsagPrunable();
  abstract final List<Clsag> clsag;
  ClsagPrunable copyWith({List<Clsag>? clsag});
}

abstract class MgSigPrunable extends RctSigPrunable {
  const MgSigPrunable();
  abstract final List<MgSig> mgs;
}

class BulletproofPlus extends MoneroSerialization {
  final List<RctKey> v;
  final RctKey a;
  final RctKey a1;
  final RctKey b;
  final RctKey r1;
  final RctKey s1;
  final RctKey d1;
  final List<RctKey> l;
  final List<RctKey> r;

  Map<String, dynamic> toJson() {
    return {
      "v": v.map((e) => BytesUtils.toHexString(e)).toList(),
      "a": BytesUtils.toHexString(a),
      "a1": BytesUtils.toHexString(a1),
      "b": BytesUtils.toHexString(b),
      "r1": BytesUtils.toHexString(r1),
      "s1": BytesUtils.toHexString(s1),
      "d1": BytesUtils.toHexString(d1),
      "l": l.map((e) => BytesUtils.toHexString(e)).toList(),
      "r": r.map((e) => BytesUtils.toHexString(e)).toList(),
    };
  }

  factory BulletproofPlus.fromJson(Map<String, dynamic> json) {
    return BulletproofPlus(
      a: BytesUtils.fromHexString(json.as<String>("a")),
      a1: BytesUtils.fromHexString(json.as<String>("a1")),
      b: BytesUtils.fromHexString(json.as<String>("b")),
      r1: BytesUtils.fromHexString(json.as<String>("r1")),
      s1: BytesUtils.fromHexString(json.as<String>("s1")),
      d1: BytesUtils.fromHexString(json.as<String>("d1")),
      l: json.as<List>("l").map((e) => BytesUtils.fromHexString(e)).toList(),
      r: json.as<List>("r").map((e) => BytesUtils.fromHexString(e)).toList(),
      v: json.as<List>("v").map((e) => BytesUtils.fromHexString(e)).toList(),
    );
  }

  BulletproofPlus(
      {required RctKey a,
      required RctKey a1,
      required RctKey b,
      required RctKey r1,
      required RctKey s1,
      required RctKey d1,
      required List<RctKey> l,
      required List<RctKey> r,
      this.v = const []})
      : a = a.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        a1 = a1.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        b = b.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        r1 = r1.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        s1 = s1.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        d1 = d1.asImmutableBytes.exc(32, name: "BulletproofPlus v"),
        l = l
            .map((e) => e.asImmutableBytes.exc(32, name: "BulletproofPlus v"))
            .toList()
            .immutable,
        r = r
            .map((e) => e.asImmutableBytes.exc(32, name: "BulletproofPlus v"))
            .toList()
            .immutable;

  BulletproofPlus copyWith(
      {RctKey? a,
      RctKey? a1,
      RctKey? b,
      RctKey? r1,
      RctKey? s1,
      RctKey? d1,
      List<RctKey>? l,
      List<RctKey>? r,
      KeyV? v}) {
    return BulletproofPlus(
        a: a ?? this.a,
        a1: a1 ?? this.a1,
        b: b ?? this.b,
        r1: r1 ?? this.r1,
        s1: s1 ?? this.s1,
        d1: d1 ?? this.d1,
        l: l ?? this.l,
        r: r ?? this.r,
        v: v ?? this.v);
  }

  factory BulletproofPlus.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return BulletproofPlus.fromStruct(decode);
  }
  factory BulletproofPlus.fromStruct(Map<String, dynamic> json) {
    return BulletproofPlus(
        a: json.asBytes("a"),
        a1: json.asBytes("a1"),
        b: json.asBytes("b"),
        r1: json.asBytes("r1"),
        s1: json.asBytes("s1"),
        d1: json.asBytes("d1"),
        l: json.asListBytes("l")!,
        r: json.asListBytes("r")!);
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "a"),
      LayoutConst.fixedBlob32(property: "a1"),
      LayoutConst.fixedBlob32(property: "b"),
      LayoutConst.fixedBlob32(property: "r1"),
      LayoutConst.fixedBlob32(property: "s1"),
      LayoutConst.fixedBlob32(property: "d1"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "l"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "r"),
    ]);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "a": a,
      "a1": a1,
      "b": b,
      "r1": r1,
      "s1": s1,
      "d1": d1,
      "l": l,
      "r": r
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class Bulletproof extends MoneroSerialization {
  final List<RctKey> v;
  final RctKey a;
  final RctKey s;
  final RctKey t1;
  final RctKey t2;
  final RctKey taux;
  final RctKey mu;
  final List<RctKey> l;
  final List<RctKey> r;
  final RctKey a_;
  final RctKey b;
  final RctKey t;
  Bulletproof({
    required RctKey a,
    required RctKey s,
    required RctKey t1,
    required RctKey t2,
    required RctKey taux,
    required RctKey mu,
    required List<RctKey> l,
    required List<RctKey> r,
    required RctKey a_,
    required RctKey b,
    required RctKey t,
    List<RctKey> v = const [],
  })  : a = a.asImmutableBytes.exc(32, name: "Bulletproof a"),
        s = s.asImmutableBytes.exc(32, name: "Bulletproof s"),
        t1 = t1.asImmutableBytes.exc(32, name: "Bulletproof t1"),
        t2 = t2.asImmutableBytes.exc(32, name: "Bulletproof t2"),
        taux = taux.asImmutableBytes.exc(32, name: "Bulletproof taux"),
        mu = mu.asImmutableBytes.exc(32, name: "Bulletproof v"),
        l = l
            .map((e) => e.asImmutableBytes.exc(32, name: "Bulletproof v"))
            .toList()
            .immutable,
        r = r
            .map((e) => e.asImmutableBytes.exc(32, name: "Bulletproof v"))
            .toList()
            .immutable,
        a_ = a_.asImmutableBytes.exc(32, name: "Bulletproof a_"),
        b = b.asImmutableBytes.exc(32, name: "Bulletproof b"),
        t = t.asImmutableBytes.exc(32, name: "Bulletproof v"),
        v = v
            .map((e) => e.asImmutableBytes.exc(32, name: "Bulletproof v"))
            .toList()
            .immutable;

  Bulletproof copyWith(
      {RctKey? a,
      RctKey? s,
      RctKey? t1,
      RctKey? t2,
      RctKey? taux,
      RctKey? mu,
      List<RctKey>? l,
      List<RctKey>? r,
      RctKey? a_,
      RctKey? b,
      RctKey? t,
      KeyV? v}) {
    return Bulletproof(
        a: a ?? this.a,
        s: s ?? this.s,
        t1: t1 ?? this.t1,
        t2: t2 ?? this.t2,
        taux: taux ?? this.taux,
        mu: mu ?? this.mu,
        l: l ?? this.l,
        r: r ?? this.r,
        a_: a_ ?? this.a_,
        b: b ?? this.b,
        t: t ?? this.t,
        v: v ?? this.v);
  }

  factory Bulletproof.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
        bytes: bytes, layout: layout(property: property));
    return Bulletproof.fromStruct(decode);
  }
  factory Bulletproof.fromStruct(Map<String, dynamic> json) {
    return Bulletproof(
      a: json.asBytes("a"),
      s: json.asBytes("s"),
      t1: json.asBytes("t1"),
      t2: json.asBytes("t2"),
      taux: json.asBytes("taux"),
      mu: json.asBytes("mu"),
      l: json.asListBytes("l")!,
      r: json.asListBytes("r")!,
      a_: json.asBytes("a_"),
      b: json.asBytes("b"),
      t: json.asBytes("t"),
    );
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.fixedBlob32(property: "a"),
      LayoutConst.fixedBlob32(property: "s"),
      LayoutConst.fixedBlob32(property: "t1"),
      LayoutConst.fixedBlob32(property: "t2"),
      LayoutConst.fixedBlob32(property: "taux"),
      LayoutConst.fixedBlob32(property: "mu"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "l"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(), property: "r"),
      LayoutConst.fixedBlob32(property: "a_"),
      LayoutConst.fixedBlob32(property: "b"),
      LayoutConst.fixedBlob32(property: "t"),
    ]);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "a": a,
      "s": s,
      "t1": t1,
      "t2": t2,
      "taux": taux,
      "mu": mu,
      "l": l,
      "r": r,
      "a_": a_,
      "b": b,
      "t": t,
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }
}

class Clsag extends MoneroSerialization {
  final List<RctKey> s;
  final RctKey c1;
  final RctKey d;
  final RctKey? i;
  Clsag(
      {required List<RctKey> s,
      required RctKey c1,
      required RctKey d,
      RctKey? i})
      : s = s
            .map((e) => e.asImmutableBytes.exc(32, name: "Clsag s"))
            .toList()
            .immutable,
        c1 = c1.asImmutableBytes,
        d = d.asImmutableBytes,
        i = i?.asImmutableBytes;
  factory Clsag.fromStruct(Map<String, dynamic> json) {
    return Clsag(
        s: json.asListBytes("s")!,
        c1: json.asBytes("c1"),
        d: json.asBytes("d"));
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int mixinLength}) {
    return LayoutConst.struct([
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(mixinLength),
          property: "s"),
      LayoutConst.fixedBlob32(property: "c1"),
      LayoutConst.fixedBlob32(property: "d")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout(
      {String? property, int mixinLength = 0}) {
    return layout(property: property, mixinLength: mixinLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"s": s, "c1": c1, "d": d};
  }
}

class RctSigPrunableBulletproofPlus extends ClsagPrunable {
  final List<BulletproofPlus> bulletproofPlus;
  @override
  final List<Clsag> clsag;
  int get bpp => bulletproofPlus.length;
  @override
  final List<RctKey> pseudoOuts;
  RctSigPrunableBulletproofPlus(
      {required List<BulletproofPlus> bulletproofPlus,
      required List<Clsag> clsag,
      required List<RctKey> pseudoOuts})
      : bulletproofPlus = bulletproofPlus.immutable,
        pseudoOuts =
            pseudoOuts.map((e) => e.asImmutableBytes).toList().immutable,
        clsag = clsag.immutable;

  factory RctSigPrunableBulletproofPlus.fromStruct(Map<String, dynamic> json) {
    return RctSigPrunableBulletproofPlus(
        clsag:
            json.asListOfMap("clsag")!.map((e) => Clsag.fromStruct(e)).toList(),
        bulletproofPlus: json
            .asListOfMap("bulletproofPlus")!
            .map((e) => BulletproofPlus.fromStruct(e))
            .toList(),
        pseudoOuts: json.asListBytes("pseudoOuts")!);
  }
  static Layout<Map<String, dynamic>> layout({
    String? property,
    required int inputLength,
    required int mixinLength,
  }) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(BulletproofPlus.layout(),
          property: "bulletproofPlus"),
      LayoutConst.seq(Clsag.layout(mixinLength: mixinLength),
          LayoutConst.constant(inputLength),
          property: "clsag"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(inputLength),
          property: "pseudoOuts"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({
    String? property,
    int inputLength = 0,
    int mixinLength = 0,
  }) {
    return layout(
        property: property, inputLength: inputLength, mixinLength: mixinLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "bulletproofPlus":
          bulletproofPlus.map((e) => e.toLayoutStruct()).toList(),
      "clsag": clsag.map((e) => e.toLayoutStruct()).toList(),
      "pseudoOuts": pseudoOuts
    };
  }

  @override
  RctSigPrunableBulletproofPlus copyWith({List<Clsag>? clsag}) {
    return RctSigPrunableBulletproofPlus(
        bulletproofPlus: bulletproofPlus,
        clsag: clsag ?? this.clsag,
        pseudoOuts: pseudoOuts);
  }
}

class MgSig extends MoneroSerialization {
  final List<List<RctKey>> ss;
  final RctKey cc;
  final KeyV ii;
  MgSig(
      {required List<List<RctKey>> ss, required RctKey cc, KeyV ii = const []})
      : ss = ss
            .map((e) => e
                .map((d) => d.asImmutableBytes.exc(32, name: "Clsag s"))
                .toList()
                .immutable)
            .toList()
            .immutable,
        ii = ii.map((e) => e.asImmutableBytes).toList().immutable,
        cc = cc.asImmutableBytes;
  factory MgSig.fromStruct(Map<String, dynamic> json) {
    return MgSig(ss: json.asListOfListBytes("ss")!, cc: json.as("cc"));
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property,
      required int mixinLength,
      required int ss2ElementLength}) {
    return LayoutConst.struct([
      LayoutConst.seq(
          LayoutConst.seq(
            LayoutConst.fixedBlob32(),
            LayoutConst.constant(ss2ElementLength),
          ),
          LayoutConst.constant(mixinLength),
          property: "ss"),
      LayoutConst.fixedBlob32(property: "cc"),
      // LayoutConst.fixedBlob32(property: "d")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout(
      {String? property, int mixinLength = 0, int ss2ElementLength = 0}) {
    return layout(
        property: property,
        mixinLength: mixinLength,
        ss2ElementLength: ss2ElementLength);
  }

  Map<String, dynamic> toJson() {
    return {
      "ss": ss.map((e) => e.map((d) => BytesUtils.toHexString(d))).toList(),
      "cc": BytesUtils.toHexString(cc),
      "ii": ii.map((e) => BytesUtils.toHexString(e)).toList()
    };
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"ss": ss, "cc": cc};
  }
}

abstract class BulletproofPrunable extends RctSigPrunable {
  const BulletproofPrunable();
  abstract final List<Bulletproof> bulletproof;
}

class RctSigPrunableCLSAG extends BulletproofPrunable implements ClsagPrunable {
  @override
  final List<Bulletproof> bulletproof;
  @override
  final List<Clsag> clsag;
  int get bp => bulletproof.length;
  @override
  final List<RctKey> pseudoOuts;
  @override
  RctSigPrunableCLSAG copyWith({List<Clsag>? clsag}) {
    return RctSigPrunableCLSAG(
        bulletproof: bulletproof,
        clsag: clsag ?? this.clsag,
        pseudoOuts: pseudoOuts);
  }

  RctSigPrunableCLSAG(
      {required List<Bulletproof> bulletproof,
      required List<Clsag> clsag,
      required List<RctKey> pseudoOuts})
      : bulletproof = bulletproof.immutable,
        pseudoOuts =
            pseudoOuts.map((e) => e.asImmutableBytes).toList().immutable,
        clsag = clsag.immutable;

  factory RctSigPrunableCLSAG.fromStruct(Map<String, dynamic> json) {
    return RctSigPrunableCLSAG(
        clsag:
            json.asListOfMap("clsag")!.map((e) => Clsag.fromStruct(e)).toList(),
        bulletproof: json
            .asListOfMap("bulletproof")!
            .map((e) => Bulletproof.fromStruct(e))
            .toList(),
        pseudoOuts: json.asListBytes("pseudoOuts")!);
  }
  static Layout<Map<String, dynamic>> layout({
    String? property,
    required int inputLength,
    required int mixinLength,
  }) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(Bulletproof.layout(),
          property: "bulletproof"),
      LayoutConst.seq(Clsag.layout(mixinLength: mixinLength),
          LayoutConst.constant(inputLength),
          property: "clsag"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(inputLength),
          property: "pseudoOuts"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({
    String? property,
    int inputLength = 0,
    int mixinLength = 0,
  }) {
    return layout(
        property: property, inputLength: inputLength, mixinLength: mixinLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "bulletproof": bulletproof.map((e) => e.toLayoutStruct()).toList(),
      "clsag": clsag.map((e) => e.toLayoutStruct()).toList(),
      "pseudoOuts": pseudoOuts
    };
  }
}

class RctSigPrunableBulletproof2 extends BulletproofPrunable
    implements MgSigPrunable {
  @override
  final List<Bulletproof> bulletproof;
  @override
  final List<MgSig> mgs;
  int get bp => bulletproof.length;
  @override
  final List<RctKey> pseudoOuts;
  RctSigPrunableBulletproof2(
      {required List<Bulletproof> bulletproof,
      required List<RctKey> pseudoOuts,
      required List<MgSig> mgs})
      : bulletproof = bulletproof.immutable,
        mgs = mgs.immutable,
        pseudoOuts =
            pseudoOuts.map((e) => e.asImmutableBytes).toList().immutable;

  factory RctSigPrunableBulletproof2.fromStruct(Map<String, dynamic> json) {
    return RctSigPrunableBulletproof2(
        bulletproof: json
            .asListOfMap("bulletproof")!
            .map((e) => Bulletproof.fromStruct(e))
            .toList(),
        pseudoOuts: json.asListBytes("pseudoOuts")!,
        mgs: json.asListOfMap("mgs")!.map((e) => MgSig.fromStruct(e)).toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int inputLength, required int mixinLength}) {
    return LayoutConst.struct([
      MoneroLayoutConst.variantVec(Bulletproof.layout(),
          property: "bulletproof"),
      LayoutConst.seq(
          MgSig.layout(
              property: "mgs", mixinLength: mixinLength, ss2ElementLength: 2),
          LayoutConst.constant(inputLength),
          property: "mgs"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(inputLength),
          property: "pseudoOuts"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({
    String? property,
    int inputLength = 0,
    int mixinLength = 0,
  }) {
    return layout(
        property: property, inputLength: inputLength, mixinLength: mixinLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "bulletproof": bulletproof.map((e) => e.toLayoutStruct()).toList(),
      "pseudoOuts": pseudoOuts,
      "mgs": mgs.map((e) => e.toLayoutStruct()).toList(),
    };
  }
}

class RctSigPrunableBulletproof extends BulletproofPrunable
    implements MgSigPrunable {
  @override
  final List<Bulletproof> bulletproof;
  int get bp => bulletproof.length;
  @override
  final List<RctKey> pseudoOuts;
  @override
  final List<MgSig> mgs;
  RctSigPrunableBulletproof(
      {required List<Bulletproof> bulletproof,
      required List<RctKey> pseudoOuts,
      required List<MgSig> mgs})
      : bulletproof = bulletproof.immutable,
        mgs = mgs.immutable,
        pseudoOuts =
            pseudoOuts.map((e) => e.asImmutableBytes).toList().immutable;

  factory RctSigPrunableBulletproof.fromStruct(Map<String, dynamic> json) {
    return RctSigPrunableBulletproof(
        bulletproof: json
            .asListOfMap("bulletproof")!
            .map((e) => Bulletproof.fromStruct(e))
            .toList(),
        pseudoOuts: json.asListBytes("pseudoOuts")!,
        mgs: json.asListOfMap("mgs")!.map((e) => MgSig.fromStruct(e)).toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property, required int inputLength, required int mixinLength}) {
    return LayoutConst.struct([
      LayoutConst.vec(Bulletproof.layout(), property: "bulletproof"),
      LayoutConst.seq(
          MgSig.layout(
              property: "mgs", mixinLength: mixinLength, ss2ElementLength: 2),
          LayoutConst.constant(inputLength),
          property: "mgs"),
      LayoutConst.seq(
          LayoutConst.fixedBlob32(), LayoutConst.constant(inputLength),
          property: "pseudoOuts"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({
    String? property,
    int inputLength = 0,
    int mixinLength = 0,
  }) {
    return layout(
        property: property, inputLength: inputLength, mixinLength: mixinLength);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "d": 0,
      "bulletproof": bulletproof.map((e) => e.toLayoutStruct()).toList(),
      "pseudoOuts": pseudoOuts,
      "mgs": mgs.map((e) => e.toLayoutStruct()).toList()
    };
  }
}

class BoroSig extends MoneroSerialization {
  final List<RctKey> s0;
  final List<RctKey> s1;
  final RctKey ee;
  BoroSig(
      {required List<RctKey> s0, required List<RctKey> s1, required RctKey ee})
      : s0 = s0
            .map((e) => e.asImmutableBytes.exc(32, name: "BoroSig s0"))
            .toList()
            .immutable
            .exc(64, name: "BoroSig s0"),
        s1 = s1
            .map((e) => e.asImmutableBytes.exc(32, name: "BoroSig s1"))
            .toList()
            .immutable
            .exc(64, name: "BoroSig s1"),
        ee = ee.asImmutableBytes.exc(32, name: "BoroSig ee");
  factory BoroSig.fromStruct(Map<String, dynamic> json) {
    return BoroSig(
        s0: json.asListBytes("s0")!,
        s1: json.asListBytes("s1")!,
        ee: json.asBytes("ee"));
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      LayoutConst.seq(LayoutConst.fixedBlob32(), LayoutConst.constant(64),
          property: "s0"),
      LayoutConst.seq(LayoutConst.fixedBlob32(), LayoutConst.constant(64),
          property: "s1"),
      LayoutConst.fixedBlob32(property: "ee")
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"s0": s0, "s1": s1, "ee": ee};
  }
}

class RangeSig extends MoneroSerialization {
  final BoroSig asig;
  final List<RctKey> ci;
  RangeSig({required this.asig, required List<RctKey> ci})
      : ci = ci
            .map((e) => e.asImmutableBytes.exc(32, name: "RangeSig ci"))
            .toList()
            .exc(64, name: "RangeSig ci");
  factory RangeSig.fromStruct(Map<String, dynamic> json) {
    return RangeSig(
        asig: BoroSig.fromStruct(json.asMap("asig")),
        ci: json.asListBytes("ci")!);
  }
  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      BoroSig.layout(property: "asig"),
      LayoutConst.seq(LayoutConst.fixedBlob32(), LayoutConst.constant(64),
          property: "ci"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {"asig": asig.toLayoutStruct(), "ci": ci};
  }
}

class RctSigPrunableRangeSigs extends MgSigPrunable {
  final List<RangeSig> rangeSig;
  @override
  final List<MgSig> mgs;
  RctSigPrunableRangeSigs({required List<RangeSig> rangeSig, required this.mgs})
      : rangeSig = rangeSig.immutable;

  factory RctSigPrunableRangeSigs.fromStruct(Map<String, dynamic> json) {
    return RctSigPrunableRangeSigs(
        rangeSig: json
            .asListOfMap("rangeSig")!
            .map((e) => RangeSig.fromStruct(e))
            .toList(),
        mgs: json.asListOfMap("mgs")!.map((e) => MgSig.fromStruct(e)).toList());
  }
  static Layout<Map<String, dynamic>> layout(
      {String? property,
      required int outputLength,
      required int mixinLength,
      required int inputLength,
      required RCTType type}) {
    final mgsLen = type == RCTType.rctTypeSimple ? inputLength : 1;
    final ss2ElementLength =
        type == RCTType.rctTypeSimple ? 2 : inputLength + 1;

    return LayoutConst.struct([
      LayoutConst.seq(RangeSig.layout(), LayoutConst.constant(outputLength),
          property: "rangeSig"),
      LayoutConst.seq(
          MgSig.layout(
              mixinLength: mixinLength, ss2ElementLength: ss2ElementLength),
          LayoutConst.constant(mgsLen),
          property: "mgs"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout(
      {String? property,
      int outputLength = 0,
      int mixinLength = 0,
      int inputLength = 0,
      RCTType type = RCTType.rctTypeSimple}) {
    return layout(
        property: property,
        outputLength: outputLength,
        inputLength: inputLength,
        mixinLength: mixinLength,
        type: type);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "rangeSig": rangeSig.map((e) => e.toLayoutStruct()).toList(),
      "mgs": mgs.map((e) => e.toLayoutStruct()).toList()
    };
  }

  @override
  List<RctKey> get pseudoOuts => [];
}
