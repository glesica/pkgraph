import 'dart:convert' show json;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pkgraph/src/models/package.dart';
import 'package:pkgraph/src/pub_cache/pub_cache.dart';
import 'package:pkgraph/src/retry.dart';
import 'package:pub_semver/pub_semver.dart';

final _logger = Logger('fetch');
final _rateLimiters = <String, Future<void>>{};

const defaultSource = 'https://pub.dartlang.org';

Future<Package?> fetchPackageVersion({
  required String name,
  required Version version,
  PubCache? cache,
  Uri? source,
}) async {
  Package? package = cache?.getPackageVersion(
    name: name,
    version: version,
  );
  if (package != null) {
    return package;
  }

  final sourceString = source?.toString() ?? defaultSource;

  await _rateLimiters[sourceString];
  _rateLimiters[sourceString] = Future.delayed(Duration(seconds: 1));

  final versionUrl = [
    sourceString,
    'api',
    'packages',
    name,
    'versions',
    version.toString(),
  ].join('/');

  // We can't handle git or path dependencies right now so just bail.
  if (!versionUrl.startsWith('http')) {
    return null;
  }

  final versionUri = Uri.parse(versionUrl);

  final response = await runWithRetry<http.Response>(
      operation: () => http.get(versionUri),
      logger: _logger,
      validate: (response) async {
        if (response.statusCode != 200) {
          throw Exception(
            '"$versionUrl" returned status code ${response.statusCode}',
          );
        }
      });
  final jsonBody = json.decode(response!.body);

  package = Package.fromJson(jsonBody);

  cache?.addPackageVersion(
    package,
    name: name,
    version: version,
  );

  return package;
}
