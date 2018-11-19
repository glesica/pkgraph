import 'package:meta/meta.dart';

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/models/package_version.dart';

/// A default cache that will be used in all cases unless another
/// is provided. This simplifies the use-case that involves a
/// single-threaded, single-graph ETL operation.
final defaultCache = Cache();

/// Cache to allow package versions to be held in memory to avoid
/// having to re-fetch packages from the pub server when we resolve
/// package dependencies.
///
/// Note that this implementation is not thread-safe.
///
/// TODO: Make this serializable so it can be stored and re-used
class Cache {
  /// This field stores a map from source to a map from package
  /// name to an iterable of [PackageVersion] objects associated
  /// with the named package.
  Map<String, Map<String, Iterable<PackageVersion>>> _sourceToPackages = {};

  Iterable<PackageVersion> all() =>
      _sourceToPackages.values.expand((packageMap) {
        return packageMap.values.expand((packages) {
          return packages;
        });
      }).toList();

  bool contains({
    @required String packageName,
    String source = defaultSource,
  }) {
    assert(packageName != null);
    assert(source != null);

    final packageVersionsMap = _sourceToPackages[source];
    if (packageVersionsMap == null) {
      return false;
    }

    final packageVersions = packageVersionsMap[packageName];
    if (packageVersions == null) {
      return false;
    }

    return true;
  }

  Iterable<PackageVersion> get({
    Iterable<PackageVersion> orElse(),
    @required String packageName,
    String source = defaultSource,
  }) {
    assert(packageName != null);
    assert(source != null);

    if (!contains(
      packageName: packageName,
      source: source,
    )) {
      if (orElse == null) {
        throw CacheException.missing(packageName: packageName, source: source);
      }
      return orElse();
    }

    return _sourceToPackages[source][packageName];
  }

  /// Selectively remove any [PackageVersion] instance in the cache that
  /// satisfies the given callback.
  void prune({
    @required bool shouldPrune(PackageVersion packageVersion),
  }) {
    assert(shouldPrune != null);

    for (final source in _sourceToPackages.keys) {
      for (final packageName in _sourceToPackages[source].keys) {
        final packageVersions = _sourceToPackages[source][packageName];
        _sourceToPackages[source][packageName] =
            packageVersions.where((item) => !shouldPrune(item)).toList();
      }
    }
  }

  void set({
    String source = defaultSource,
    @required String packageName,
    @required Iterable<PackageVersion> packageVersions,
  }) {
    assert(packageName != null);
    assert(source != null);
    assert(packageVersions != null);

    final sourcesMap = _sourceToPackages;
    if (!sourcesMap.containsKey(source)) {
      sourcesMap[source] = <String, Iterable<PackageVersion>>{};
    }

    final packageVersionsMap = sourcesMap[source];
    if (!packageVersionsMap.containsKey(packageName)) {
      packageVersionsMap[packageName] = <PackageVersion>[]
        ..addAll(packageVersions);
    } else {
      // We should never add the same package from the same source
      // to the cache more than once. In that case, we should have
      // checked the cache and used the cached versions in the first
      // place. Note that the way we do this means it is unwise to
      // share this cache across threads.
      throw CacheException.duplicate(packageName: packageName, source: source);
    }
  }
}

class CacheException implements Exception {
  final String _error;

  final String packageName;

  final String source;

  CacheException.duplicate({
    @required this.packageName,
    @required this.source,
  }) : _error = 'duplicate package';

  CacheException.missing({
    @required this.packageName,
    @required this.source,
  }) : _error = 'missing package';

  @override
  String toString() =>
      'CacheException ($_error) - packageName: $packageName source: $source';
}
