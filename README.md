# Monero Dart

Dart library for Monero: create and sign RingCT transactions with Bulletproofs+ range proofs, multisignature transfers, account management (mnemonics, subaddresses), output tracking, and full daemon / wallet RPC support.

This package is the continuation of the original
[mrtnetwork/monero_dart](https://github.com/mrtnetwork/monero_dart).

## Crypto engine: `blockchain_utils` dual backend

All cryptography delegates to
[`blockchain_utils`](https://github.com/mrtnetwork/blockchain_utils): pure
Dart by default, optional Rust backend (FFI on native, WASM on web). When set
(`blockchainUtils.setRustApi()`), all high-level crypto used here routes
through Rust — **use the Rust backend for faster Bulletproofs+ / RingCT proof
generation**. Rust core:
[mrtnetwork/blockchain-utils](https://github.com/mrtnetwork/blockchain-utils).

## Supported networks

| Network | Support |
|---|---|
| Mainnet | ✅ |
| Stagenet | ✅ |
| Testnet | ✅ |

## Features

### Transactions

| Area | Support |
|---|---|
| Types | RingCT (full + simple), coinbase UTXO decode/spend, multisig transfers |
| Proofs | Bulletproofs+ range proofs, MLSAG / CLSAG ring signatures |
| Builder | Fee-aware transfer builder, destinations + change, unlock/track payments |
| Signing | Single-key and multisig (1-of-2 through m-of-n) signing flows |

### Addresses & keys

| Area | Support |
|---|---|
| Mnemonics | 25-word Monero mnemonics, seed generation |
| Addresses | Primary, subaddresses, integrated (payment ID), multisig addresses |
| Keys | View / spend keys, key derivation, address validation (`IAddress`) |

### Tracking

| Area | Support |
|---|---|
| Scanner | `MoneroBlockProcessor` for tracking account UTXOs |
| Unlocking | Unlock payments by tx hash, spent-output cleanup |

### Providers

| API | Support |
|---|---|
| Daemon RPC | JSON, binary, and JSON-RPC (blocks, txs, outputs, fees, broadcast) |
| Wallet RPC | Accounts, balances, transfers, multisig key exchange / import / export |

## Examples

See [`example/`](https://github.com/mrtnetwork/monero_dart/tree/main/example)
(transfers, 1-of-2 and m-of-n multisig, subaddresses, block processor,
regtest and local-node flows).

## Contributing

Contributions are welcome! Please follow these guidelines:

- Fork the repository and create a new branch.
- Make your changes and ensure tests pass.
- Submit a pull request with a detailed description of your changes.

## Feature requests and bugs

Please file feature requests and bugs in the issue tracker.
