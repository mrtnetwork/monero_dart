# Monero Dart

monero_dart is a Dart package that implements Monero cryptography for creating and signing RingCT (Rct) transactions in pure Dart. It supports the latest Bulletproof Plus for RCT signatures and multisignature accounts for transaction creation. This package includes comprehensive account management features such as account generation, seed-to-mnemonic conversion, and serialization. It also provides full support for interacting with Monero daemons and wallet RPCs, making it a complete solution for working with Monero in Dart.

## Futures

- **Transaction Management**
  - Serialize and deserialize all types of Monero transactions.
  - Create, sign (Bulletproof Plus), and generate proofs for transactions (pure Dart).
  - Create, sign (Bulletproof Plus), and generate proofs for multisignature transactions (pure Dart).

- **Address managment**
  - Generate mnemonics and seeds.
  - Generate primary, subaddresses, and integrated addresses.
  - Support multisignature address generation.

- **Binary Operations**
  - Monero transaction and data serialization.
  - Serialization of storage formats.

- **Provider**
  - Full support for Monero daemon RPC (JSON, binary, JSON-RPC).
  - Full support for Monero wallet RPC.


### Examples

  - [Transfer](https://github.com/mrtnetwork/monero_dart/blob/main/example/lib/example/in7_out3_example.dart)
  - [Multisig Transfer 1/2](https://github.com/mrtnetwork/monero_dart/blob/main/example/lib/example/m1_n2_example.dart)
  - [Multisig Transfer 3/5](https://github.com/mrtnetwork/monero_dart/blob/main/example/lib/example/m3_n5_example.dart)
  - [Simple chain account tracker](https://github.com/mrtnetwork/monero_dart/blob/main/example/lib/example/tracker.dart)



Transfer 

```dart
  /// Define the mnemonic phrase used to generate the Monero account seed.
  const mnemonic =
      "nocturnal eluded pancakes atom ultimate goblet elapse remedy sieve going weird examine federal zones duties mews howls vortex rebel zoom delayed puddle moment ozone going";

  /// Generate the Monero seed from the mnemonic phrase.
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();

  /// Create a Monero account from the generated seed, specifying the coin type (Stagenet).
  final moneroAccount =
      MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);

  /// Create an instance of [MoneroAccountKeys] with the Monero account and network (Stagenet).
  final myAccount = MoneroAccountKeys(
      account: moneroAccount, network: MoneroNetwork.stagenet);

  /// Set up the Monero provider with an HTTP provider for Stagenet daemon.
  final provider = MoneroProvider(
      MoneroHTTPProvider(daemoUrl: "http://stagenet.community.rino.io:38081"));

  /// Create an instance of the [MoneroApi] using the configured provider.
  final api = MoneroApi(provider);

  /// Retrieve unlocked payment outputs by providing transaction hashes and the account.
  /// Also cleans up any spent outputs.
  List<MoneroUnLockedPayment> outs =
      await api.unlockTxHashesPayments(txHashes: [
    "9b698348a066d920a1c5c79583ac636e2e778fc8241fd0c17eb8b0f176559bd4",
  ], account: myAccount, cleanUpSpent: true);

  /// If no unlocked payments are found, exit early.
  if (outs.isEmpty) return;

  /// Create the transfer by specifying account, payments, destinations, and change address.
  final builder = await api.createTransfer(
      account: myAccount,
      payments: outs,
      destinations: [
        TxDestination.fromXMR(
            amount: "0.1",
            address: MoneroAddress(
                "76dZbjNCQeVaQVeCq9y6H4dZ5wZqA9NY7WSnjjNUYzz5aht9rd3Qro57SSaN2eerE1aHkS9qvw5iscx3JrAT87bL8FiJ1Ye")),
        TxDestination.fromXMR(
            amount: "0.1",
            address: MoneroAddress(
                "51yw3EafPkXS6gwhJGGvNn7DzPEEGrgfeJZBvAFjzu8w252Zr1nx4PfVdXi4e6kiiQMBJ8k4JCFby2pANTAjofbo2rWBpbx")),
      ],
      changeAddress: myAccount.primaryAddress());

  /// Print details about the transaction, including fee, input, output, and change address.
  print("tx fee: ${builder.feeAsXMR}");
  print("total input: ${builder.totalInputAsXMR}");
  print("total output: ${builder.totalOutputAsXMR}");
  print("change address: ${builder.change?.address}");
  print("change amount: ${builder.change?.amountAsXMR}");

  /// Get the final signed transaction and send it to the network.
  final tx = builder.getFinalTx();
  final txId = await api.provider.sendTx(tx);

  /// Print the transaction ID.
  print("txid $txId");
```

### Address managment
```dart
  /// Define the mnemonic phrase used to generate the Monero account seed.
  const mnemonic =
      "nocturnal eluded pancakes atom ultimate goblet elapse remedy sieve going weird examine federal zones duties mews howls vortex rebel zoom delayed puddle moment ozone going";

  /// Generate the Monero seed from the mnemonic phrase.
  final seed = MoneroSeedGenerator(Mnemonic.fromString(mnemonic)).generate();

  /// Create a Monero account from the generated seed, specifying the coin type (Stagenet).
  final moneroAccount =
      MoneroAccount.fromSeed(seed, coinType: MoneroCoins.moneroStagenet);

  /// Create an instance of [MoneroAccountKeys] with the Monero account and network (Stagenet).
  final myAccount = MoneroAccountKeys(
      account: moneroAccount, network: MoneroNetwork.stagenet);

  /// Retrieve the primary address.
  final primaryAddress = myAccount.primaryAddress();

  /// Retrieve a subaddress. The minor index 1 is specified
  /// to generate the subaddress.
  final subAddress = myAccount.subAddress(const MoneroAccountIndex(minor: 1));

  /// Generate an integrated address, using a specified
  /// payment ID (represented by a 8-byte payment ID).
  final integratedAddress =
      myAccount.integratedAddress(paymentId: 8 /* 8 bytes payment ID */);

```

### Daemon and wallet RPC
All RPC methods are available [here](https://github.com/mrtnetwork/monero_dart/tree/main/lib/src/provider/methods).

 See the [example](https://github.com/mrtnetwork/monero_dart/blob/main/example/lib/example/provider_example.dart) for implementing the provider service.

```dart
/// Create a custom service provider that implements [MoneroServiceProvider]
/// to handle communication with Monero services via HTTP.
class MoneroHTTPProvider implements MoneroServiceProvider {
  @override
  Future<MoneroServiceResponse> post(MoneroRequestDetails params,
      {Duration? timeout}) async {
    /// Send the HTTP request to the network and return the response.
    /// The response contains the status code and the response body in bytes.
    return MoneroServiceResponse(
        status: response.statusCode, responseBytes: response.bodyBytes);
  }
}

  /// Create a provider instance for Monero services, 
  /// specifying URLs for both the daemon and wallet services.
  final provider = MoneroProvider(MoneroHTTPProvider(
      daemoUrl: "http://stagenet.community.rino.io:38081",
      walletUrl: "http://127.0.0.1:1880"));

  /// Send a request to the daemon to retrieve block information.
  /// The request includes block IDs and the starting height for the block range.
  final blocks = await provider.request(DaemonRequestGetBlocksBin(blockIds: [
    /// List of block IDs to fetch.
  ], startHeight: 1700000));

  /// Send a request to the wallet to retrieve the balance for the specified account index.
  final balance =
      await provider.request(WalletRequestGetBalance(accountIndex: 0));


```

## Resources

- [Monero Official](https://github.com/monero-project/monero)

## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository and create a new branch.
- Make your changes and ensure tests pass.
- Submit a pull request with a detailed description of your changes.

## Feature requests and bugs

Please file feature requests and bugs in the issue tracker.
