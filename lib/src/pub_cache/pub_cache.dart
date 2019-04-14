import 'package:meta/meta.dart';
import 'package:pkgraph/src/models/package.dart';
import 'package:pub_semver/pub_semver.dart';

abstract class PubCache {
  /// Add a package version to the cache.
  void addPackageVersion(
    Package package, {
    @required String name,
    @required Version version,
  });

  /// Get a package version from the cache.
  Package getPackageVersion({
    @required String name,
    @required Version version,
  });

  // TODO: Provide empty instance of the default implementation
  factory PubCache.empty() => null;
}
