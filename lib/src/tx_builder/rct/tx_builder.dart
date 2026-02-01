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
    bool fakeTx = false,
    bool fast = false,
    MoneroTxDestination? change,
  }) {
    sources = List<SpendablePayment<MoneroUnLockedPayment>>.from(sources)..sort(
      (a, b) => BytesUtils.compareBytes(
        b.payment.output.keyImage,
        a.payment.output.keyImage,
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
    return MoneroRctTxBuilder.fromStruct(decode);
  }
  factory MoneroRctTxBuilder.fromStruct(Map<String, dynamic> json) {
    return MoneroRctTxBuilder._(
      sourceKeys: ComputeSourceKeys.fromStruct(json.asMap("sourceKeys")),
      destinationKeys: ComputeDestinationKeys.fromStruct(
        json.asMap("destinationKeys"),
      ),
      transaction: MoneroTransaction.fromStruct(json.asMap("transaction")),
      change: json.mybeAs<MoneroTxDestination, Map<String, dynamic>>(
        key: "change",
        onValue: (e) {
          return MoneroTxDestination.fromStruct(e);
        },
      ),
      destinations:
          json
              .asListOfMap("destinations")!
              .map((e) => MoneroTxDestination.fromStruct(e))
              .toList(),
      sources:
          json
              .asListOfMap("sources")!
              .map((e) => SpendablePayment<MoneroUnLockedPayment>.fromStruct(e))
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
