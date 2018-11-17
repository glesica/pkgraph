import 'package:meta/meta.dart';
import 'package:pkgraph/src/models/package_version.dart';

/// Cache to allow package versions to be held in memory to avoid
/// having to re-fetch packages from the pub server when we resolve
/// package dependencies.
class Cache {
  /// This field stores a map from source to a map from package
  /// name to an iterable of [PackageVersion] objects associated
  /// with the named package.
  Map<String, Map<String, Iterable<PackageVersion>>> _packageVersions;

  Iterable<PackageVersion> get({
    @required Iterable<PackageVersion> orElse(),
    @required String packageName,
    @required String source,
  }) {
    assert(orElse != null);
    assert(packageName != null);
    assert(source != null);

    final packageVersionsMap = _packageVersions[source];
    if (packageVersionsMap == null) {
      return orElse();
    }

    final packageVersions = packageVersionsMap[packageName];
    if (packageVersions == null) {
      return orElse();
    }

    return packageVersions;
  }

  void set({
    @required String source,
    @required String packageName,
    @required Iterable<PackageVersion> packageVersions,
  }) {
    final sourcesMap = _packageVersions;
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
      throw CacheException(packageName: packageName, source: source);
    }
  }
}

class CacheException implements Exception {
  final String packageName;

  final String source;

  CacheException({
    @required this.packageName,
    @required this.source,
  });

  @override
  String toString() =>
      'DoubleCacheException - packageName: $packageName source: $source';
}
