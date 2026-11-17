import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/error/monero_error.dart';
import 'package:monero_dart/src/crypto/multisig/const/const.dart';
import 'package:monero_dart/src/crypto/multisig/core/kex_message.dart';
import 'package:monero_dart/src/crypto/ringct/const/const.dart';
import 'package:monero_dart/src/crypto/ringct/utils/rct_crypto.dart';
import 'package:monero_dart/src/crypto/types/types.dart';

class MoneroMultisigKexUtils {
  static List<ED25519MoneroPublicKey> getKexExcludePubkeys({
    required int kexRoundsComplete,
    required ED25519MoneroPublicKey basePublicKey,
    required Set<ED25519MoneroPublicKey> kexKeys,
  }) {
    if (kexRoundsComplete == 0) {
      return [basePublicKey];
    } else {
      return kexKeys.toList();
    }
  }

  static List<int> generateMessageHash({
    required ED25519MoneroPrivateKey? msgPrivateKey,
    required ED25519MoneroPublicKey signingPubKey,
    required List<ED25519MoneroPublicKey> msgPubKeys,
    required int round,
  }) {
    List<int> hashKey;
    List<int> keyBytes;
    if (round == 1) {
      hashKey = MoneroMultisigConst.multisigKexMsgV2Magic1.codeUnits;
      keyBytes = msgPrivateKey!.takeSecretKey();
    } else {
      hashKey = MoneroMultisigConst.multisigKexMsgV2MagicN.codeUnits;
      keyBytes = msgPubKeys.expand((e) => e.toBytes()).toList();
    }
    final roundBytes = round.toU32LeBytes();

    return QuickCrypto.keccak256Hash([
      ...hashKey,
      ...roundBytes,
      ...signingPubKey.toBytes(),
      ...keyBytes,
    ]);
  }

  static List<ED25519MoneroPublicKey> validateConfig({
    required int threshold,
    required List<ED25519MoneroPublicKey> signers,
    required ED25519MoneroPublicKey basePublicKey,
  }) {
    if (threshold <= 0 || threshold > signers.length) {
      throw BuError(DefaultErrorType.invalidArgument, 
        'Multisig account: tried to set invalid threshold.',
      );
    }
    if (signers.length < 2 || signers.length > 10) {
      throw BuError(DefaultErrorType.invalidArgument, 
        'Multisig account: tried to set invalid number of signers.',
      );
    }

    if (!signers.contains(basePublicKey)) {
      throw BuError(DefaultErrorType.notFound, 
        'Multisig account: tried to set signers, but did not find the account\'s base pubkey in signer list.',
      );
    }

    signers.sort((a, b) => BytesUtils.compareBytes(a.toBytes(), b.toBytes()));

    if (signers.toSet().length != signers.length) {
      throw BuError(MoneroErrorType.multisigAccount, 
        'Multisig account: tried to set signers, but there are duplicate signers unexpectedly.',
      );
    }
    return signers.clone();
  }

