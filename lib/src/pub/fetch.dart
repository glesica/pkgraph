import 'dart:async';
import 'dart:convert' show json;

import 'package:http/http.dart' as http;

import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/pub/cache.dart';

const defaultSource = 'pub.dartlang.org';
const packageEndpoint = '/api/packages/';

final defaultCache = Cache();

/// Fetch all versions of the given package from the given source
/// (pub server).
Future<Iterable<PackageVersion>> fetchPackageVersions(
  String packageName, {
  Cache cache,
  bool https = true,
  String source = defaultSource,
}) async {
  assert(packageName != null);
  assert(https != null);
  assert(source != null);

  cache ??= defaultCache;

  final url =
      '${https ? 'https' : 'http'}://$source$packageEndpoint$packageName';
  final response = await http.get(url);
  final jsonBody = json.decode(response.body);
  final jsonVersions = jsonBody['versions'] as List<dynamic>;

  final packageVersions = <PackageVersion>[];
  for (int i = 0; i < jsonVersions.length; i++) {
    final jsonVersion = jsonVersions[i] as Map<String, dynamic>;
    final pubspec = jsonVersion['pubspec'] as Map<String, dynamic>;
    packageVersions.add(PackageVersion.fromJson(
      pubspec,
      ordinal: null,
      source: source,
    ));
  }

  cache.set(
    source: source,
    packageName: packageName,
    packageVersions: packageVersions,
  );

  return packageVersions;
}
