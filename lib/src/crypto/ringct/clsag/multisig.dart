import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class CLSAGContext {
  final int n;
  final KeyV _cParams;
  final int cParamsLOffset;
  final int cParamsROffset;

  final KeyV _bParams;
  final int bParamsLOffset;
  final int bParamsROffset;

  final RctKey _muP;
  final RctKey _muC;
  final GroupElementDsmp _wHlprecomp;
  final List<GroupElementDsmp> _wPrecomp;
  final List<GroupElementDsmp> _hPrecomp;
  final GroupElementDsmp _gPrecomp;

  final int l;
  final KeyV _s;
  final int numAlphaComponents;

  CLSAGContext(
      {required this.n,
      required KeyV cParams,
      required this.cParamsLOffset,
      required this.cParamsROffset,
      required KeyV bParams,
      required this.bParamsLOffset,
      required this.bParamsROffset,
      required RctKey muP,
      required RctKey muC,
      required GroupElementDsmp wHlprecomp,
      required List<GroupElementDsmp> wPrecomp,
      required List<GroupElementDsmp> hPrecomp,
      required GroupElementDsmp gPrecomp,
      required this.l,
      required KeyV s,
      required this.numAlphaComponents})
      : _cParams = cParams,
        _bParams = bParams,
        _muP = muP,
        _muC = muC,
        _wHlprecomp = wHlprecomp,
        _wPrecomp = wPrecomp,
        _hPrecomp = hPrecomp,
        _gPrecomp = gPrecomp,
        _s = s;

  factory CLSAGContext.init(
    KeyV P,
    KeyV cNonzero,
    RctKey cOffset,
    RctKey message,
    RctKey I,
    RctKey D,
    int l,
    KeyV s,
    int numAlphaComponents,
  ) {
    // initialized = false;
    if (P.isEmpty) {
      throw const MoneroCryptoException("Invalid P length.");
    }
    final int n = P.length;
    if (cNonzero.length != n) {
      throw const MoneroCryptoException("Invalid cNonzero length.");
    }
    if (s.length != n) {
      throw const MoneroCryptoException("Invalid s length.");
    }
    if (l >= n) {
      throw const MoneroCryptoException("Invalid l length.");
    }
    final KeyV cParams = [];
    final KeyV bParams = [];
    int cParamsLOffset;
    int bParamsLOffset;
    int cParamsROffset;
    int bParamsROffset;

    // Populate cParams and bParams
    cParams.add(RCT.strToKey(RCTConst.cslagHashKeyRound));
    bParams.add(RCT.strToKey(RCTConst.cslagHashKeyRoundMultisig));

    cParams.addAll(P);
    bParams.addAll(P);
    cParams.addAll(cNonzero);
    bParams.addAll(cNonzero);
    cParams.add(cOffset);
    bParams.add(cOffset);
    cParams.add(message);
    bParams.add(message);

    // Set offsets for later insertions
    cParamsLOffset = cParams.length;
    bParamsLOffset = bParams.length;
    cParams.add(RCT.zero()); // Placeholder for L
    bParams.addAll(List.filled(
        numAlphaComponents, RCT.zero())); // Placeholders for L multisig nonces

    cParamsROffset = cParams.length;
    bParamsROffset = bParams.length;
    cParams.add(RCT.zero()); // Placeholder for R
    bParams.addAll(List.generate(numAlphaComponents,
        (_) => RCT.zero())); // Placeholders for R multisig nonces

    // Add I and D
    bParams.add(I);
    bParams.add(D);

    // Insert fake responses before and after `l`
    bParams.addAll(s.sublist(0, l));
    bParams.addAll(s.sublist(l + 1));

    // Add real signing index 'l'
    bParams.add(RCT.d2hInt(l));

    // Add number of parallel nonces
    bParams.add(RCT.d2hInt(numAlphaComponents));

    // Add number of ring members
    bParams.add(RCT.d2hInt(n));

    final KeyV muPParams = [];
    final KeyV muCParams = [];
    muPParams.add(RCT.strToKey(RCTConst.cslagHashKeyAgg0));
    muCParams.add(RCT.strToKey(RCTConst.cslagHashKeyAgg1));

    muPParams.addAll(P);
    muCParams.addAll(P);
    muPParams.addAll(cNonzero);
    muCParams.addAll(cNonzero);
    muPParams.add(I);
    muCParams.add(I);
    muPParams.add(RCT.scalarmultKey_(D, RCTConst.invEight));
    muCParams.add(muPParams.last);
    muPParams.add(cOffset);
    muCParams.add(cOffset);

    // Calculate muP and muC
    final RctKey muP = RCT.hashToScalarKeys(muPParams);
    final RctKey muC = RCT.hashToScalarKeys(muCParams);

    final GroupElementDsmp iPrecomp = GroupElementCached.dsmp;
    final GroupElementDsmp dPrecomp = GroupElementCached.dsmp;
    final GroupElementDsmp wHLprecomp = GroupElementCached.dsmp;
    RCT.precomp(iPrecomp, I);
    RCT.precomp(dPrecomp, D);
    final RctKey wHL = RCT.zero();
    RCT.addKeys3_(wHL, muP, iPrecomp, muC, dPrecomp);
    RCT.precomp(wHLprecomp, wHL);
    final List<GroupElementDsmp> wPrecomp =
        List.generate(n, (i) => GroupElementCached.dsmp);
    final List<GroupElementDsmp> hPrecomp =
        List.generate(n, (i) => GroupElementCached.dsmp);

    for (int i = 0; i < n; ++i) {
      final GroupElementDsmp pPrecomp = GroupElementCached.dsmp;
      final GroupElementDsmp cPrecomp = GroupElementCached.dsmp;
      final RctKey C = RCT.zero();
      RCT.subKeys(C, cNonzero[i], cOffset);
      RCT.precomp(pPrecomp, P[i]);
      RCT.precomp(cPrecomp, C);
      final RctKey W = RCT.zero();
      RCT.addKeys3_(W, muP, pPrecomp, muC, cPrecomp);
      RCT.precomp(wPrecomp[i], W);
      final GroupElementP3 hiP3 = GroupElementP3();
      RCT.hashToP3(hiP3, P[i]);
      CryptoOps.geDsmPrecomp(hPrecomp[i], hiP3);
    }
    final GroupElementDsmp gPrecomp = GroupElementCached.dsmp;
    RCT.precomp(gPrecomp, RCTConst.g);

    return CLSAGContext(
        n: n,
        cParams: cParams,
        cParamsLOffset: cParamsLOffset,
        cParamsROffset: cParamsROffset,
        bParams: bParams,
        bParamsLOffset: bParamsLOffset,
        bParamsROffset: bParamsROffset,
        muP: muP,
        muC: muC,
        wHlprecomp: wHLprecomp,
        wPrecomp: wPrecomp,
        hPrecomp: hPrecomp,
        gPrecomp: gPrecomp,
        l: l,
        s: s,
        numAlphaComponents: numAlphaComponents);
  }

  void combineAlphaAndComputeChallenge({
    required KeyV totalAlphaG,
    required KeyV totalAlphaH,
    required KeyV alpha,
    required RctKey alphaCombinedR,
    required RctKey c0R,
    required RctKey cR,
  }) {
    RctKey c = RCT.zero();
    RctKey c0 = RCT.zero();
    if (numAlphaComponents != totalAlphaG.length) {
      throw const MoneroCryptoException("Invalid alpha G length.");
    }
    if (numAlphaComponents != totalAlphaH.length) {
      throw const MoneroCryptoException("Invalid alpha H length.");
    }
    if (numAlphaComponents != alpha.length) {
      throw const MoneroCryptoException("Invalid alpha length.");
    }
    // insert aggregate public nonces for L and R components
    for (int i = 0; i < numAlphaComponents; ++i) {
      _bParams[bParamsLOffset + i] = totalAlphaG[i];
      _bParams[bParamsROffset + i] = totalAlphaH[i];
    }
    final RctKey b = RCT.hashToScalarKeys(_bParams);
    _cParams[cParamsLOffset] = RCT.identity();
    _cParams[cParamsROffset] = RCT.identity();
    final RctKey bI = RCT.identity();
    CryptoOps.scZero(alphaCombinedR);
    for (int i = 0; i < numAlphaComponents; ++i) {
      RCT.addKeys(_cParams[cParamsLOffset], _cParams[cParamsLOffset],
          RCT.scalarmultKey_(totalAlphaG[i], bI));
      RCT.addKeys(_cParams[cParamsROffset], _cParams[cParamsROffset],
          RCT.scalarmultKey_(totalAlphaH[i], bI));
      CryptoOps.scMulAdd(alphaCombinedR, alpha[i], bI, alphaCombinedR);
      CryptoOps.scMul(bI, bI, b);
    }
    c = RCT.hashToScalarKeys(_cParams);
    for (int i = (l + 1) % n; i != l; i = (i + 1) % n) {
      if (i == 0) c0 = c.clone();
      RCT.addKeys3_(
          _cParams[cParamsLOffset], _s[i], _gPrecomp, c, _wPrecomp[i]);
      RCT.addKeys3_(
          _cParams[cParamsROffset], _s[i], _hPrecomp[i], c, _wHlprecomp);
      c = RCT.hashToScalarKeys(_cParams);
    }
    if (l == 0) {
      c0 = c.clone();
    }
    CryptoOps.scFill(cR, c);
    CryptoOps.scFill(c0R, c0);
  }

  List<int> get muP => _muP.clone();
  List<int> get muC => _muC.clone();

  Tuple<RctKey, RctKey> getMu() {
    return Tuple(_muP.clone(), _muC.clone());
  }
}
