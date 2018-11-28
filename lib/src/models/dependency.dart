import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// A dependency specified by a given package version.
class Dependency {
  /// The version constraint given for this dependency.
  final VersionConstraint constraint;

  /// The name of the package depended upon.
  final String packageName;

  /// The pub server form which this dependency is to be satisfied.
  final String source;

  Dependency({
    @required this.constraint,
    @required this.packageName,
    @required this.source,
  });
}
