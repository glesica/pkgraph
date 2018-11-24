import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';
import 'package:pkgraph/src/pub/cache.dart';

/// A Cypher query to create the necessary constraint Source nodes so
/// that the source URL is a unique key.
///
/// This will prevent the creation of duplicate Source nodes and
/// improve query performance. This statement only needs to be run once.
Statement sourceConstraintStatement() => Statement(
    statement: 'CREATE CONSTRAINT ON (s:Source) ASSERT s.url IS UNIQUE;');

/// A cypher query to insert a Version node, along with its Source and
/// Package nodes if they don't already exist.
Statement packageVersionStatement(PackageVersion package) =>
    Statement(statement: '''
        MERGE (s:Source {url: {source}})
        MERGE (s)<-[:HOSTED_ON]-(p:Package {name: {package}, source_url: {source}})
        MERGE (p)-[:HAS_VERSION]->(v:Version {version: {version}, package_name: {package}})
          ON CREATE SET
            v.ordinal = {ordinal},
            v.major = {major},
            v.minor = {minor},
            v.patch = {patch},
            v.build = {build},
            v.preRelease = {preRelease},
            v.dart1 = {dart1},
            v.dart2 = {dart2},
            v.homepage = {homepage}
    ''')
      ..set('source', package.source)
      ..set('package', package.name)
      ..set('version', package.version.toString())
      ..set('ordinal', package.ordinal)
      ..set('major', package.major)
      ..set('minor', package.minor)
      ..set('patch', package.patch)
      ..set('build', package.build)
      ..set('preRelease', package.preRelease)
      ..set('dart1', package.sdk.allowsAny(dart1Versions))
      ..set('dart2', package.sdk.allowsAny(dart2Versions))
      ..set('homepage', package.homepage?.toString() ?? '');

/// Create statements to insert dependency edges for all dependencies
/// of the given package.
///
/// This function relies heavily on the cache, either the one passed in
/// or the default cache. If any of the dependent packages is missing
/// from the cache, it will throw.
Iterable<Statement> packageDependenciesStatements(
  PackageVersion package, {
  Cache cache,
}) {
  assert(package != null);

  cache ??= defaultCache;

  final statements = <Statement>[];
  for (final dependency in package.allDependencies) {
    // Filter package versions to only those that match the constraint.
    final dependencyVersions = cache
        .get(
          packageName: dependency.packageName,
          source: dependency.source,
        )
        .where((dependencyVersion) =>
            dependency.constraint.allows(dependencyVersion.version));
    for (final dependencyVersion in dependencyVersions) {
      // Build a statement that creates a relationship between the
      // package version and the dependent package version as shown.
      // (package:Version)-[:MAY_USE]->(dependency:Version)
      final statement = Statement(statement: '''
          MATCH (s:Source {url: {source}})<-[:HOSTED_ON]-
                (p:Package {name: {package}})-[:HAS_VERSION]->
                (v:Version {version: {version}}),
                (ds:Source {url: {depSource}})<-[:HOSTED_ON]-
                (dp:Package {name: {depPackage}})-[:HAS_VERSION]->
                (dv:Version {version: {depVersion}})
          MERGE (v)-[:MAY_USE]->(dv)
      ''')
        ..set('source', package.source)
        ..set('package', package.name)
        ..set('version', package.version.toString())
        ..set('depSource', dependencyVersion.source)
        ..set('depPackage', dependencyVersion.name)
        ..set('depVersion', dependencyVersion.version.toString());
      statements.add(statement);
    }
  }

  return statements;
}
