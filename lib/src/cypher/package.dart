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
        MERGE (p:Package {name: {package}})
        MERGE (v:Version {version: {version}})
          SET v.ordinal = {ordinal},
              v.major = {major},
              v.minor = {minor},
              v.patch = {patch},
              v.build = {build},
              v.preRelease = {preRelease},
              v.homepage = {homepage}
        MERGE (p)-[:HOSTED_ON]->(s)
        MERGE (p)-[:HAS_VERSION]->(v);''')
      ..set('source', package.source)
      ..set('package', package.name)
      ..set('version', package.version.toString())
      ..set('ordinal', package.ordinal)
      ..set('major', package.major)
      ..set('minor', package.minor)
      ..set('patch', package.patch)
      ..set('build', package.build)
      ..set('preRelease', package.preRelease)
      ..set('homepage', package.homepage?.toString() ?? '');

/// Create statements to insert dependency edges for all dependencies
/// of the given package.
///
/// This function relies heavily on the cache, either the one passed in
/// or the default cache. If any of the dependent packages is missing
/// from the cache, it will throw.
///
/// TODO: This should error if dependencies haven't been added yet
Iterable<Statement> packageDependenciesStatements(
  PackageVersion package, {
  Cache cache,
}) {
  assert(package != null);

  cache ??= defaultCache;

  final statements = <Statement>[];
  for (final dependency in package.dependencies) {
    // Filter package versions to only compatible
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
          MATCH (s:Source {url: {source}}),
                (p:Package {name: {package}})-[:HOSTED_ON]->(s),
                (v:Version {version: {version}})<-[:HAS_VERSION]-(p),
                (ds:Source {url: {depSource}}),
                (dp:Package {name: {depPackage}})-[:HOSTED_ON]->(ds),
                (dv:Version {version: {depVersion}})<-[:HAS_VERSION]-(dp)
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
