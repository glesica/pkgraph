import 'dart:async';
import 'dart:collection';
import 'dart:convert' show json;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/models/solved_dependency.dart';
import 'package:pkgraph/src/pub/cache.dart';
import 'package:pkgraph/src/pub/load_yaml_map.dart';
import 'package:pkgraph/src/pub/path_to_package_name.dart';

/// Packages endpoint for a pub server.
const packageEndpoint = '/api/packages/';

final _logger = Logger('fetch.dart');

Iterable<SolvedDependency> fetchLocalSolvedPackages(
  String packagePath, {
  Cache cache,
}) {
  assert(packagePath != null);

  cache ??= defaultCache;

  final lockFilePath = path.join(packagePath, 'pubspec.lock');
  final pubspecContent = File(lockFilePath).readAsStringSync();
  final pubspec = loadYamlMap(pubspecContent);
  final solvedMaps = pubspec['packages'] as Map<String, dynamic>;

  final solvedDependencies = <SolvedDependency>[];
  for (final map in solvedMaps.values) {
    solvedDependencies.add(SolvedDependency.fromJson(map));
  }

  // Make sure that the origin package is in the cache so that we
  // can grab it later when we add the solved relationships.
  final packageName = pathToPackageName(packagePath);
  if (!cache.contains(packageName: packageName, source: localSource)) {
    fetchLocalPackageVersions(packagePath, cache: cache);
  }

  return solvedDependencies;
}

/// Fetch a package version from a local directory containing a
/// pubspec.yaml file, presumably a Dart package or application.
///
/// Note that even though this returns an iterable there will
/// only ever be one package returned. This may change in the
/// future if we decide to do something tricky to get additional
/// available local versions, but it's not even clear if that
/// would really make sense, so here we are.
///
/// TODO: Cache won't work right if someone else depends on the local package
Future<Iterable<PackageVersion>> fetchLocalPackageVersions(
  String packagePath, {
  Cache cache,
}) async {
  assert(packagePath != null);

  cache ??= defaultCache;

  // TODO: This won't work for special paths like "." and ".."
  final packageName = pathToPackageName(packagePath);
  final source = localSource;

  if (cache.contains(
    packageName: packageName,
    source: source,
  )) {
    _logger.info('cache hit on $packageName from $source');
    return cache.get(packageName: packageName, source: source);
  }

  // TODO: Provide better error handling for file operations
  final pubspecPath = path.join(packagePath, 'pubspec.yaml');
  _logger.info('reading $pubspecPath');
  final pubspecContent = File(pubspecPath).readAsStringSync();
  final pubspec = loadYamlMap(pubspecContent);

  final packageVersion =
      PackageVersion.fromJson(pubspec, ordinal: 0, source: source);

  cache.set(
    packageName: packageName,
    source: source,
    packageVersions: [packageVersion],
  );

  return [packageVersion];
}

/// Fetch all versions of the given package from the given source
/// (pub server).
///
/// TODO: Use a `Uri` for the source instead of a string
Future<Iterable<PackageVersion>> fetchPubPackageVersions(
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

  // TODO: Use the retry function here to deal with spotty connections
  _logger.info('requesting $url');
  final response = await http.get(url);
  _logger.fine('response body from $url: ${response.body}');

  // TODO: Deal with various non-200 status codes more intelligently
  if (response.statusCode != 200) {
    _logger.warning('received ${response.statusCode} from $url');
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
  String originPackageNameOrPath, {
  Cache cache,
  bool isLocalPackage = false,
  String source = defaultSource,
}) async {
  assert(originPackageNameOrPath != null);
  assert(isLocalPackage != null);
  assert(source != null);

  cache ??= defaultCache;

  final packageQueue = Queue.of([
    _QueuedPackage(
      isLocalPackage: isLocalPackage,
      packageName: originPackageNameOrPath,
      source: source,
    ),
  ]);
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

    final nextPackageVersions = nextQueuedPackage.isLocalPackage
        ? await fetchLocalPackageVersions(nextQueuedPackage.packageName)
        : await fetchPubPackageVersions(
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
        // TODO: Once we parse local dependencies we need to set that here
        packageQueue.add(_QueuedPackage(
          packageName: dependency.packageName,
          source: dependency.source,
        ));
      }
    }
  }

  // Remove packages that depend on packages we couldn't find. This
  // generally corresponds to packages that have been removed from
  // the pub server for whatever reason. Package versions that depend
  // on these packages won't solve anyway, so we don't include them
  // in our graph.
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
  final bool isLocalPackage;
  final String packageName;
  final String source;

  _QueuedPackage({
    this.isLocalPackage = false,
    @required this.packageName,
    @required this.source,
  }) : assert(isLocalPackage != null);

  @override
  int get hashCode => packageName.hashCode ^ source.hashCode;

  @override
  bool operator ==(dynamic other) =>
      other is _QueuedPackage &&
      other.packageName == packageName &&
      other.source == source;
}
