import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/models/dependency.dart';
import 'package:pkgraph/src/models/from_json.dart';

part 'package_version.g.dart';

final _logger = Logger('package_version.dart');

/// A model that represents a specific version of a particular package.
@JsonSerializable(nullable: false)
class PackageVersion {
  /// A single author in the case where this key is used instead of
  /// the plural in the pubspec.
  ///
  /// TODO: Use this in place of the plural version if it is set
  @JsonKey(defaultValue: '', nullable: true)
  final String author;

  /// The list of author strings for this version.
  ///
  /// TODO: Think about parsing the author strings themselves
  @JsonKey(defaultValue: const [], nullable: true)
  final Iterable<String> authors;

  /// The list of dependencies for this version.
  @JsonKey(fromJson: _toDependencies)
  final Iterable<Dependency> dependencies;

  /// The package description for this version.
  final String description;

  /// The list of dev dependencies for this version.
  @JsonKey(name: 'dev_dependencies', fromJson: _toDependencies, toJson: _fromDependencies)
  final Iterable<Dependency> devDependencies;

  /// The URI of the package's homepage.
  @JsonKey(nullable: true)
  final Uri homepage;

  /// Package name. Should not change across versions.
  final String name;

  int _ordinal;

  /// SDK version constraint required by this version of the package.
  @JsonKey(name: 'environment', fromJson: _toSdk)
  final VersionConstraint sdk;

  String _source;

  /// The version of the package represented by this object.
  @JsonKey(fromJson: toVersion)
  final Version version;

  // TODO: It's unfortunate that we have to expose this publicly
  PackageVersion({
    @required this.author,
    @required this.authors,
    @required this.dependencies,
    @required this.description,
    @required this.devDependencies,
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
  Iterable<Dependency> get allDependencies =>
      []..addAll(dependencies)..addAll(devDependencies);

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

  Map<String, dynamic> toJson() => _$PackageVersionToJson(this);

  @override
  String toString() => '$source/$name @ $version';
}

Iterable<Dependency> _toDependencies(Map<String, dynamic> value) {
  // TODO: Handle git dependencies https://www.dartlang.org/tools/pub/dependencies#git-packages
  // TODO: Handle SDK dependencies https://www.dartlang.org/tools/pub/dependencies#sdk
  // TODO: Make sure there's no reason to use the "inner" hosted package name
  if (value == null) {
    return const [];
  }

  final dependencies = <Dependency>[];
  for (final entry in value.entries) {
    _logger.fine('parsing dependency: $entry');

    final entryKey = entry.key;
    final entryValue = entry.value;

    String constraint;
    String source;

    if (entryValue is Map<String, dynamic>) {
      if (entryValue.containsKey('version') &&
          entryValue.containsKey('hosted')) {
        // Handle a hosted dependency from a non-default pub server, example:
        // dependencies:
        //   transmogrify:
        //     hosted:
        //       name: transmogrify
        //       url: http://your-package-server.com
        //     version: ^1.4.0
        constraint = entryValue['version'] as String ?? 'any';
        source = entryValue['hosted']['url'] as String;
      } else {
        // There's a weird older schema that looks like this, just skip it.
        // dependencies:
        //   unittest
        //     sdk: unittest
        if (entryValue.containsKey('sdk')) {
          _logger.warning('skipping obsolete dependency $entry');
          continue;
        }

        if (entryValue.containsKey('path')) {
          _logger.warning('skipping path dependency $entry');
          continue;
        }

        if (entryValue.containsKey('git')) {
          _logger.warning('skipping git dependency $entry');
          continue;
        }
      }
    } else {
      // Handle a hosted dependency from the default pub server, example:
      // dependencies:
      //   transmogrify: ^1.4.0
      constraint = entryValue as String ?? 'any';
      source = defaultSource;
    }

    dependencies.add(Dependency(
      constraint: VersionConstraint.parse(constraint),
      packageName: entryKey,
      source: source,
    ));
  }

  return dependencies;
}

VersionConstraint _toSdk(Map<String, dynamic> value) {
  if (value == null) {
    return VersionConstraint.parse('0.0.0');
  }

  return VersionConstraint.parse(value['sdk'] as String);
}
