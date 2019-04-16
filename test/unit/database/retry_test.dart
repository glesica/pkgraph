import 'package:test/test.dart';

import 'retry_harness.dart';

void main() {
  group('runWithRetry', () {
    group('when operation throws', () {
      test('should retry and succeed', () async {
        final harness = RetryHarness()..errorTarget = 1;
        await harness.run(retries: 1);
        expect(harness.didSucceed, isTrue);
      });

      test('should retry and fail', () {
        final harness = RetryHarness()..errorTarget = 2;
        expect(() => harness.run(retries: 1), throwsException);
        expect(harness.didSucceed, isFalse);
      });

      test('should wait between retries', () async {
        final harness = RetryHarness()..errorTarget = 5;
        int start = DateTime.now().millisecondsSinceEpoch;
        await harness.run(retries: 5, waitAfter: Duration(milliseconds: 100));
        int end = DateTime.now().millisecondsSinceEpoch;
        expect(harness.didSucceed, isTrue);
        expect(end - start, greaterThanOrEqualTo(500));
      });
    });

    group('when operation does not throw', () {
      test('should succeed', () async {
        final harness = RetryHarness();
        await harness.run();
        expect(harness.didSucceed, isTrue);
      });
    });
  });
}
