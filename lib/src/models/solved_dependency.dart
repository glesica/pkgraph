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
@JsonSerializable(
  nullable: false,
  createToJson: false,
  generateToJsonFunction: false,
)
class SolvedDependency {
  /// A container for the description object so that we can
  /// reference its fields to extract name and source (url).
  @JsonKey(fromJson: _toDescription)
  final Description description;

  /// The type of the dependency: direct (main), direct (dev),
  /// and transitive.
  @JsonKey(name: 'dependency', fromJson: _toDependencyType)
  final DependencyType type;

  /// Version of the dependency that was solved.
  @JsonKey(fromJson: toVersion)
  final Version version;

  SolvedDependency({
    @required this.description,
    @required this.type,
    @required this.version,
  });

  factory SolvedDependency.fromJson(Map<String, dynamic> json) =>
      _$SolvedDependencyFromJson(json);

  /// Name of the package depended upon.
  @JsonKey(ignore: true)
  String get name => description.name;

  /// Source (pub server) where the dependency comes from.
  @JsonKey(ignore: true)
  String get source => description.source;
}

/// Convert a string to a [DependencyType] for deserialization.
DependencyType _toDependencyType(String value) {
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

/// Convert a map to a [Description] instance.
Description _toDescription(Map<String, dynamic> value) => Description(
      name: value['name'] as String,
      source: value['url'] as String,
    );

/// A class to hold the description fields for a solved dependency.
///
/// TODO: Remove once json_serializable adds support for duplicate field names
class Description {
  final String name;

  final String source;

  Description({
    @required this.name,
    @required this.source,
  });
}
