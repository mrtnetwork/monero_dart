@TestOn('browser')
@Tags(['wasm'])
library;

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/src/crypto/monero/crypto.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  setUpAll(() async {
    // Shared harness: injects the glue script (served by the dart-test
    // static handler from test/wasm_assets/), waits for bootstrap, then
    // selects the Rust backend. No .so involved.
    await MoneroTestApi.initWasmBrowser();
  });

  group('wasm backend smoke (monero_dart)', () {
    test('sha256 empty (shared backend)', () {
      expect(
        BytesUtils.toHexString(QuickCrypto.sha256Hash([])),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });
    test('monero key image vector', () {
      final publicKey = ED25519MoneroPublicKey.fromBytes(
        BytesUtils.fromHexString(
          'e46b60ebfe610b8ba761032018471e5719bb77ea1cd945475c4a4abe7224bfd0',
        ),
      );
      final secretKey = ED25519MoneroPrivateKey.fromBytes(
        BytesUtils.fromHexString(
          '981d477fb18897fa1f784c89721a9d600bf283f06b89cb018a077f41dcefef0f',
        ),
      );
      expect(
        BytesUtils.toHexString(
          MoneroCrypto.generateKeyImageBytes(
            pubkey: publicKey.keyBytes,
            secretKey: secretKey.takeSecretKey(),
          ),
        ),
        'a637203ec41eab772532d30420eac80612fce8e44f1758bc7e2cb1bdda815887',
      );
    });
  });
}
