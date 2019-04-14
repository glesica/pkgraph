import 'dart:convert' show json;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pkgraph/src/models/package.dart';
import 'package:pkgraph/src/pub_cache/pub_cache.dart';
import 'package:pkgraph/src/retry.dart';
import 'package:pub_semver/pub_semver.dart';

final _logger = Logger('fetch');

const defaultSource = 'https://pub.dartlang.org';

Future<Package> fetchPackageVersion({
  @required String name,
  @required Version version,
  PubCache cache,
  Uri source,
}) async {
  Package package = cache?.getPackageVersion(
    name: name,
    version: version,
  );
  if (package != null) {
    return package;
  }

  final versionUrl = [
    source?.toString() ?? defaultSource,
    'api',
    'packages',
    name,
    'versions',
    version.toString(),
  ].join('/');

  final response = await runWithRetry<http.Response>(
    operation: () => http.get(versionUrl),
    logger: _logger,
    validate: (response) async {
      if (response.statusCode != 200) {
        throw Exception('Status code was ${response.statusCode}');
      }
    }
  );
  final jsonBody = json.decode(response.body);

  package = Package.fromJson(jsonBody);

  cache?.addPackageVersion(
    package,
    name: name,
    version: version,
  );

  return package;
}
