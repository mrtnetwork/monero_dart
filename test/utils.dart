import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'test_backend.dart';
import 'test_backend_stub.dart'
    if (dart.library.io) 'test_backend_io.dart'
    as backend_io;

export 'test_backend.dart';

extension Take<T> on List<T> {
  List<T> takeShuffle([int limit = 10]) {
    final shuffle = clone()..shuffle();
    return shuffle.take(limit).toList();
  }
}

class MoneroTestConst {
  static const iteration = 50;
}

/// Installs a deterministic seeded RNG for reproducible test vectors.
///
/// Replaces the old pattern of pasting a hardcoded hex key-stream into
/// every test plus an index-cycling `QuickCrypto.setupRandom` closure.
/// Each call creates a fresh `ChaCha20Rng`, so every test starts from the
/// same stream position regardless of execution order.
///
/// This only overrides the random *source* (`_generateRandom`); the global
/// Fortuna `_prng` is untouched, so `QuickCrypto.setupRandom(null)`
/// (already done after each case in `bullet_proof_test.dart`) restores
/// default behavior.
///
/// IMPORTANT: the `blockchainUtils` backend must be initialized *before*
/// calling this. First access to `blockchainUtils.api` draws 3x32 bytes via
/// `QuickCrypto.generateRandom` (secp256k1 blinding contexts), which would
/// silently shift the seeded stream mid-test. `MoneroTestApi.runTest`
/// already initializes the backend first, so this is safe there; standalone
/// scripts must call `blockchainUtils.setDartApi()` (or touch `.api`) first.
void installSeededTestRng({int seedByte = 12}) {
  final rng = ChaCha20Rng(List<int>.filled(32, seedByte));
  QuickCrypto.setupRandom(rng.nextBytes);
}

typedef CbRunTest = void Function();
typedef CbRunTestApi = void Function(BlockchainUtilsApi api);

class MoneroTestApi {
  static bool _inited = false;
  static BuTestConfig? _explicit;

  /// Pins an explicit backend config (overrides environment).
  static void configure(BuTestConfig config) {
    _explicit = config;
    _inited = false;
  }

  static BuTestConfig _resolve([BuTestConfig? override]) {
    return override ?? _explicit ?? BuTestConfig.fromEnv();
  }

  /// Backend the harness resolved for this run (explicit entry config →
  /// `BU_BACKEND` → default). The backend-identity test reads this instead
  /// of the raw env var, because suite entries pin the backend explicitly
  /// (e.g. the browser-dart entry forces pure Dart while `BU_BACKEND`
  /// is unset, which parses as `ffi`).
  static BuTestBackend get resolvedBackend => _resolve().backend;

  /// Throws [StateError] when the resolved backend did not actually
  /// activate (e.g. an `ffi` run silently falling back to pure Dart).
  /// Every entry point funnels through here so a misconfigured backend
  /// fails loudly instead of producing backend-mislabeled results.
  static void _assertBackendActive(BuTestBackend backend) {
    final native = blockchainUtils.hasNativeBackend;
    if (backend == BuTestBackend.dart && native) {
      throw StateError(
        'BU_BACKEND=dart selected but a native backend is active. '
        'Refusing to run Dart-backend tests against Rust.',
      );
    }
    if (backend != BuTestBackend.dart && !native) {
      throw StateError(
        'BU_BACKEND=$backend selected but no native backend is active '
        '(hasNativeBackend == false). Refusing to run Rust-backend tests '
        'on the pure-Dart backend.',
      );
    }
  }

  /// Resolves + applies the backend, building the FFI library with cargo
  /// first when missing and `BU_BUILD=ffi|all|1` (VM only).
  static Future<void> ensureBackend([BuTestConfig? config]) async {
    if (_inited) return;
    final c = _resolve(config);
    if (c.backend == BuTestBackend.wasm) {
      throw UnsupportedError(
        'wasm backend needs a browser: run '
        '`dart test -p chrome test/one_shot_browser_wasm_test.dart` '
        '(or call MoneroTestApi.initWasmBrowser on web).',
      );
    }
    if (c.backend == BuTestBackend.ffi) {
      String? path = c.ffiLibraryPath;
      try {
        path ??= backend_io.defaultFfiLibraryPath(profile: c.ffiProfile);
        if (!backend_io.ffiLibraryExists(path)) {
          if (c.buildMissing) {
            path = await backend_io.ensureFfiLibrary(
              profile: c.ffiProfile,
              buildMissing: true,
              features: c.ffiFeatures,
              noDefaultFeatures: c.ffiNoDefaultFeatures,
            );
          } else {
            path = null; // fall back to platform default lookup
          }
        }
      } on UnsupportedError catch (_) {
        path = c.ffiLibraryPath;
      }
      // ignore: avoid_redundant_argument_values
      c.applyTo(blockchainUtils, resolvedFfiPath: path);
    } else {
      c.applyTo(blockchainUtils);
    }
    _assertBackendActive(c.backend);
    _inited = true;
  }

  /// Browser entry point: loads the WASM glue/module and selects the Rust
  /// backend. Web only.
  static Future<void> initWasmBrowser([BuTestConfig? config]) async {
    final c = _resolve(config);
    final buConfig = BuConfig(
      wasmGlueUrl: c.wasmGlueUrl,
      wasmModuleUrl: c.wasmModuleUrl,
    );
    await Bu.ensureWasmLoaded(buConfig);
    blockchainUtils.setRustApi(
      wasmGlueUrl: c.wasmGlueUrl,
      wasmModuleUrl: c.wasmModuleUrl,
    );
    _assertBackendActive(BuTestBackend.wasm);
    _inited = true;
  }

  static void _init() {
    if (_inited) return;
    final c = _resolve();
    if (c.backend == BuTestBackend.wasm) {
      throw UnsupportedError(
        'wasm backend needs a browser: run '
        '`dart test -p chrome test/one_shot_browser_wasm_test.dart`.',
      );
    }
    if (c.backend == BuTestBackend.ffi) {
      String? path = c.ffiLibraryPath;
      try {
        path ??= backend_io.defaultFfiLibraryPath(profile: c.ffiProfile);
        if (!backend_io.ffiLibraryExists(path)) {
          path = null; // fall back to platform default lookup
        }
      } on UnsupportedError {
        path = c.ffiLibraryPath;
      }
      c.applyTo(blockchainUtils, resolvedFfiPath: path);
    } else {
      c.applyTo(blockchainUtils);
    }
    _assertBackendActive(c.backend);
    _inited = true;
  }

  static void runTest(CbRunTest fn, String name, {CbRunTestApi? onNative}) {
    _init();
    fn();
    if (onNative != null) onNative(blockchainUtils.api);
  }
}
