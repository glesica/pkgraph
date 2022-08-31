import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _logger = Logger('retry.dart');

/// Call a function and catch all errors, retrying a certain number of
/// times.
///
/// The maximum number of times the operation may run is `retries + 1`.
///
/// TODO: Improve how we handle the intermediate errors
/// We probably want to have the onError callback accept the error and
/// stack trace, along with the retries remaining so the behavior can
/// be customized, but for now it's fine.
Future<void> runWithRetry({
  required Future<void> operation(),
  Future<void> onError()?,
  int retries = 2,
  Duration waitAfter = const Duration(seconds: 5),
}) async {
  for (var i = 0; i <= retries; i++) {
    final remaining = retries - i;

    try {
      await operation();
      break;
    } catch (error, stackTrace) {
      _logger.warning(
          'operation failed ($remaining attempts left) - error:\n$error\n$stackTrace');
      if (onError != null) {
        await onError();
      }
      if (remaining == 0) {
        rethrow;
      }

      await Future.delayed(waitAfter);
    }
  }
}
