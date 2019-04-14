import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// Call a function and catch all errors, retrying a certain number of
/// times.
///
/// The maximum number of times the operation may run is `retries + 1`.
///
/// TODO: Improve how we handle the intermediate errors
/// We probably want to have the onError callback accept the error and
/// stack trace, along with the retries remaining so the behavior can
/// be customized, but for now it's fine.
///
/// If `onError` is provided, it will be called each time the
/// operation fails.
///
/// If `orElse` is provided, it will be called in the case that all
/// retries fail and its result will be returned as the result of
/// the function.
///
/// If `validate` is provided, it should throw an exception if the
/// result it receives is invalid or should otherwise cause a retry.
///
/// `waitAfter` determines the time to wait before each retry.
Future<T> runWithRetry<T>({
  @required Future<T> operation(),
  Logger logger,
  Future<void> onError(),
  Future<T> orElse(),
  int retries = 2,
  Future<void> validate(T result),
  Duration waitAfter = const Duration(seconds: 5),
}) async {
  assert(operation != null);
  assert(retries != null);
  assert(waitAfter != null);

  T result;

  for (var i = 0; i <= retries; i++) {
    final remaining = retries - i;

    try {
      result = await operation();

      if (validate != null) {
        await validate(result);
      }

      break;
    } catch (error, stackTrace) {
      logger?.info(
        'operation failed ($remaining attempts left)'
            ' error:\n$error\n$stackTrace',
      );

      result = null;

      if (onError != null) {
        await onError();
      }

      if (remaining == 0 && orElse == null) {
        rethrow;
      }

      if (remaining > 0) {
        await Future.delayed(waitAfter);
      }
    }
  }

  if (result == null && orElse != null) {
    return await orElse();
  }

  return result;
}
