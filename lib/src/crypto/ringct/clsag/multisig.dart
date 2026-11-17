// Copyright (c) 2021-2024, The Monero Project
// Copyright (c) 2024, MRTNETWORK (https://github.com/mrtnetwork)

// All rights reserved.

// This software includes portions of the Monero Project's original C/C++ implementation,
// which have been adapted and reimplemented in Dart.

// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// Redistributions of source code must retain the above copyright notice,
// this list of conditions, and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions, and the following disclaimers in the documentation and/or other materials provided with the distribution.
// Neither the name of the copyright holders nor the names of their contributors
// may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:blockchain_utils/blockchain_utils.dart';
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
  final RctKey _wHL;
  final KeyV _wPoints;
  final KeyV _hPoints;

  final int l;
  final KeyV _s;
  final int numAlphaComponents;

  CLSAGContext({
    required this.n,
    required KeyV cParams,
    required this.cParamsLOffset,
    required this.cParamsROffset,
    required KeyV bParams,
    required this.bParamsLOffset,
    required this.bParamsROffset,
    required RctKey muP,
    required RctKey muC,
    required RctKey wHL,
    required KeyV wPoints,
    required KeyV hPoints,
    required this.l,
    required KeyV s,
    required this.numAlphaComponents,
  }) : _cParams = cParams,
       _bParams = bParams,
       _muP = muP,
       _muC = muC,
       _wHL = wHL,
       _wPoints = wPoints,
       _hPoints = hPoints,
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
      throw BuError(DefaultErrorType.invalidArgument, "Invalid P length.");
    }
    final int n = P.length;
    if (cNonzero.length != n) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid cNonzero length.",
      );
    }
    if (s.length != n) {
      throw BuError(DefaultErrorType.invalidArgument, "Invalid s length.");
    }
    if (l < 0 || l >= n) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid signing index l: expected 0 <= l < $n, received $l.",
      );
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
    bParams.addAll(
      List.filled(numAlphaComponents, RCT.zero()),
    ); // Placeholders for L multisig nonces

    cParamsROffset = cParams.length;
    bParamsROffset = bParams.length;
    cParams.add(RCT.zero()); // Placeholder for R
    bParams.addAll(
      List.generate(numAlphaComponents, (_) => RCT.zero()),
    ); // Placeholders for R multisig nonces

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
    muPParams.add(RCT.scalarmultKey(D, RCTConst.invEight));
    muCParams.add(muPParams.last);
    muPParams.add(cOffset);
    muCParams.add(cOffset);

    // Calculate muP and muC
    final RctKey muP = RCT.hashToScalarKeys(muPParams);
    final RctKey muC = RCT.hashToScalarKeys(muCParams);

    // wHL = muP*I + muC*D; W[i] = muP*P[i] + muC*C[i]; H[i] = Hs(P[i]).
    final ed25519 = blockchainUtils.api.ed25519;
    final RctKey wHL = ed25519.mulAdd(muP, I, muC, D);
    final KeyV wPoints = [];
    final KeyV hPoints = [];

    for (int i = 0; i < n; ++i) {
      // final RctKey C = RCT.zero();
      final RctKey C = RCT.subKeys(cNonzero[i], cOffset);
      final RctKey W = ed25519.mulAdd(muP, P[i], muC, C);
      wPoints.add(W);
      hPoints.add(RCT.hashToP3Bytes(P[i]));
    }

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
      wHL: wHL,
      wPoints: wPoints,
      hPoints: hPoints,
      l: l,
      s: s,
      numAlphaComponents: numAlphaComponents,
    );
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
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid alpha G length.",
      );
    }
    if (numAlphaComponents != totalAlphaH.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid alpha H length.",
      );
    }
    if (numAlphaComponents != alpha.length) {
      throw BuError(DefaultErrorType.invalidArgument, "Invalid alpha length.");
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
    alphaCombinedR.setAll(0, List<int>.filled(32, 0));
    for (int i = 0; i < numAlphaComponents; ++i) {
      _cParams[cParamsLOffset] = RCT.addKeys(
        _cParams[cParamsLOffset],
        RCT.scalarmultKey(totalAlphaG[i], bI),
      );
      _cParams[cParamsROffset] = RCT.addKeys(
        _cParams[cParamsROffset],
        RCT.scalarmultKey(totalAlphaH[i], bI),
      );
      alphaCombinedR.setAll(
        0,
        blockchainUtils.api.ed25519.scMulAdd(alpha[i], bI, alphaCombinedR),
      );
      bI.setAll(0, blockchainUtils.api.ed25519.scMul(bI, b));
    }
    c = RCT.hashToScalarKeys(_cParams);
    final gen = blockchainUtils.api.ed25519.generator();
    for (int i = (l + 1) % n; i != l; i = (i + 1) % n) {
      if (i == 0) c0 = c.clone();
      // L = s*G + c*W[i]; R = s*H[i] + c*wHL.
      _cParams[cParamsLOffset] = blockchainUtils.api.ed25519.mulAdd(
        _s[i],
        gen,
        c,
        _wPoints[i],
      );
      _cParams[cParamsROffset] = blockchainUtils.api.ed25519.mulAdd(
        _s[i],
        _hPoints[i],
        c,
        _wHL,
      );
      c = RCT.hashToScalarKeys(_cParams);
    }
    if (l == 0) {
      c0 = c.clone();
    }
    cR.setAll(0, c);
    c0R.setAll(0, c0);
  }

  List<int> get muP => _muP.clone();
  List<int> get muC => _muC.clone();

  (RctKey, RctKey) getMu() {
    return (_muP.clone(), _muC.clone());
  }
}