  static void checkMultisigConfig(int round, int threshold, int numSigners) {
    if (numSigners <= 1) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Must be at least one other multisig signer.",
      );
    }
    if (numSigners > MoneroMultisigConst.multisigMaxSigners) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Too many multisig signers specified (limit = 16 to prevent dangerous combinatorial explosion during key exchange).",
      );
    }
    if (numSigners < threshold) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Multisig threshold may not be larger than number of signers.",
      );
    }
    if (threshold <= 0) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Multisig threshold must be > 0.",
      );
    }
    if (round <= 0) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Multisig kex round must be > 0.",
      );
    }
    if (round > multisigSetupRoundsRequired(numSigners, threshold)) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "Trying to process multisig kex for an invalid round.",
      );
    }
  }

  static int multisigKexRoundsRequired(int numSigners, int threshold) {
    if (numSigners < threshold) {
      throw BuError(DefaultErrorType.invalidArgument, 
        "num_signers must be >= threshold",
      );
    }
    if (threshold < 1) {
      throw BuError(DefaultErrorType.invalidArgument, "threshold must be >= 1");
    }
    return numSigners - threshold + 1;
  }

  static int multisigSetupRoundsRequired(int numSigners, int threshold) {
    return multisigKexRoundsRequired(numSigners, threshold) + 1;
  }

  static ED25519MoneroPrivateKey getMultisigBlindedSecretKey(List<int> key) {
    final keyBytes = RCT.hashToScalar([
      ...key,
      ...MoneroMultisigConst.hashKeyMultisig,
    ]);
    return ED25519MoneroPrivateKey.fromBytes(keyBytes);
  }

  static (ED25519MoneroPrivateKey, ED25519MoneroPublicKey)
  calculateMultisigKeypairFromDerivation(List<int> derivation) {
    final ED25519MoneroPrivateKey blindedSkey = getMultisigBlindedSecretKey(
      derivation,
    );
    final pubKey = blindedSkey.publicKey;
    return (blindedSkey, pubKey);
  }

  static ED25519MoneroPrivateKey makeMultisigCommonPrivkey(
    List<ED25519MoneroPrivateKey> participantBaseCommonPrivkeys,
  ) {
    participantBaseCommonPrivkeys.sort((key1, key2) {
      return BytesUtils.compareBytes(
        key1.takeSecretKey(),
        key2.takeSecretKey(),
      );
    });
    final keyBytes = RCT.hashToScalarKeys(
      participantBaseCommonPrivkeys
          .map((e) => e.takeSecretKey().toBytes())
          .toList(),
    );
    return ED25519MoneroPrivateKey.fromBytes(keyBytes);
  }

  static RctKey computeMultisigAggregationCoefficient(
    List<ED25519MoneroPublicKey> sortedKeys,
    ED25519MoneroPublicKey aggregationKey,
  ) {
    // aggregation key must be in sortedKeys
    if (!sortedKeys.contains(aggregationKey)) {
      throw BuError(DefaultErrorType.notFound, 
        "Aggregation key expected to be in input keyset.",
      );
    }

    // aggregation coefficient salt
    final RctKey salt = RCT.zero();
    salt.setAll(0, MoneroMultisigConst.hashKeyMultisigKeyAggregation);

    final KeyV data = [
      aggregationKey.toBytes(),
      ...sortedKeys.map((e) => e.toBytes()),
      salt,
    ];
    return RCT.hashToScalarKeys(data);
  }

  static (ED25519MoneroPublicKey, List<ED25519MoneroPrivateKey>)
  generateMultisigAggregateKey(
    List<ED25519MoneroPublicKey> finalKeys,
    List<ED25519MoneroPrivateKey> multisigPrivateKeys,
  ) {
    final Map<ED25519MoneroPublicKey, int> ownKeysMapping = {};
    final List<RctKey> privkeysInOut =
        multisigPrivateKeys.map((e) => e.takeSecretKey().toBytes()).toList();
    for (int i = 0; i < privkeysInOut.length; i++) {
      final ED25519MoneroPublicKey pubkey = multisigPrivateKeys[i].publicKey;
      ownKeysMapping[pubkey] = i;
      finalKeys.add(pubkey);
    }

    // Sort finalKeys in ascending order
    finalKeys.sort((a, b) => BytesUtils.compareBytes(a.toBytes(), b.toBytes()));
    for (int i = 1; i < finalKeys.length; i++) {
      if (finalKeys[i] == finalKeys[i - 1]) {
        throw BuError(DefaultErrorType.invalidArgument, 
          "Unexpected duplicate found in input list.",
        );
      }
    }

    // Initialize aggregate key
    RctKey aggregateKey = RCT.identity();

    for (final key in finalKeys) {
      // Compute aggregation coefficient
      final RctKey coeff = computeMultisigAggregationCoefficient(
        finalKeys,
        key,
      );
      if (ownKeysMapping[key] != null) {
        final int index = ownKeysMapping[key]!;
        privkeysInOut[index] = blockchainUtils.api.ed25519.scMul(
          coeff,
          privkeysInOut[index],
        );
      }

      // Convert public key (pre-merge operation)
      final RctKey convertedPubkey = RCT.scalarmultKey(key.toBytes(), coeff);

      // Merge converted public key into aggregate key
      aggregateKey = RCT.addKeys(aggregateKey, convertedPubkey);
    }
    final pubKey = ED25519MoneroPublicKey.fromBytes(aggregateKey);
    final List<ED25519MoneroPrivateKey> updatedKeys =
        privkeysInOut.map((e) => ED25519MoneroPrivateKey.fromBytes(e)).toList();
    return (pubKey, updatedKeys);
  }

  static Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
  multisigKexMakeRoundKeys(
    ED25519MoneroPrivateKey basePrivateKey,
    Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>> pubkeyOriginsMap,
  ) {
    final Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
    derivationOriginsMapOut = {};

    for (final i in pubkeyOriginsMap.entries) {
      // D = 8 * k_base * K_pubkey
      // note: must be mul8 (cofactor), otherwise it is possible to leak to a malicious participant if the local
      //       base_privkey is a multiple of 8 or not
      // note2: avoid making temporaries that won't be memwiped
      RctKey derivationRct = RCT.scalarmultKey(
        i.key.toBytes(),
        basePrivateKey.takeSecretKey(),
      );
      derivationRct = RCT.scalarmultKey(derivationRct, RCTConst.eight);

      // retain mapping between pubkey's origins and the DH derivation
      // note: if working on last kex round, then caller must know how to handle these derivations properly
      derivationOriginsMapOut[ED25519MoneroPublicKey.fromBytes(derivationRct)] =
          i.value.clone();
    }
    return derivationOriginsMapOut;
  }

  static void checkMessagesRound(
    List<MultisigKexMessage> expandedMsgs,
    int expectedRound,
  ) {
    if (expandedMsgs.isEmpty) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "At least one input message expected.",
      );
    }

    final int round = expandedMsgs[0].round;
    if (round != expectedRound) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Messages don't have the expected kex round number.",
      );
    }

    for (final expandedMsg in expandedMsgs) {
      if (expandedMsg.round != round) {
        throw BuError(MoneroErrorType.multisigAccount, 
          "All messages must have the same kex round number.",
        );
      }
    }
  }

  static (int, Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>)
  multisigKexMsgsSanitizePubkeys(
    List<MultisigKexMessage> expandedMsgs,
    List<ED25519MoneroPublicKey> excludePubkeys,
  ) {
    final Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
    sanitizedPubkeysOut = {};
    // Ensure there is at least one input message
    if (expandedMsgs.isEmpty) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "At least one input message expected.",
      );
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

    return (round, sanitizedPubkeysOut);
  }

  static Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
  evaluateMultisigKexRoundMsgs(
    ED25519MoneroPublicKey basePubkey,
    int expectedRound,
    List<ED25519MoneroPublicKey> signers,
    List<MultisigKexMessage> expandedMsgs,
    List<ED25519MoneroPublicKey> excludePubkeys,
    bool incompleteSignerSet,
  ) {
    if (excludePubkeys.toSet().length != excludePubkeys.length) {
      throw BuError(MoneroErrorType.crypto, 
        "Found duplicate pubkeys for exclusion unexpectedly.",
      );
    }
    final r = multisigKexMsgsSanitizePubkeys(expandedMsgs, excludePubkeys);
    final round = r.$1;
    final pubkeyOriginsMap = r.$2;
    if (round != expectedRound) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Kex messages were for round $round, but expected round is $expectedRound",
      );
    }
    pubkeyOriginsMap.removeWhere((_, keyset) {
      keyset.removeWhere((e) => e == basePubkey);
      return keyset.isEmpty;
    });

    // Evaluate pubkeys collected
    final originPubkeysMap =
        <ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>{};

    // Number of recommendations per pubkey required
    final numRecommendationsPerPubkeyRequired = incompleteSignerSet ? 1 : round;

    for (final entry in pubkeyOriginsMap.entries) {
      if (entry.value.length < numRecommendationsPerPubkeyRequired) {
        throw BuError(MoneroErrorType.multisigAccount, 
          "A pubkey recommended by multisig kex messages had an unexpected number of recommendations.",
        );
      }
      // Map sanitized pubkeys back to origins
      for (final origin in entry.value) {
        originPubkeysMap.putIfAbsent(origin, () => {}).add(entry.key);
      }
    }

    // Number of unique signers recommending pubkeys
    final numSignersRequired =
        incompleteSignerSet
            ? signers.length - 1 - (round - 1)
            : signers.length - 1;
    if (originPubkeysMap.length < numSignersRequired) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Number of unique other signers recommending pubkeys does not equal number of required other signers",
      );
    }
    // Calculate expected recommendations
    int nChooseK(int n, int k) {
      if (n < k) return 0;
      return (List.generate(k, (i) => n - i).fold<int>(1, (a, b) => a * b) /
              List.generate(k, (i) => i + 1).fold<int>(1, (a, b) => a * b))
          .round();
    }

    final expectedRecommendationsOthers = nChooseK(
      signers.length - 2,
      round - 1,
    );
    final expectedRecommendationsSelf = nChooseK(signers.length - 1, round - 1);
    if (expectedRecommendationsSelf <= 0 ||
        expectedRecommendationsOthers <= 0) {
      throw BuError(DefaultErrorType.invalidArgument, 
        'Bad num signers or round num (possibly numerical limits exceeded).',
      );
    }

    // Check that local account recommends expected number of keys
    if (excludePubkeys.length != expectedRecommendationsSelf) {
      throw BuError(MoneroErrorType.multisigAccount, 
        'Local account did not recommend expected number of multisig keys.',
      );
    }

    // Check that other signers recommend expected number of keys
    for (final entry in originPubkeysMap.entries) {
      if (entry.value.length != expectedRecommendationsOthers) {
        throw BuError(MoneroErrorType.multisigAccount, 
          'A multisig signer recommended an unexpected number of pubkeys.',
        );
      }

      // Only expected signers should be recommending keys
      if (!signers.contains(entry.key)) {
        throw BuError(MoneroErrorType.multisigAccount, 
          'Multisig key exchange message with unexpected signer encountered.',
        );
      }
    }

    return pubkeyOriginsMap;
  }

  static Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
  evaluateMultisigPostKexRoundMsgs(
    ED25519MoneroPublicKey basePubkey,
    int expectedRound,
    List<ED25519MoneroPublicKey> signers,
    List<MultisigKexMessage> expandedMsgs,
    bool incompleteSignerSet,
  ) {
    // Sanitize input messages
    final List<ED25519MoneroPublicKey> dummy = [];

    final r = multisigKexMsgsSanitizePubkeys(expandedMsgs, dummy);
    final pubkeyOriginsMap = r.$2;
    final round = r.$1;
    if (round != expectedRound) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Kex messages were for round $round, but expected round is $expectedRound",
      );
    }

    // 1) There should only be two pubkeys
    if (pubkeyOriginsMap.length != 2) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Multisig post-kex round messages from other signers did not all contain two pubkeys.",
      );
    }

    // 2) Both keys should be recommended by the same set of signers
    final pubkeySetIterator = pubkeyOriginsMap.values.iterator;
    pubkeySetIterator.moveNext();
    final firstSet = pubkeySetIterator.current;
    pubkeySetIterator.moveNext();
    final secondSet = pubkeySetIterator.current;
    if (!CompareUtils.iterableIsEqual(firstSet, secondSet)) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Multisig post-kex round messages from other signers did not all recommend the same pubkey pair.",
      );
    }

    // 3) All signers should be present in the recommendation list (unless an incomplete list is permitted)
    final origins = {...firstSet, basePubkey}; // Add self if missing

    final numSignersRequired = incompleteSignerSet ? 1 : signers.length;

    if (origins.length < numSignersRequired) {
      throw BuError(MoneroErrorType.multisigAccount, 
        "Multisig post-kex round message origins don't line up with multisig signer set",
      );
    }

    for (final origin in origins) {
      // Ensure each origin is part of the signers list
      if (!signers.contains(origin)) {
        throw BuError(DefaultErrorType.notFound, 
          "An unknown origin recommended a multisig post-kex verification message.",
        );
      }
    }

    return pubkeyOriginsMap;
  }

  static Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
  multisigKexProcessRoundMsgs(
    ED25519MoneroPrivateKey basePrivkey,
    ED25519MoneroPublicKey basePubkey,
    int currentRound,
    int threshold,
    List<ED25519MoneroPublicKey> signers,
    List<MultisigKexMessage> expandedMsgs,
    List<ED25519MoneroPublicKey> excludePubkeys,
    bool incompleteSignerSet,
  ) {
    Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>>
    keysToOriginsMapOut = {};
    checkMultisigConfig(currentRound, threshold, signers.length);
    final kexRoundsRequired = multisigKexRoundsRequired(
      signers.length,
      threshold,
    );

    // Process messages into a [pubkey : {origins}] map
    Map<ED25519MoneroPublicKey, Set<ED25519MoneroPublicKey>> evaluatedPubkeys =
        {};

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
      keysToOriginsMapOut = multisigKexMakeRoundKeys(
        basePrivkey,
        evaluatedPubkeys,
      );
    } else if (currentRound >= kexRoundsRequired) {
      keysToOriginsMapOut = {
        for (final i in evaluatedPubkeys.entries) i.key: i.value.clone(),
      };
    }
    return keysToOriginsMapOut;
  }
}
