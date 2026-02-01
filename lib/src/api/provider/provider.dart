part of 'package:monero_dart/src/api/api.dart';

class QuickMoneroProvider {
  final MoneroProvider provider;
  const QuickMoneroProvider(this.provider);

  Future<DaemonGetEstimateFeeResponse> baseFee() async {
    return await provider.request(
      const DaemonRequestGetFeeEstimate(
        MoneroNetworkConst.feeEstimateGraceBlocks,
      ),
    );
  }

  Future<DaemonGetBlockHeightResponse> currentHeight() async {
    return await provider.request(const DaemonRequestGetHeight());
  }

  Future<DaemonGetBlockBinResponse> getBlocks({
    List<String> blockIds = const [],
    int startHeight = 0,
    bool prune = true,
    DaemonRequestBlocksInfo requestedInfo = DaemonRequestBlocksInfo.blocksOnly,
  }) async {
    return await provider.request(
      DaemonRequestGetBlocksBin(
        blockIds: blockIds,
        prune: prune,
        startHeight: startHeight,
        requestedInfo: requestedInfo,
      ),
    );
  }

  Future<MoneroTransactionWithOutputIndeces> getSingleTx(String txId) async {
    final result = await provider.request(
      DaemonRequestGetTransactions(
        [txId],
        prune: false,
        decodeAsJson: false,
        split: false,
      ),
    );
    if (result.length != 1) {
      throw const DartMoneroPluginException("Tx not found.");
    }
    final tx = result[0];
    return MoneroTransactionWithOutputIndeces(
      transaction: tx.toTx(),
      outputIndices: tx.outoutIndices,
    );
  }

  Future<List<MoneroTransactionWithOutputIndeces>> getTxes({
    required List<String> txHashes,
    bool validateResponse = true,
    bool allowMempol = false,
  }) async {
    if (txHashes.isEmpty) {
      throw const DartMoneroPluginException(
        "At least one transaction hash is required to retrieve transactions",
      );
    }
    final result = await provider.request(
      DaemonRequestGetTransactions(
        txHashes,
        prune: false,
        decodeAsJson: false,
        split: false,
      ),
    );
    if (validateResponse && txHashes.length != result.length) {
      throw const DartMoneroPluginException(
        "One or more transactions could not be found.",
      );
    }
    if (allowMempol) {
      return result
          .map(
            (e) => MoneroTransactionWithOutputIndeces.unSafe(
              transaction: e.toTx(),
              outputIndices: e.outoutIndices,
            ),
          )
          .toList();
    }
    return result
        .map(
          (e) => MoneroTransactionWithOutputIndeces(
            transaction: e.toTx(),
            outputIndices: e.outoutIndices,
          ),
        )
        .toList();
  }

  Future<List<BigInt>> getAbsoluteDistribution() async {
    final distributions = await provider.request(
      DaemonRequestGetOutputDistributionBin(
        amounts: [BigInt.zero],
        compress: true,
        cumulative: false,
      ),
    );
    if (distributions.distributions.length != 1) {
      throw const DartMoneroPluginException(
        "invalid output Distribution response.",
      );
    }
    final List<BigInt> offsets = List<BigInt>.from(
      distributions.distributions[0].distribution,
    );
    for (int i = 1; i < offsets.length; i++) {
      offsets[i] = offsets[i] + offsets[i - 1];
    }
    return offsets;
  }

  Future<GetOutResponse> getOuts(
    List<DaemonGetOutRequestParams> outputs,
  ) async {
    final outs = await provider.request(
      DaemonRequestGetOuts(outputs: outputs, getTxId: false),
    );
    return outs;
  }

  Future<DaemonIsKeyImageSpentResponse> keyImagesStatus(
    List<String> keyImages, {
    bool validateResponse = true,
  }) async {
    if (keyImages.isEmpty) {
      return DaemonIsKeyImageSpentResponse([]);
    }
    final result = await provider.request(
      DaemonRequestIsKeyImageSpent(keyImages),
    );
    if (validateResponse && result.spentStatus.length != keyImages.length) {
      throw const DartMoneroPluginException(
        "Invalid daemon response: Mismatch between the number of key images and the status response.",
      );
    }

    return result;
  }

