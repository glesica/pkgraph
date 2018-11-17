import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:pkgraph/src/models/dependency.dart';

part 'package_version.g.dart';

/// A model that represents a specific version of a particular package.
@JsonSerializable(nullable: false)
class PackageVersion {
  /// A single author in the case where this key is used instead of
  /// the plural in the pubspec.
  ///
  /// TODO: Use this in place of the plural version if it is set
  final String author;

  /// The list of author strings for this version.
  ///
  /// TODO: Think about parsing the author strings themselves
  final Iterable<String> authors;

  /// The list of dependencies for this version.
  @JsonKey(fromJson: _toDependencies)
  final Iterable<Dependency> dependencies;

  /// The package description for this version.
  final String description;

  /// The URI of the package's homepage.
  final Uri homepage;

  /// Package name. Should not change across versions.
  final String name;

  int _ordinal;

  /// SDK version constraint required by this version of the package.
  @JsonKey(name: 'environment', fromJson: _toSdk)
  final VersionConstraint sdk;

  String _source;

  /// The version of the package represented by this object.
  @JsonKey(fromJson: _toVersion)
  final Version version;

  // TODO: It's unfortunate that we have to expose this publicly
  PackageVersion({
    @required this.author,
    @required this.authors,
    @required this.dependencies,
    @required this.description,
    @required this.homepage,
    @required this.name,
    int ordinal,
    @required this.sdk,
    String source,
    @required this.version,
  })  : _ordinal = ordinal,
        _source = source;

  factory PackageVersion.fromJson(
    Map<String, dynamic> json, {
    @required int ordinal,
    @required String source,
  }) =>
      _$PackageVersionFromJson(json)
        .._ordinal = ordinal
        .._source = source;

  @JsonKey(ignore: true)
  int get major => version.major;

  @JsonKey(ignore: true)
  int get minor => version.minor;

  @JsonKey(ignore: true)
  int get patch => version.patch;

  @JsonKey(ignore: true)
  String get preRelease => version.preRelease.join('_');

  @JsonKey(ignore: true)
  String get build => version.build.join('_');

  /// The position in the order of releases of this version of the package.
  /// This allows querying for version ranges in the database, where we
  /// can't properly interpret semantic versions otherwise.
  @JsonKey(ignore: true)
  int get ordinal => _ordinal;

  /// The pub server from whence this package came. This becomes a node
  /// in the graph to which the package version will be attached.
  @JsonKey(ignore: true)
  String get source => _source;

  @override
  String toString() => '$source/$name @ $version';
}

Iterable<Dependency> _toDependencies(Map<String, dynamic> value) {
  // TODO: Handle git dependencies
  // TODO: Handle path dependencies (somehow)
  // TODO: Handle dependencies on custom pub servers
  if (value == null) {
    return [];
  }

  return value.entries.map((entry) {
    final constraint = VersionConstraint.parse(entry.value as String);
    final name = entry.key;
    return Dependency(constraint: constraint, name: name);
  });
}

Version _toVersion(String value) => Version.parse(value);

VersionConstraint _toSdk(Map<String, dynamic> value) {
  if (value == null) {
    return VersionConstraint.parse('0.0.0');
  }

  return VersionConstraint.parse(value['sdk'] as String);
}
