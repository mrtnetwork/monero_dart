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
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
import 'package:monero_dart/src/crypto/multisig/utils/multi_sig_kex_utils.dart';
import 'package:monero_dart/src/serialization/layout/constant/const.dart';
import 'package:monero_dart/src/serialization/layout/serialization/serialization.dart';

abstract class MoneroMultisigAccountCore extends MoneroSerialization {
  int _threshold;
  int get threshold => _threshold;
  List<MoneroPublicKey> _signers;
  List<MoneroPublicKey> get signers => _signers.clone();
  final MoneroPrivateKey basePrivateKey;
  final MoneroPublicKey basePublicKey;
  MoneroPrivateKey baseCommonPrivateKey;
  List<MoneroPrivateKey> _multisigPrivateKeys;
  List<MoneroPrivateKey> get multisigPrivateKeys =>
      _multisigPrivateKeys.clone();
  MoneroPrivateKey _commonPrivateKey;
  MoneroPrivateKey get commonPrivateKey => _commonPrivateKey;
  MoneroPublicKey _multisigPubKey;

  /// same at all
  MoneroPublicKey get multisigPubKey => _multisigPubKey;
  MoneroPublicKey get multisigSignerPubKey => basePublicKey;
  MoneroPublicKey _commonPubKey;
  MoneroPublicKey get commonPubKey => _commonPubKey;
  int _kexRoundsComplete;
  int get kexRoundsComplete => _kexRoundsComplete;
  MultisigKexMessageSerializable _nextRoundKexMessage;
  Map<MoneroPublicKey, Set<MoneroPublicKey>> _kexKeysInMap;
  MultisigKexMessageSerializable get nextRoundKexMessage =>
      _nextRoundKexMessage;
  @override
  Map<String, dynamic> toLayoutStruct() {
    final message = nextRoundKexMessage.toBase58();
    return {
      "threshold": threshold,
      "kex_rounds_complete": kexRoundsComplete,
      "signers": signers.map((e) => e.key).toList(),
      "base_private_key": basePrivateKey.key,
      "base_public_key": basePublicKey.key,
      "base_common_private_key": baseCommonPrivateKey.key,
      "multisig_private_keys": multisigPrivateKeys.map((e) => e.key).toList(),
      "common_private_key": commonPrivateKey.key,
      "multisig_pub_key": multisigPubKey.key,
      "common_pub_key": commonPubKey.key,
      "kex_round_message": message,
      "kex_keys": _kexKeysInMap.map((k, v) =>
          MapEntry<List<int>, List<List<int>>>(
              k.key, v.map((e) => e.key).toList()))
    };
  }

