import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:pkgraph/src/models/dependency_type.dart';
import 'package:pkgraph/src/models/from_json.dart';

part 'solved_dependency.g.dart';

/// A container for a solved dependency from a pubspec.lock file.
///
/// Some schema examples are shown below.
///
/// yaml:
///   dependency: "direct main"
///   description:
///     name: yaml
///     url: "https://pub.dartlang.org"
///   source: hosted
///   version: "2.1.15"
///
/// TODO: Need to handle solved path dependencies
@JsonSerializable(nullable: false)
class SolvedDependency {
  /// A container for the description object so that we can
  /// reference its fields to extract name and source (url).
  final Map<String, dynamic> _description;

  /// The type of the dependency: direct (main), direct (dev),
  /// and transitive.
  @JsonKey(name: 'dependency', fromJson: toDependencyType)
  final DependencyType type;

  /// Version of the dependency that was solved.
  @JsonKey(fromJson: toVersion)
  final Version version;

  SolvedDependency({
    @required Map<String, String> description,
    @required this.type,
    @required this.version,
  }) : _description = description;

  factory SolvedDependency.fromJson(Map<String, dynamic> json) =>
      _$SolvedDependencyFromJson(json);

  /// Name of the package depended upon.
  @JsonKey(ignore: true)
  String get name => _description['name'] as String;

  /// Source (pub server) where the dependency comes from.
  @JsonKey(ignore: true)
  String get source => _description['url'] as String;
}

/// Convert a string to a [DependencyType] for deserialization.
DependencyType toDependencyType(String value) {
  switch (value) {
    case 'direct main':
      return DependencyType.directMain;
    case 'direct dev':
      return DependencyType.directDev;
    case 'transitive':
      return DependencyType.transitive;
    default:
      throw ArgumentError.value(
        value,
        'value',
        'is not a valid dependency type',
      );
  }
}
