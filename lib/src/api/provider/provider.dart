part of 'package:monero_dart/src/api/api.dart';

/// Unified transaction status (wallet `WalletTransactionStatus` parity for
/// the Monero cases).
enum MoneroTxStatus {
  /// The transaction is confirmed.
  block,

  /// The transaction is in pool or has no height yet.
  pending,

  /// The transaction double-spent.
  failed,

  /// The transaction is unknown to the daemon.
  unknown,
}

mixin MoneroQuickClientApi {
  IProvider<IServiceProvider, MoneroRequestDetails> get provider;

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
      throw BuError(DefaultErrorType.notFound, "Tx not found.");
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
      throw BuError(
        DefaultErrorType.invalidArgument,
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
      throw BuError(
        DefaultErrorType.notFound,
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

  Future<List<BigInt>> getAbsoluteDistribution({
    Duration? timeout,
    bool binary = true,
  }) async {
    final distributions = await provider.request(switch (binary) {
      true => DaemonRequestGetOutputDistributionBin(
        amounts: [BigInt.zero],
        compress: true,
        cumulative: false,
      ),
      false => DaemonRequestGetOutputDistribution(
        amounts: [BigInt.zero],
        cumulative: false,
      ),
    }, timeout: timeout ?? const Duration(minutes: 2));
    if (distributions.distributions.length != 1) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid output distribution response: expected exactly one distribution.",
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
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid daemon response: Mismatch between the number of key images and the status response.",
      );
    }

    return result;
  }

  List<SpendablePayment<T>> generateFakePaymentOuts<
    T extends MoneroUnLockedPayment
  >({required List<T> payments, int fakeOutsLength = 16}) {
    final List<List<OutsEntry>> outs =
        payments.map((e) {
          bool lowIndex = e.globalIndex < BigInt.from(fakeOutsLength);
          return List.generate(fakeOutsLength, (i) {
            final indexBig = BigInt.from(i);
            return OutsEntry(
              index: switch (lowIndex) {
                true => e.globalIndex + indexBig,
                false => e.globalIndex - indexBig,
              },
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
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Fake outputs length should be greater than zero.",
      );
    }
    final List<List<OutsEntry>> outs = [];

    BigInt maxGlobalIndex = BigInt.zero;
    for (final i in payments) {
      final globalIndex = i.globalIndex;
      if (globalIndex > maxGlobalIndex) {
        maxGlobalIndex = globalIndex;
      }
    }
    final offsets = await getAbsoluteDistribution();
    if (offsets.length < MoneroNetworkConst.cryptonoteDefaultTxSpendableAge) {
      throw BuError(DefaultErrorType.invalidState, "Not enough rct outputs");
    }
    if (offsets.last < maxGlobalIndex) {
      throw BuError(
        DefaultErrorType.invalidArgument,
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
        throw BuError(
          DefaultErrorType.invalidState,
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
      offset += outChunSize;

      final outs = await getOuts(chunkRequest);
      outKeysResponse.addAll(outs.outs);
    }
    int base = 0;
    for (final payment in payments) {
      const defaultOutCount =
          MoneroNetworkConst.cryptonoteMinedMoneyUnlockWindow -
          MoneroNetworkConst.cryptonoteDefaultTxSpendableAge;
      final int outputsCount = baseRequestCount + defaultOutCount;
      final List<OutsEntry> out = [];
      final mask = RCT.commit(
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
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Daemon response did not include the requested real output",
        );
      }
      out.add(
        OutsEntry(
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
          throw BuError(
            DefaultErrorType.notFound,
            "Could not find index of picked output in requested outputs",
          );
        }
        final fakeOutResponse = outKeysResponse[i];
        final fakeOutRequest = outKeysRequests[i];
        final fakeEntry = OutsEntry(
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
        throw BuError(
          DefaultErrorType.invalidState,
          "Not enough outputs to mix: required ${fakeOutsLength + 1}, found ${out.length}.",
        );
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
        throw BuError(DefaultErrorType.notFound, "Index not found.");
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

  String? _genesis;

  Future<int> getHeight() async {
    final block = await provider.request(DaemonRequestGetLastBlockHeader());
    return block.blockHeader.height;
  }

  Future<DaemonGetBlocksByHeightResponse> getBlockByRange(
    int start,
    int end,
  ) async {
    final List<int> heights = List.generate(end - start, (i) => start + i);
    if (heights.isEmpty) {
      heights.add(start);
    }
    final blocks = await provider.request(
      DaemonRequestGetBlocksByHeightBin(heights),
    );
    if (blocks.blocks.length != heights.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Unexpected daemon response.",
      );
    }
    return blocks;
  }

  Future<List<DaemonBlockHeaderResponse>> getBlockHeadersRange({
    required int start,
    required int end,
    bool validateResponse = true,
  }) async {
    final r = await provider.request(
      DaemonRequestGetBlockHeaderByRange(startHeight: start, endHeight: end),
    );
    if (validateResponse && r.headers.length != (end - start) + 1) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Unexpected daemon response.",
      );
    }
    return r.headers;
  }

  Future<DaemonGetEstimateFeeResponse> getFeeEstimate() async {
    return await provider.request(
      const DaemonRequestGetFeeEstimate(
        MoneroNetworkConst.feeEstimateGraceBlocks,
      ),
    );
  }

  Future<DaemonGetInfoResponse> getChainInfo() async {
    return await provider.request(DaemonRequestGetInfo());
  }

  Future<String> getGenesisBlockHash() async {
    _genesis ??= await provider.request(DaemonRequestOnGetBlockHash(0));
    return _genesis!;
  }

  Future<MoneroTransaction> getTx(String txId) async {
    final rParams = DaemonRequestGetTransactions(
      [txId],
      prune: false,
      decodeAsJson: false,
      split: false,
    );
    final result = await provider.request(rParams);
    if (result.length != 1) {
      throw BuError(DefaultErrorType.notFound, "Transaction not found.");
    }
    return result[0].toTx();
  }

  /// Spent hex key images of [keyImages] (empty in, empty out).
  Future<List<String>> getSpentKeyImages(List<String> keyImages) async {
    if (keyImages.isEmpty) return [];
    final status = await keyImagesStatus(keyImages);
    final spent = <String>[];
    for (var i = 0; i < keyImages.length; i++) {
      if (status.spentStatus[i].isSpent) spent.add(keyImages[i]);
    }
    return spent;
  }

  /// Submits [txHex], returning it. Rejected submissions throw.
  Future<String> sendRawTransaction(String txHex) async {
    final response = await provider.request(
      DaemonRequestSendRawTransaction(txAsHex: txHex),
    );
    if (response.doubleSpend ||
        response.invalidInput ||
        response.invalidOutput ||
        response.overspend ||
        response.tooBig) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Monero transaction rejected.",
        details: {"reason": response.reason},
      );
    }
    return txHex;
  }

  /// Polls until [transactionId] confirms, throwing with double-spend
  /// details on failure or on [timeout].
  Future<void> trackTransaction({
    required String transactionId,
    Duration timeout = const Duration(minutes: 30),
    Duration periodicTimeOut = const Duration(seconds: 15),
  }) async {
    Timer? timer;
    try {
      final Completer<void> completer = Completer<void>();
      timer = Timer.periodic(periodicTimeOut, (_) async {
        if (completer.isCompleted) return;
        try {
          final txes = await provider.request(
            DaemonRequestGetTransactions([transactionId]),
          );
          final match = txes.where((e) => e.txHash == transactionId);
          if (match.isEmpty) return;
          final tx = match.first;
          if (tx.doubleSpend) {
            completer.completeError(
              BuError(
                DefaultErrorType.invalidArgument,
                "Monero transaction double-spent.",
              ),
            );
          } else if ((tx.confirmations ?? 0) > 0) {
            completer.complete();
          }
        } catch (_) {}
      });
      await completer.future.timeout(timeout);
    } on TimeoutException {
      throw BuError(
        DefaultErrorType.invalidState,
        "transaction confirmation failed within the allotted timeout.",
      );
    } finally {
      timer?.cancel();
      timer = null;
    }
  }

  /// Latest daemon height. Transport failures throw.
  Future<BigInt> getDaemonHeight() async {
    final info = await provider.request(const DaemonRequestGetHeight());
    return BigInt.from(info.height);
  }

  /// Status of [transactionId]: unknown when the daemon has no such
  /// transaction, pending while in pool or heightless, failed on
  /// double-spend, block otherwise.
  Future<MoneroTxStatus> getTransactionStatus(String transactionId) async {
    final txes = await provider.request(
      DaemonRequestGetTransactions([transactionId]),
    );
    if (txes.length != 1) return MoneroTxStatus.unknown;
    final tx = txes.first;
    if (tx.inPool || tx.height == null) return MoneroTxStatus.pending;
    if (tx.doubleSpend) return MoneroTxStatus.failed;
    return MoneroTxStatus.block;
  }

  /// Max 50 tx hashes per daemon call (client-side batching).
  static const int maxTxRequestPerCall = 50;
}
