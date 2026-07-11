part of 'package:monero_dart/src/tx_builder/tx_builder.dart';

class MoneroRctTxBuilder
    extends MoneroTxBuilder<SpendablePayment<MoneroUnLockedPayment>> {
  MoneroRctTxBuilder._({
    required super.sourceKeys,
    required super.destinationKeys,
    required super.transaction,
    required super.destinations,
    required super.sources,
    required super.change,
  });

  factory MoneroRctTxBuilder({
    required MoneroBaseAccountKeys account,
    required List<MoneroTxDestination> destinations,
    required List<SpendablePayment<MoneroUnLockedPayment>> sources,
    required BigInt fee,
    List<TxExtraNonce> extraNonces = const [],
    bool fakeTx = false,
    bool fast = false,
    MoneroTxDestination? change,
  }) {
    sources = List<SpendablePayment<MoneroUnLockedPayment>>.from(sources)..sort(
      (a, b) => BytesUtils.compareBytes(
        b.payment.output.keyImage.keyImage,
        a.payment.output.keyImage.keyImage,
      ),
    );
    final seed = MoneroTxBuilder._createTxSecretKeySeed(
      sources: sources,
      domain: "wallet_tx_privkeys_seed",
      fakeTx: fakeTx,
    );
    final sourceKeys = MoneroTxBuilder._computeSourceKeys(sources: sources);
    final destinationKeys = MoneroTxBuilder._computeDestinationKeys(
      account: account,
      destinations: destinations,
      sources: sourceKeys,
      change: change,
      txSeed: seed,
      fee: fee,
      fakeTx: fakeTx,
      extraNonces: extraNonces,
    );
    final signature = MoneroTxBuilder._buildSignature(
      destinationKeys: destinationKeys,
      sourceKeys: sourceKeys,
      sources: sources,
      fee: fee,
      fast: fast,
      fakeTx: fakeTx,
    );
    final transaction = MoneroTxBuilder._buildTx(
      destinationKeys: destinationKeys,
      sourceKeys: sourceKeys,
      signature: signature,
    );
    return MoneroRctTxBuilder._(
      sourceKeys: sourceKeys,
      destinationKeys: destinationKeys,
      transaction: transaction,
      change: change,
      destinations: destinations,
      sources: sources,
    );
  }
  factory MoneroRctTxBuilder.deserialize(List<int> bytes, {String? property}) {
    final decode = MoneroSerialization.deserialize(
      bytes: bytes,
      layout: layout(property: property),
    );
    return MoneroRctTxBuilder.deserializeJson(decode);
  }
  factory MoneroRctTxBuilder.deserializeJson(Map<String, dynamic> json) {
    return MoneroRctTxBuilder._(
      sourceKeys: ComputeSourceKeys.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("sourceKeys"),
      ),
      destinationKeys: ComputeDestinationKeys.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("destinationKeys"),
      ),
      transaction: MoneroTransaction.deserializeJson(
        json.valueEnsureAsMap<String, dynamic>("transaction"),
      ),
      change: json.valueTo<MoneroTxDestination?, Map<String, dynamic>>(
        key: "change",
        parse: (e) {
          return MoneroTxDestination.deserializeJson(e);
        },
      ),
      destinations:
          json
              .valueEnsureAsList<Map<String, dynamic>>("destinations")
              .map((e) => MoneroTxDestination.deserializeJson(e))
              .toList(),
      sources:
          json
              .valueEnsureAsList<Map<String, dynamic>>("sources")
              .map(
                (e) =>
                    SpendablePayment<MoneroUnLockedPayment>.deserializeJson(e),
              )
              .toList(),
    );
  }

  static Layout<Map<String, dynamic>> layout({
    String? property,
    MoneroTransaction? transaction,
  }) {
    return LayoutConst.struct([
      ComputeSourceKeys.layout(property: "sourceKeys"),
      ComputeDestinationKeys.layout(property: "destinationKeys"),
      MoneroTransaction.layout(
        property: "transaction",
        transaction: transaction,
        forcePrunable: true,
      ),
      MoneroLayoutConst.variantVec(
        MoneroTxDestination.layout(),
        property: "destinations",
      ),
      MoneroLayoutConst.variantVec(
        SpendablePayment.layout(),
        property: "sources",
      ),
      LayoutConst.optional(MoneroTxDestination.layout(), property: "change"),
    ], property: property);
  }

  @override
  Map<String, dynamic> toLayoutStruct() {
    return {
      "sourceKeys": sourceKeys.toLayoutStruct(),
      "destinationKeys": destinationKeys.toLayoutStruct(),
      "transaction": transaction.toLayoutStruct(),
      "destinations": destinations.map((e) => e.toLayoutStruct()).toList(),
      "sources": sources.map((e) => e.toLayoutStruct()).toList(),
      "change": change?.toLayoutStruct(),
    };
  }

  @override
  Layout<Map<String, dynamic>> createLayout({String? property}) {
    return layout(property: property, transaction: transaction);
  }

  @override
  MoneroTransaction getFinalTx() {
    return transaction;
  }
}
