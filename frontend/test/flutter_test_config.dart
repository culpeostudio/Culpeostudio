import 'dart:async';

import 'package:culpeo_studio/core/api_client.dart';

/// Runs before every test in this directory.
///
/// Screens load their data over gRPC as they mount. No backend answers in a
/// widget test, so on the production deadline each of those calls would still
/// be waiting when the test ends and be reported as a pending timer. A tiny
/// deadline makes them give up on the first pump instead, which is how the
/// HTTP client behaved - it failed at once with "connection refused" - and
/// what the tests are written against.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ApiClient.callDeadline = const Duration(milliseconds: 1);
  await testMain();
}
