// L4 entry: full suite in Chrome against the Rust WASM backend.
// WASM assets are served by `dart test` from test/wasm_assets/ (built via
// `dart tool/build_backends.dart --wasm`). Small vectors for speed.
//
//   CHROME_EXECUTABLE=<wrapper> dart test -p chrome test/one_shot_browser_wasm_test.dart
@TestOn('browser')
@Tags(['wasm'])
library;

import 'package:test/test.dart';

import 'one_shot_suite.dart';
import 'utils.dart';

void main() async {
  const config = BuTestConfig(backend: BuTestBackend.wasm);
  MoneroTestApi.configure(config);
  await MoneroTestApi.initWasmBrowser(config);
  runOneShotSuite();
}
