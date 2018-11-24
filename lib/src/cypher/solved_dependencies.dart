import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/models/solved_dependency.dart';

/// A statement to insert a solved dependency relationship between
/// a package version and the version of one of its dependencies
/// that it solved to when `pub get` was run.
Statement solvedDependencyStatement(PackageVersion originPackageVersion,
        SolvedDependency solvedDependency) =>
    Statement(statement: '''
        MATCH (:Source {url: {originSource}})<-[:HOSTED_ON]-
              (:Package {name: {origin}})-[:HAS_VERSION]->
              (v:Version {version: {originVersion}}),
              (:Source {url: {dependencySource}})<-[:HOSTED_ON]-
              (:Package {name: {dependency}})-[:HAS_VERSION]->
              (dv:Version {version: {dependencyVersion}})
        MERGE (v)-[r:SOLVED_TO]->(dv)
          ON CREATE SET
            r.type = {type}
    ''')
      ..set('originSource', originPackageVersion.source)
      ..set('origin', originPackageVersion.name)
      ..set('originVersion', originPackageVersion.version.toString())
      ..set('dependencySource', solvedDependency.source)
      ..set('dependency', solvedDependency.name)
      ..set('dependencyVersion', solvedDependency.version.toString())
      ..set('type', solvedDependency.type.name);
