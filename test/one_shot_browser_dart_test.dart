// L2 entry: full suite in Chrome against the pure-Dart backend (dart2js).
//
//   CHROME_EXECUTABLE=<wrapper> dart test -p chrome test/one_shot_browser_dart_test.dart
@TestOn('browser')
library;

import 'package:test/test.dart';

import 'one_shot_suite.dart';
import 'utils.dart';

void main() async {
  MoneroTestApi.configure(const BuTestConfig(backend: BuTestBackend.dart));
  runOneShotSuite();
}
