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

## Breaking changes

- **All legacy exception classes removed — every error is `BuError`.** Failures throw `BuError` with a `MoneroErrorType` taxonomy value (`domain: 'monero'`: plugin, crypto, multisig, serialization, scanner, proofs, …). Update `catch` clauses and `on` filters to `BuError`.

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

## Support

<details>
<summary><b>Support This Project — Click to show wallets</b></summary>

<br>

If this project helped you, consider supporting:

| Network | Address |
|---------|---------|
| ETH / EVM | `0xDdEDf30f96E6e2674Fab476bfC36201074081bcC` |
| TRON / TRC20 | `TDfY8zN3sobm2agzCmzzTYj7r4xxeVtcDL` |
| SOL | `BeV1GsY9W7hNBRqQasnq9LjFJPCwkqVghuNH7Yq7vp3d` |
| ADA | `addr1q83pedgpuka83q7rmfk2x3mepeq53x7fgucptye93d0sr9rj08fhhkk3ymxa59ydsrtg5ky5fe437ncw2mp7cnplsc0qwj0lzv` |
| SUI | `0xaaba244910f612f37d2cc090f9c78235753925c2ade5e2b1e79dc5d18ef4aa59` |
| APTOS | `0xfbdf4caecade57dafb08f633e2f4ef1518644b396b11f39026a0571ae6691b70` |
| TON | `UQCXNPerK6BKJng7h-Ph6Up4d6GlAFdXUrEL-5Fc9zAYhdFO` |
| BTC | `bc1q92fvc5jm4k8e5wegzmhzdv72gwe43sgfnuspgzfmj7llkd8xhmusgd44qf` |
| STELLAR | `GAMSM5WVDFDLEEG7W3D64AJGN75IX7PVXXOT7WIX4NKT4SS2ERF4N2XN` |

Thank you!

</details>
