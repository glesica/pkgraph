import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/models/solved_dependency.dart';

/// A statement to insert a solved dependency relationship between
/// a package version and the version of one of its dependencies
/// that it solved to when `pub get` was run.
Statement solvedDependencyStatement(PackageVersion originPackageVersion,
        SolvedDependency solvedDependency) =>
    Statement(statement: '''
        MATCH (:Package {name: {origin}})-[:HAS_VERSION]->
              (v:Version {version: {originVersion}})-[:HOSTED_ON]->
              (:Source {url: {originSource}}),
              (:Package {name: {dependency}})-[:HAS_VERSION]->
              (d:Version {version: {dependencyVersion}})-[:HOSTED_ON]->
              (:Source {url: {dependencySource}})
        MERGE (v)-[r:SOLVED_TO]->(d)
          ON CREATE SET
            r.type = {type}
    ''')
      ..set('origin', originPackageVersion.name)
      ..set('originVersion', originPackageVersion.version.toString())
      ..set('originSource', originPackageVersion.source)
      ..set('dependency', solvedDependency.name)
      ..set('dependencyVersion', solvedDependency.version.toString())
      ..set('dependencySource', solvedDependency.source)
      ..set('type', solvedDependency.type.name);