  List<SpendablePayment<T>> generateFakePaymentOuts<
    T extends MoneroUnLockedPayment
  >({required List<T> payments, int fakeOutsLength = 16}) {
    final List<List<OutsEntery>> outs =
        payments.map((e) {
          return List.generate(fakeOutsLength, (i) {
            return OutsEntery(
              index: e.globalIndex - BigInt.from(i),
              key: CtKey(
                dest:
                    i == 0
                        ? e.output.ephemeralPublicKey
                        : RCT.identity(clone: false),
                mask: RCT.identity(clone: false),
              ),
            );
          }).toList();
        }).toList();
    return List.generate(
      payments.length,
      (i) => SpendablePayment(
        payment: payments[i],
        outs: outs[i],
        realOutIndex: 0,
      ),
    );
  }

  Future<List<SpendablePayment<T>>> generatePaymentOutputs<
    T extends MoneroPayment
  >({required List<T> payments, int fakeOutsLength = 15}) async {
    if (fakeOutsLength <= 0) {
      throw const DartMoneroPluginException(
        "fake outs length should be greather than zero.",
      );
    }
    final List<List<OutsEntery>> outs = [];

    BigInt maxGlobalIndex = BigInt.zero;
    for (final i in payments) {
      final globalIndex = i.globalIndex;
      if (globalIndex > maxGlobalIndex) {
        maxGlobalIndex = globalIndex;
      }
    }
    final offsets = await getAbsoluteDistribution();
    if (offsets.length < MoneroNetworkConst.cryptonoteDefaultTxSpendableAge) {
      throw const DartMoneroPluginException("Not enough rct outputs");
    }
    if (offsets.last < maxGlobalIndex) {
      throw const DartMoneroPluginException(
        "Daemon reports suspicious number of rct outputs",
      );
    }
    final int baseRequestCount = ((fakeOutsLength + 1) * 1.5 + 1).ceil();
    final List<OutKeyResponse> outKeysResponse = [];
    final List<DaemonGetOutRequestParams> outKeysRequestOrder = [];
    List<DaemonGetOutRequestParams> outKeysRequests = [];

    void addOuts(DaemonGetOutRequestParams out) {
      outKeysRequestOrder.add(out);
      outKeysRequests.add(out);
    }

    final gamma = Gamma(rctOffsets: offsets);
    for (final i in payments) {
      final BigInt amount = BigInt.zero;
      final Set<BigInt> indices = {};
      const defaultOutCount =
          MoneroNetworkConst.cryptonoteMinedMoneyUnlockWindow -
          MoneroNetworkConst.cryptonoteDefaultTxSpendableAge;
      final int outputsCount = baseRequestCount + defaultOutCount;
      final int start = outKeysRequests.length;
      final BigInt numOuts = gamma.numRctOuts;
      if (numOuts == BigInt.zero) {
        throw const DartMoneroPluginException(
          "histogram reports no unlocked rct outputs, not even ours",
        );
      }
      BigInt numFound = BigInt.zero;
      if (numOuts <= BigInt.from(outputsCount)) {
        for (BigInt i = BigInt.zero; i < numOuts; i += BigInt.one) {
          addOuts(DaemonGetOutRequestParams(amount: amount, index: i));
        }
        for (
          BigInt i = numOuts;
          i < BigInt.from(outputsCount);
          i += BigInt.one
        ) {
          addOuts(DaemonGetOutRequestParams(amount: amount, index: i));
        }
      } else {
        if (numFound == BigInt.zero) {
          numFound = BigInt.one;
          indices.add(i.globalIndex);
          addOuts(
            DaemonGetOutRequestParams(amount: amount, index: i.globalIndex),
          );
        }
        BigInt usableOuts = numOuts;
        bool blackballed = false;
        while (numFound < BigInt.from(outputsCount)) {
          if (BigInt.from(indices.length) == usableOuts) {
            if (blackballed) {
              break;
            }
            blackballed = true;
            usableOuts = numOuts;
          }
          BigInt i;

          do {
            i = gamma.pick();
          } while (i >= numOuts);
          if (indices.contains(i)) {
            continue;
          }
          indices.add(i);
          addOuts(DaemonGetOutRequestParams(amount: amount, index: i));
          numFound += BigInt.one;
        }
        while (numFound < BigInt.from(outputsCount)) {
          addOuts(
            DaemonGetOutRequestParams(amount: amount, index: BigInt.zero),
          );
          numFound += BigInt.one;
        }
      }
      final lastPart = outKeysRequests.sublist(start)
        ..sort((a, b) => a.index.compareTo(b.index));
      outKeysRequests = [...outKeysRequests.sublist(0, start), ...lastPart];
    }

    int offset = 0;
    while (offset < outKeysRequests.length) {
      const int size = 1000;
      final int outChunSize = IntUtils.min(
        outKeysRequests.length - offset,
        size,
      );
      final List<DaemonGetOutRequestParams> chunkRequest = [];
      for (int i = 0; i < outChunSize; i++) {
        chunkRequest.add(outKeysRequests[offset + i]);
      }
      offset += size;
      final outs = await getOuts(outKeysRequests);
      outKeysResponse.addAll(outs.outs);
    }

    int base = 0;
    for (final payment in payments) {
      const defaultOutCount =
          MoneroNetworkConst.cryptonoteMinedMoneyUnlockWindow -
          MoneroNetworkConst.cryptonoteDefaultTxSpendableAge;
      final int outputsCount = baseRequestCount + defaultOutCount;
      final List<OutsEntery> out = [];
      final mask = RCT.commitVar(
        xmrAmount: payment.output.amount,
        mask: payment.output.mask,
      );
      bool hasRealOut = false;
      for (int n = 0; n < outputsCount; ++n) {
        final int i = base + n;
        if (outKeysRequests[i].index == payment.globalIndex) {
          if (BytesUtils.bytesEqual(
            outKeysResponse[i].key,
            payment.output.outputPublicKey,
          )) {
            if (BytesUtils.bytesEqual(outKeysResponse[i].mask, mask)) {
              if (outKeysResponse[i].unlocked) {
                hasRealOut = true;
              }
            }
          }
        }
      }
      if (!hasRealOut) {
        throw const DartMoneroPluginException(
          "Daemon response did not include the requested real output",
        );
      }
      out.add(
        OutsEntery(
          index: payment.globalIndex,
          key: CtKey(dest: payment.output.outputPublicKey, mask: mask),
        ),
      );

      for (
        int idx = base;
        idx < base + outputsCount && out.length < fakeOutsLength + 1;
        ++idx
      ) {
        final attemptedOutput = outKeysRequestOrder[idx];
        int i;
        for (i = base; i < base + outputsCount; ++i) {
          if (outKeysRequests[i].index == attemptedOutput.index) {
            break;
          }
        }
        if (i == base + outputsCount) {
          throw const DartMoneroPluginException(
            "Could not find index of picked output in requested outputs",
          );
        }
        final fakeOutResponse = outKeysResponse[i];
        final fakeOutRequest = outKeysRequests[i];
        final fakeEntry = OutsEntery(
          index: fakeOutRequest.index,
          key: CtKey(dest: fakeOutResponse.key, mask: fakeOutResponse.mask),
        );
        if (fakeOutResponse.unlocked &&
            fakeOutRequest.index != payment.globalIndex &&
            !out.contains(fakeEntry)) {
          out.add(fakeEntry);
        }
      }
      out.sort((a, b) => a.index.compareTo(b.index));
      outs.add(out);
      if (out.length < fakeOutsLength + 1) {
        throw const DartMoneroPluginException("not enough outs to mix.");
      }

      base += outputsCount;
    }
    gamma.clean();

    return List.generate(payments.length, (i) {
      final payment = payments[i];
      final sourceOuts = outs[i];
      final index = sourceOuts.indexWhere(
        (e) => e.index == payment.globalIndex,
      );
      if (index.isNegative) {
        throw const DartMoneroPluginException("Index not found.");
      }
      return SpendablePayment<T>(
        payment: payment,
        outs: sourceOuts,
        realOutIndex: index,
      );
    });
  }

  Future<String> sendTx(
    MoneroTransaction tx, {
    bool doNotRelay = false,
    bool doSanityChecks = true,
  }) async {
    final dataHex = tx.serializeHex();
    await provider.request(
      DaemonRequestSendRawTransaction(
        txAsHex: dataHex,
        doNotRelay: doNotRelay,
        doSanityChecks: doSanityChecks,
      ),
    );
    return tx.getTxHash();
  }
}