  static Layout<Map<String, dynamic>> layout({String? property}) {
    return LayoutConst.struct([
      MoneroLayoutConst.varintInt(property: "threshold"),
      MoneroLayoutConst.varintInt(property: "kex_rounds_complete"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "signers"),
      LayoutConst.fixedBlob32(property: "base_private_key"),
      LayoutConst.fixedBlob32(property: "base_public_key"),
      LayoutConst.fixedBlob32(property: "base_common_private_key"),
      MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32(),
          property: "multisig_private_keys"),
      LayoutConst.fixedBlob32(property: "common_private_key"),
      LayoutConst.fixedBlob32(property: "multisig_pub_key"),
      LayoutConst.fixedBlob32(property: "common_pub_key"),
      MoneroLayoutConst.variantString(property: "kex_round_message"),
      MoneroLayoutConst.map(
          keyLayout: LayoutConst.fixedBlob32(),
          valueLayout: MoneroLayoutConst.variantVec(LayoutConst.fixedBlob32()),
          property: "kex_keys"),
    ], property: property);
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property);
  }

  MoneroMultisigAccountCore(
      {required int threshold,
      required List<MoneroPublicKey> signers,
      required this.basePrivateKey,
      required this.basePublicKey,
      required this.baseCommonPrivateKey,
      required List<MoneroPrivateKey> multisigPrivateKeys,
      required MoneroPrivateKey commonPrivateKey,
      required MoneroPublicKey multisigPubKey,
      required MoneroPublicKey commonPubKey,
      required int kexRoundsComplete,
      required MultisigKexMessageSerializable nextRoundKexMessage,
      required Map<MoneroPublicKey, Set<MoneroPublicKey>> kexKeysToOriginsMap})
      : _signers = signers.clone(),
        _multisigPrivateKeys = multisigPrivateKeys.clone(),
        _commonPrivateKey = commonPrivateKey,
        _multisigPubKey = multisigPubKey,
        _commonPubKey = commonPubKey,
        _kexRoundsComplete = kexRoundsComplete,
        _nextRoundKexMessage = nextRoundKexMessage,
        _threshold = threshold,
        _kexKeysInMap = {
          for (final i in kexKeysToOriginsMap.entries) i.key: i.value.clone()
        };

  void _initializeKexUpdate(
      List<MultisigKexMessage> expandedMsgs, int kexRoundsRequired) {
    // Initialization is only needed during the first round
    if (_kexRoundsComplete > 0) return;

    // The first round of kex msgs will contain each participant's base pubkeys and ancillary privkeys, so we prepare them here

    // Collect participants' base common privkey shares
    // Note: Duplicate privkeys are acceptable, and duplicates due to duplicate signers
    //       will be blocked by duplicate-signer errors after this function is called
    final List<MoneroPrivateKey> participantBaseCommonPrivkeys = [];
    // Add local ancillary base privkey
    participantBaseCommonPrivkeys.add(baseCommonPrivateKey);

    // Add other signers' base common privkeys
    for (final MultisigKexMessage expandedMsg in expandedMsgs) {
      if (expandedMsg.signingPubKey != basePublicKey) {
        participantBaseCommonPrivkeys.add(expandedMsg.messagePrivateKey!);
      }
    }
    _commonPrivateKey = MoneroMultisigKexUtils.makeMultisigCommonPrivkey(
        participantBaseCommonPrivkeys);

    // Set common pubkey
    _commonPubKey = _commonPrivateKey.publicKey;

    // If N-of-N, then the base privkey will be used directly to make the account's share of the final key
    if (kexRoundsRequired == 1) {
      _multisigPrivateKeys.clear();
    }
  }

  void _finalizeKexUpdate(int kexRoundsRequired,
      Map<MoneroPublicKey, Set<MoneroPublicKey>> resultKeysToOriginsMap) {
    List<MoneroPublicKey> nextMsgKeys = [];

    if (_kexRoundsComplete == kexRoundsRequired) {
      // Post-KEX Verification
      if (!resultKeysToOriginsMap.containsKey(_multisigPubKey)) {
        throw const MoneroMultisigAccountException(
            "Multisig post-kex round: expected multisig pubkey not found.");
      }
      if (!resultKeysToOriginsMap.containsKey(_commonPubKey)) {
        throw const MoneroMultisigAccountException(
            "Multisig post-kex round: expected common pubkey not found.");
      }

      nextMsgKeys.add(_multisigPubKey);
      nextMsgKeys.add(_commonPubKey);
    } else if (_kexRoundsComplete + 1 == kexRoundsRequired) {
      // Final Key Aggregation
      final List<MoneroPublicKey> resultKeys =
          resultKeysToOriginsMap.keys.toList();
      final aggregateKey = MoneroMultisigKexUtils.generateMultisigAggregateKey(
          resultKeys, _multisigPrivateKeys);
      _multisigPubKey = aggregateKey.item1;
      _multisigPrivateKeys = aggregateKey.item2;
      // Reset mapping for the next round
      _kexKeysInMap.clear();

      nextMsgKeys.add(_multisigPubKey);
      nextMsgKeys.add(_commonPubKey);
    } else if (_kexRoundsComplete + 2 == kexRoundsRequired) {
      // Derivation of Private Keys for Next Round
      _multisigPrivateKeys.clear();
      _kexKeysInMap.clear();
      nextMsgKeys.clear();
      for (final derivationAndOrigins in resultKeysToOriginsMap.entries) {
        final derivedPubkey =
            MoneroMultisigKexUtils.calculateMultisigKeypairFromDerivation(
                derivationAndOrigins.key.key);
        _multisigPrivateKeys.add(derivedPubkey.item1);
        _kexKeysInMap[derivedPubkey.item2] = derivationAndOrigins.value.toSet();
        nextMsgKeys.add(derivedPubkey.item2);
      }
    } else {
      // Intermediate Round (Pass Keys to Other Participants)
      nextMsgKeys = resultKeysToOriginsMap.keys.toList();
      _kexKeysInMap = resultKeysToOriginsMap.clone();
    }

    // Update the round counter
    _kexRoundsComplete++;

    // Prepare the next round KEX message (or finalize if KEX is complete)
    _nextRoundKexMessage = MultisigKexMessage.generate(
      round: (_kexRoundsComplete > kexRoundsRequired
              ? kexRoundsRequired
              : _kexRoundsComplete) +
          1,
      signingPrivateKey: basePrivateKey,
      msgPubKeys: nextMsgKeys,
    ).message;
  }

  void _kexUpdateImpl(
      List<MultisigKexMessage> expandedMsgs, bool incompleteSignerSet) {
    // Check if the messages are for the expected KEX round
    MoneroMultisigKexUtils.checkMessagesRound(
        expandedMsgs, _kexRoundsComplete + 1);

    // Calculate the number of required KEX rounds
    final int kexRoundsRequired =
        MoneroMultisigKexUtils.multisigKexRoundsRequired(
            _signers.length, threshold);

    if (kexRoundsRequired <= 0) {
      throw const MoneroMultisigAccountException(
          'Multisig kex rounds required unexpectedly 0.');
    }

    if (_kexRoundsComplete >= kexRoundsRequired + 1) {
      throw const MoneroMultisigAccountException(
          'Multisig kex has already completed all required rounds (including post-kex verification).');
    }

    // Initialize account update
    _initializeKexUpdate(expandedMsgs, kexRoundsRequired);

    // Process messages into a map of pubkey to origins
    final excludePubKeys = MoneroMultisigKexUtils.getKexExcludePubkeys(
        kexRoundsComplete: kexRoundsComplete,
        basePublicKey: basePublicKey,
        kexKeys: _kexKeysInMap.keys.toSet());
    final resultKeysToOriginsMap =
        MoneroMultisigKexUtils.multisigKexProcessRoundMsgs(
            basePrivateKey,
            basePublicKey,
            _kexRoundsComplete + 1,
            threshold,
            _signers,
            expandedMsgs,
            excludePubKeys,
            incompleteSignerSet);

    // Finalize account update
    _finalizeKexUpdate(kexRoundsRequired, resultKeysToOriginsMap);
  }

  bool get accountIsActive {
    return _kexRoundsComplete > 0;
  }

  bool get mainKexRoundsDone {
    if (accountIsActive) {
      return kexRoundsComplete >=
          MoneroMultisigKexUtils.multisigKexRoundsRequired(
              _signers.length, _threshold);
    } else {
      return false;
    }
  }

  bool get multisigIsReady {
    if (mainKexRoundsDone) {
      return kexRoundsComplete >=
          MoneroMultisigKexUtils.multisigSetupRoundsRequired(
              _signers.length, threshold);
    }
    return false;
  }

  void initializeKex(int threshold, List<MoneroPublicKey> signers,
      List<MultisigKexMessage> messages) {
    if (accountIsActive) {
      throw const MoneroCryptoException(
          "multisig account: tried to initialize kex, but already initialized.");
    }
    _signers = MoneroMultisigKexUtils.validateConfig(
        threshold: threshold, signers: signers, basePublicKey: basePublicKey);
    _threshold = threshold;
    _kexUpdateImpl(messages, false);
  }

  void kexUpdate(List<MultisigKexMessage> expandedMessages,
      {bool forceUpdate = false}) {
    if (!accountIsActive) {
      throw const MoneroCryptoException(
          "multisig account: tried to update kex, but kex isn't initialized yet.");
    }
    if (multisigIsReady) {
      throw const MoneroCryptoException(
          "multisig account: tried to update kex, but kex is already complete.");
    }
    _kexUpdateImpl(expandedMessages, forceUpdate);
  }
}
