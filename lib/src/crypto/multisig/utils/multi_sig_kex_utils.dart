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

import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/const/const.dart';
import 'package:monero_dart/src/crypto/multisig/exception/exception.dart';
import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class MoneroMultisigKexUtils {
  static List<MoneroPublicKey> getKexExcludePubkeys(
      {required int kexRoundsComplete,
      required MoneroPublicKey basePublicKey,
      required Set<MoneroPublicKey> kexKeys}) {
    if (kexRoundsComplete == 0) {
      return [basePublicKey];
    } else {
      return kexKeys.toList();
    }
  }

  static List<int> generateMessageHash(
      {required MoneroPrivateKey? msgPrivateKey,
      required MoneroPublicKey signingPubKey,
      required List<MoneroPublicKey> msgPubKeys,
      required int round}) {
    List<int> hashKey;
    List<int> keyBytes;
    if (round == 1) {
      hashKey = MoneroMultisigConst.multisigKexMsgV2Magic1.codeUnits;
      keyBytes = msgPrivateKey!.key;
    } else {
      hashKey = MoneroMultisigConst.multisigKexMsgV2MagicN.codeUnits;
      keyBytes = msgPubKeys.expand((e) => e.key).toList();
    }
    final roundBytes =
        IntUtils.toBytes(round, length: 4, byteOrder: Endian.little);

    return QuickCrypto.keccack256Hash(
        [...hashKey, ...roundBytes, ...signingPubKey.key, ...keyBytes]);
  }

  static List<MoneroPublicKey> validateConfig(
      {required int threshold,
      required List<MoneroPublicKey> signers,
      required MoneroPublicKey basePublicKey}) {
    if (threshold <= 0 || threshold > signers.length) {
      throw const MoneroMultisigAccountException(
          'Multisig account: tried to set invalid threshold.');
    }
    if (signers.length < 2 || signers.length > 10) {
      throw const MoneroMultisigAccountException(
          'Multisig account: tried to set invalid number of signers.');
    }

    if (!signers.contains(basePublicKey)) {
      throw const MoneroMultisigAccountException(
          'Multisig account: tried to set signers, but did not find the account\'s base pubkey in signer list.');
    }

    signers.sort((a, b) => BytesUtils.compareBytes(a.key, b.key));

    if (signers.toSet().length != signers.length) {
      throw const MoneroMultisigAccountException(
          'Multisig account: tried to set signers, but there are duplicate signers unexpectedly.');
    }
    return signers.clone();
  }

  static void checkMultisigConfig(int round, int threshold, int numSigners) {
    if (numSigners <= 1) {
      throw const MoneroMultisigAccountException(
          "Must be at least one other multisig signer.");
    }
    if (numSigners > MoneroMultisigConst.multisigMaxSigners) {
      throw const MoneroMultisigAccountException(
          "Too many multisig signers specified (limit = 16 to prevent dangerous combinatorial explosion during key exchange).");
    }
    if (numSigners < threshold) {
      throw const MoneroMultisigAccountException(
          "Multisig threshold may not be larger than number of signers.");
    }
    if (threshold <= 0) {
      throw const MoneroMultisigAccountException(
          "Multisig threshold must be > 0.");
    }
    if (round <= 0) {
      throw const MoneroMultisigAccountException(
          "Multisig kex round must be > 0.");
    }
    if (round > multisigSetupRoundsRequired(numSigners, threshold)) {
      throw const MoneroMultisigAccountException(
          "Trying to process multisig kex for an invalid round.");
    }
  }

  static int multisigKexRoundsRequired(int numSigners, int threshold) {
    if (numSigners < threshold) {
      throw const MoneroMultisigAccountException(
          "num_signers must be >= threshold");
    }
    if (threshold < 1) {
      throw const MoneroMultisigAccountException("threshold must be >= 1");
    }
    return numSigners - threshold + 1;
  }

  static int multisigSetupRoundsRequired(int numSigners, int threshold) {
    return multisigKexRoundsRequired(numSigners, threshold) + 1;
  }

  static MoneroPrivateKey getMultisigBlindedSecretKey(RctKey key) {
    final keyBytes =
        RCT.hashToScalar_([...key, ...MoneroMultisigConst.hashKeyMultisig]);
    return MoneroPrivateKey.fromBytes(keyBytes);
  }

  static Tuple<MoneroPrivateKey, MoneroPublicKey>
      calculateMultisigKeypairFromDerivation(RctKey derivation) {
    final MoneroPrivateKey blindedSkey =
        getMultisigBlindedSecretKey(derivation);
    final pubKey = blindedSkey.publicKey;
    return Tuple(blindedSkey, pubKey);
  }

  static MoneroPrivateKey makeMultisigCommonPrivkey(
      List<MoneroPrivateKey> participantBaseCommonPrivkeys) {
    participantBaseCommonPrivkeys.sort((key1, key2) {
      return BytesUtils.compareBytes(key1.key, key2.key);
    });
    final keyBytes = RCT.hashToScalarKeys(
        participantBaseCommonPrivkeys.map((e) => e.key).toList());
    return MoneroPrivateKey.fromBytes(keyBytes);
  }

  static RctKey computeMultisigAggregationCoefficient(
      List<MoneroPublicKey> sortedKeys, MoneroPublicKey aggregationKey) {
    // aggregation key must be in sortedKeys
    if (!sortedKeys.contains(aggregationKey)) {
      throw const MoneroMultisigAccountException(
          "Aggregation key expected to be in input keyset.");
    }

    // aggregation coefficient salt
    final RctKey salt = RCT.zero();
    salt.setAll(0, MoneroMultisigConst.hashKeyMultisigKeyAggregation);

    final KeyV data = [
      aggregationKey.key,
      ...sortedKeys.map((e) => e.key),
      salt
    ];
    return RCT.hashToScalarKeys(data);
  }

  static Tuple<MoneroPublicKey, List<MoneroPrivateKey>>
      generateMultisigAggregateKey(List<MoneroPublicKey> finalKeys,
          List<MoneroPrivateKey> multisigPrivateKeys) {
    final Map<MoneroPublicKey, int> ownKeysMapping = {};
    final List<RctKey> privkeysInOut =
        multisigPrivateKeys.map((e) => e.key.clone()).toList();
    for (int i = 0; i < privkeysInOut.length; i++) {
      final MoneroPublicKey pubkey = multisigPrivateKeys[i].publicKey;
      ownKeysMapping[pubkey] = i;
      finalKeys.add(pubkey);
    }

    // Sort finalKeys in ascending order
    finalKeys.sort((a, b) => BytesUtils.compareBytes(a.key, b.key));
    for (int i = 1; i < finalKeys.length; i++) {
      if (finalKeys[i] == finalKeys[i - 1]) {
        throw const MoneroMultisigAccountException(
            "Unexpected duplicate found in input list.");
      }
    }

    // Initialize aggregate key
    final RctKey aggregateKey = RCT.identity();

    for (final key in finalKeys) {
      // Compute aggregation coefficient
      final RctKey coeff =
          computeMultisigAggregationCoefficient(finalKeys, key);
      if (ownKeysMapping[key] != null) {
        final int index = ownKeysMapping[key]!;
        CryptoOps.scMul(privkeysInOut[index], coeff, privkeysInOut[index]);
      }

      // Convert public key (pre-merge operation)
      final RctKey convertedPubkey = RCT.scalarmultKey_(key.key, coeff);

      // Merge converted public key into aggregate key
      RCT.addKeys(aggregateKey, aggregateKey, convertedPubkey);
    }
    final pubKey = MoneroPublicKey.fromBytes(aggregateKey);
    final List<MoneroPrivateKey> updatedKeys =
        privkeysInOut.map((e) => MoneroPrivateKey.fromBytes(e)).toList();
    return Tuple(pubKey, updatedKeys);
  }

  static Map<MoneroPublicKey, Set<MoneroPublicKey>> multisigKexMakeRoundKeys(
      MoneroPrivateKey basePrivateKey,
      Map<MoneroPublicKey, Set<MoneroPublicKey>> pubkeyOriginsMap) {
    final Map<MoneroPublicKey, Set<MoneroPublicKey>> derivationOriginsMapOut =
        {};

    for (final i in pubkeyOriginsMap.entries) {
      // D = 8 * k_base * K_pubkey
      // note: must be mul8 (cofactor), otherwise it is possible to leak to a malicious participant if the local
      //       base_privkey is a multiple of 8 or not
      // note2: avoid making temporaries that won't be memwiped
      final RctKey derivationRct = RCT.zero();

      RCT.scalarmultKey(derivationRct, i.key.key, basePrivateKey.key);
      RCT.scalarmultKey(derivationRct, derivationRct, RCTConst.eight);

      // retain mapping between pubkey's origins and the DH derivation
      // note: if working on last kex round, then caller must know how to handle these derivations properly
      derivationOriginsMapOut[MoneroPublicKey.fromBytes(derivationRct)] =
          i.value.clone();
    }
    return derivationOriginsMapOut;
  }

  static void checkMessagesRound(
      List<MultisigKexMessage> expandedMsgs, int expectedRound) {
    if (expandedMsgs.isEmpty) {
      throw const MoneroMultisigAccountException(
          "At least one input message expected.");
    }

    final int round = expandedMsgs[0].round;
    if (round != expectedRound) {
      throw const MoneroMultisigAccountException(
          "Messages don't have the expected kex round number.");
    }

    for (final expandedMsg in expandedMsgs) {
      if (expandedMsg.round != round) {
        throw const MoneroMultisigAccountException(
            "All messages must have the same kex round number.");
      }
    }
  }

  static Tuple<int, Map<MoneroPublicKey, Set<MoneroPublicKey>>>
      multisigKexMsgsSanitizePubkeys(
    List<MultisigKexMessage> expandedMsgs,
    List<MoneroPublicKey> excludePubkeys,
  ) {
    final Map<MoneroPublicKey, Set<MoneroPublicKey>> sanitizedPubkeysOut = {};
    // Ensure there is at least one input message
    if (expandedMsgs.isEmpty) {
      throw const MoneroMultisigAccountException(
          "At least one input message expected.");
    }

    // Get the round from the first message and check that all messages are from the same round
    final int round = expandedMsgs[0].round;
    checkMessagesRound(expandedMsgs, round);

    for (final expandedMsg in expandedMsgs) {
      if (round == 1) {
        sanitizedPubkeysOut
            .putIfAbsent(expandedMsg.signingPubKey, () => {})
            .add(expandedMsg.signingPubKey);
      } else {
        // In other rounds, only the message pubkeys are treated as message pubkeys
        for (final pubkey in expandedMsg.pubKeys) {
          if (excludePubkeys.contains(pubkey)) {
            continue;
          }
          sanitizedPubkeysOut
              .putIfAbsent(pubkey, () => {})
              .add(expandedMsg.signingPubKey);
        }
      }
    }

    return Tuple(round, sanitizedPubkeysOut);
  }

  static Map<MoneroPublicKey, Set<MoneroPublicKey>>
      evaluateMultisigKexRoundMsgs(
          MoneroPublicKey basePubkey,
          int expectedRound,
          List<MoneroPublicKey> signers,
          List<MultisigKexMessage> expandedMsgs,
          List<MoneroPublicKey> excludePubkeys,
          bool incompleteSignerSet) {
    if (excludePubkeys.toSet().length != excludePubkeys.length) {
      throw const MoneroCryptoException(
          "Found duplicate pubkeys for exclusion unexpectedly.");
    }
    final r = multisigKexMsgsSanitizePubkeys(expandedMsgs, excludePubkeys);
    final round = r.item1;
    final pubkeyOriginsMap = r.item2;
    if (round != expectedRound) {
      throw MoneroMultisigAccountException(
          "Kex messages were for round $round, but expected round is $expectedRound");
    }
    pubkeyOriginsMap.removeWhere((_, keyset) {
      keyset.removeWhere((e) => e == basePubkey);
      return keyset.isEmpty;
    });

    // Evaluate pubkeys collected
    final originPubkeysMap = <MoneroPublicKey, Set<MoneroPublicKey>>{};

    // Number of recommendations per pubkey required
    final numRecommendationsPerPubkeyRequired = incompleteSignerSet ? 1 : round;

    for (final entry in pubkeyOriginsMap.entries) {
      if (entry.value.length < numRecommendationsPerPubkeyRequired) {
        throw const MoneroMultisigAccountException(
            "A pubkey recommended by multisig kex messages had an unexpected number of recommendations.");
      }
      // Map sanitized pubkeys back to origins
      for (final origin in entry.value) {
        originPubkeysMap.putIfAbsent(origin, () => {}).add(entry.key);
      }
    }

    // Number of unique signers recommending pubkeys
    final numSignersRequired = incompleteSignerSet
        ? signers.length - 1 - (round - 1)
        : signers.length - 1;
    if (originPubkeysMap.length < numSignersRequired) {
      throw const MoneroMultisigAccountException(
          "Number of unique other signers recommending pubkeys does not equal number of required other signers");
    }
    // Calculate expected recommendations
    int nChooseK(int n, int k) {
      if (n < k) return 0;
      return (List.generate(k, (i) => n - i).fold<int>(1, (a, b) => a * b) /
              List.generate(k, (i) => i + 1).fold<int>(1, (a, b) => a * b))
          .round();
    }

    final expectedRecommendationsOthers =
        nChooseK(signers.length - 2, round - 1);
    final expectedRecommendationsSelf = nChooseK(signers.length - 1, round - 1);
    if (expectedRecommendationsSelf <= 0 ||
        expectedRecommendationsOthers <= 0) {
      throw const MoneroMultisigAccountException(
          'Bad num signers or round num (possibly numerical limits exceeded).');
    }

    // Check that local account recommends expected number of keys
    if (excludePubkeys.length != expectedRecommendationsSelf) {
      throw const MoneroMultisigAccountException(
          'Local account did not recommend expected number of multisig keys.');
    }

    // Check that other signers recommend expected number of keys
    for (final entry in originPubkeysMap.entries) {
      if (entry.value.length != expectedRecommendationsOthers) {
        throw const MoneroMultisigAccountException(
            'A multisig signer recommended an unexpected number of pubkeys.');
      }

      // Only expected signers should be recommending keys
      if (!signers.contains(entry.key)) {
        throw const MoneroMultisigAccountException(
            'Multisig key exchange message with unexpected signer encountered.');
      }
    }

    return pubkeyOriginsMap;
  }

  static Map<MoneroPublicKey, Set<MoneroPublicKey>>
      evaluateMultisigPostKexRoundMsgs(
    MoneroPublicKey basePubkey,
    int expectedRound,
    List<MoneroPublicKey> signers,
    List<MultisigKexMessage> expandedMsgs,
    bool incompleteSignerSet,
  ) {
    // Sanitize input messages
    final List<MoneroPublicKey> dummy = [];

    final r = multisigKexMsgsSanitizePubkeys(expandedMsgs, dummy);
    final pubkeyOriginsMap = r.item2;
    final round = r.item1;
    if (round != expectedRound) {
      throw MoneroMultisigAccountException(
          "Kex messages were for round $round, but expected round is $expectedRound");
    }

    // 1) There should only be two pubkeys
    if (pubkeyOriginsMap.length != 2) {
      throw const MoneroMultisigAccountException(
          "Multisig post-kex round messages from other signers did not all contain two pubkeys.");
    }

    // 2) Both keys should be recommended by the same set of signers
    final pubkeySetIterator = pubkeyOriginsMap.values.iterator;
    pubkeySetIterator.moveNext();
    final firstSet = pubkeySetIterator.current;
    pubkeySetIterator.moveNext();
    final secondSet = pubkeySetIterator.current;
    if (!CompareUtils.iterableIsEqual(firstSet, secondSet)) {
      throw const MoneroMultisigAccountException(
          "Multisig post-kex round messages from other signers did not all recommend the same pubkey pair.");
    }

    // 3) All signers should be present in the recommendation list (unless an incomplete list is permitted)
    final origins = {...firstSet, basePubkey}; // Add self if missing

    final numSignersRequired = incompleteSignerSet ? 1 : signers.length;

    if (origins.length < numSignersRequired) {
      throw const MoneroMultisigAccountException(
          "Multisig post-kex round message origins don't line up with multisig signer set");
    }

    for (final origin in origins) {
      // Ensure each origin is part of the signers list
      if (!signers.contains(origin)) {
        throw const MoneroMultisigAccountException(
            "An unknown origin recommended a multisig post-kex verification message.");
      }
    }

    return pubkeyOriginsMap;
  }

  static Map<MoneroPublicKey, Set<MoneroPublicKey>> multisigKexProcessRoundMsgs(
    MoneroPrivateKey basePrivkey,
    MoneroPublicKey basePubkey,
    int currentRound,
    int threshold,
    List<MoneroPublicKey> signers,
    List<MultisigKexMessage> expandedMsgs,
    List<MoneroPublicKey> excludePubkeys,
    bool incompleteSignerSet,
  ) {
    Map<MoneroPublicKey, Set<MoneroPublicKey>> keysToOriginsMapOut = {};
    checkMultisigConfig(currentRound, threshold, signers.length);
    final kexRoundsRequired =
        multisigKexRoundsRequired(signers.length, threshold);

    // Process messages into a [pubkey : {origins}] map
    Map<MoneroPublicKey, Set<MoneroPublicKey>> evaluatedPubkeys = {};

    if (threshold == 1 && currentRound == kexRoundsRequired) {
      // In the last main kex round of 1-of-N, all signers share a key so the local signer
      // doesn't care about evaluating recommendations from other signers
    } else if (currentRound <= kexRoundsRequired) {
      // For normal kex rounds, fully evaluate kex round messages
      evaluatedPubkeys = evaluateMultisigKexRoundMsgs(
        basePubkey,
        currentRound,
        signers,
        expandedMsgs,
        excludePubkeys,
        incompleteSignerSet,
      );
    } else {
      // For the post-kex verification round, validate the last kex round's messages
      evaluatedPubkeys = evaluateMultisigPostKexRoundMsgs(
        basePubkey,
        currentRound,
        signers,
        expandedMsgs,
        incompleteSignerSet,
      );
    }

    // Prepare keys-to-origins map for updating the multisig account
    if (currentRound < kexRoundsRequired) {
      // Normal kex round: make new keys
      keysToOriginsMapOut =
          multisigKexMakeRoundKeys(basePrivkey, evaluatedPubkeys);
    } else if (currentRound >= kexRoundsRequired) {
      keysToOriginsMapOut = {
        for (final i in evaluatedPubkeys.entries) i.key: i.value.clone()
      };
    }
    return keysToOriginsMapOut;
  }
}
