import 'dart:async';

import 'package:pkgraph/src/database/retry.dart';
import 'package:test/test.dart';

/// A test harness for the [runWithRetry] function.
class RetryHarness {
  /// True if the operation eventually succeeded.
  bool didSucceed = false;

  /// Actual number of errors so far.
  int errorActual = 0;

  /// Target number of errors.
  int errorTarget = 0;

  /// The number of times the onError callback was called.
  int onErrorCount = 0;

  Future<void> onError() async {
    onErrorCount++;
  }

  Future<void> operation() async {
    if (errorActual < errorTarget) {
      errorActual++;
      throw Exception('error');
    }
    didSucceed = true;
  }

  Future<void> run({
    int retries = 1,
    Duration waitAfter = const Duration(milliseconds: 1),
  }) async {
    assert(retries != null);
    assert(waitAfter != null);

    try {
      await runWithRetry(
        operation: operation,
        onError: onError,
        retries: retries,
        waitAfter: waitAfter,
      );
    } finally {
      expect(errorActual, errorTarget);
      expect(onErrorCount, errorTarget);
    }
  }
}
