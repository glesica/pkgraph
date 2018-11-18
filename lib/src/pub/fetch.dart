import 'dart:async';
import 'dart:collection';
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

Future<Iterable<PackageVersion>> recursiveFetchPackageVersions(
  String packageName, {
  Cache cache,
  bool https = true,
  String source = defaultSource,
}) async {
  assert(packageName != null);
  assert(https != null);
  assert(source != null);

  final packageVersions = <PackageVersion>[];

  final packageQueue = Queue.of([_QueuedPackage(packageName, source)]);
  final packagesSeen = Set<_QueuedPackage>();

  while (packageQueue.isNotEmpty) {
    final nextQueuePackage = packageQueue.removeFirst();

    // Check if we've seen this one before, if so, we're good to go,
    // if not, record it and move on.
    if (packagesSeen.contains(nextQueuePackage)) {
      continue;
    }
    packagesSeen.add(nextQueuePackage);

    final nextPackageVersions = await fetchPackageVersions(
      nextQueuePackage.packageName,
      cache: cache,
      https: https,
      source: nextQueuePackage.source,
    );

    for (final nextPackageVersion in nextPackageVersions) {
      packageVersions.add(nextPackageVersion);

      // Should we just hydrate the PackageVersion object with enough
      // info about its dependencies to create relationships and not
      // worry about hitting all the package versions up front? Either
      // way this approach won't give us enough information to actually
      // compute which dependency versions we should have relationships
      // to because we're just going to end up with a flat list.

      // Queue up dependencies
      nextPackageVersion.dependencies.forEach((dependency) {
        final nextQueueDependency = _QueuedPackage(dependency.name, );
      });
    }
  }

  return packageVersions;
}

class _QueuedPackage {
  final String packageName;
  final String source;

  _QueuedPackage(this.packageName, this.source);

  @override
  int get hashCode => packageName.hashCode ^ source.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is _QueuedPackage &&
      other.packageName == packageName &&
      other.source == source;
}
