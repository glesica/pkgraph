import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

/// A dependency specified by a given package version.
class Dependency {
  /// The version constraint given for this dependency.
  final VersionConstraint constraint;

  /// The name of the package depended upon.
  final String name;

  Dependency({
    @required this.constraint,
    @required this.name,
  });
}