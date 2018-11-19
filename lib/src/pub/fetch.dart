import 'dart:async';
import 'dart:collection';
import 'dart:convert' show json;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/pub/cache.dart';

final _logger = Logger('fetch.dart');

/// Fetch all versions of the given package from the given source
/// (pub server).
///
/// TODO: Use a `Uri` for the source instead of a string
Future<Iterable<PackageVersion>> fetchPackageVersions(
  String packageName, {
  Cache cache,
  String source = defaultSource,
}) async {
  assert(packageName != null);
  assert(source != null);

  cache ??= defaultCache;

  if (cache.contains(
    packageName: packageName,
    source: source,
  )) {
    _logger.info('cache hit on $packageName from $source');
    return cache.get(packageName: packageName, source: source);
  }

  // Not sure what the rate limit looks like on the public pub server so
  // we'll do this just in case.
  // TODO: Make this user-configurable
  await Future.delayed(Duration(seconds: 1));

  final url = '$source$packageEndpoint$packageName';

  _logger.info('requesting $url');
  final response = await http.get(url);
  _logger.fine('response body from $url: ${response.body}');

  // TODO: Deal with various non-200 status codes more intelligently
  if (response.statusCode != 200) {
    _logger.warning('received ${response.statusCode} from $url');
    // TODO: Consider unwinding the whole fetch and skipping the root package
    return const [];
  }

  final jsonBody = json.decode(response.body);
  final jsonVersions = jsonBody['versions'] as List<dynamic>;
  _logger.info('fetching ${jsonVersions.length} versions from $url');

  final packageVersions = <PackageVersion>[];
  for (int i = 0; i < jsonVersions.length; i++) {
    final jsonVersion = jsonVersions[i] as Map<String, dynamic>;
    final pubspec = jsonVersion['pubspec'] as Map<String, dynamic>;
    packageVersions.add(PackageVersion.fromJson(
      pubspec,
      ordinal: i,
      source: source,
    ));
  }

  cache.set(
    packageName: packageName,
    source: source,
    packageVersions: packageVersions,
  );

  return packageVersions;
}

/// Recursively populate a [Cache] starting at the given package.
///
/// Any package versions that depend on packages that have been removed
/// from their respective pub server will be omitted from the cache. For
/// example, if version 1.0.0 of package A depends on some version of
/// package B, but version 2.0.0 of package A does not depend on any
/// version of package B, and package B has since disappeared from its
/// pub server, then the cache will include version 2.0.0 of package A,
/// but not version 1.0.0 of package A. In this scenario the cache will
/// also not include any version of package B.
Future<void> populatePackagesCache(
  String originPackageName, {
  Cache cache,
  String source = defaultSource,
}) async {
  assert(originPackageName != null);
  assert(source != null);

  cache ??= defaultCache;

  final packageQueue = Queue.of([_QueuedPackage(originPackageName, source)]);
  final packagesSeen = Set<_QueuedPackage>();
  final emptyPackages = Set<_QueuedPackage>();

  while (packageQueue.isNotEmpty) {
    final nextQueuedPackage = packageQueue.removeFirst();

    // Check if we've seen this one before, if so, we're good to go,
    // if not, record it and move on.
    if (packagesSeen.contains(nextQueuedPackage)) {
      continue;
    }
    packagesSeen.add(nextQueuedPackage);

    final nextPackageVersions = await fetchPackageVersions(
      nextQueuedPackage.packageName,
      cache: cache,
      source: nextQueuedPackage.source,
    );

    if (nextPackageVersions.isEmpty) {
      emptyPackages.add(nextQueuedPackage);
    }

    // Queue up all package dependencies. Those that have already been
    // fetched will be skipped when they pop up.
    for (final nextPackageVersion in nextPackageVersions) {
      for (final dependency in nextPackageVersion.dependencies) {
        packageQueue
            .add(_QueuedPackage(dependency.packageName, dependency.source));
      }
    }
  }

  // Remove packages that depend on packages we couldn't find.
  cache.prune(shouldPrune: (packageVersion) {
    return packageVersion.dependencies.any((dependency) {
      return emptyPackages.any((queuedPackage) {
        return dependency.packageName == queuedPackage.packageName &&
            dependency.source == queuedPackage.source;
      });
    });
  });
}

/// A package waiting to be fetched.
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
