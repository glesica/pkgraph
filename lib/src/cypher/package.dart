import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';

/// A Cypher query to create the necessary constraint Source nodes so
/// that the source URL is a unique key. This will prevent the creation
/// of duplicate Source nodes and improve query performance. This
/// statement only needs to be run once.
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
              v.preRelease = {preRelease}
        MERGE (v)<-[:HAS_VERSION]-(p)-[:HOSTED_ON]->(s);''')
      ..set('package', package.name)
      ..set('source', package.source)
      ..set('version', package.version.toString())
      ..set('ordinal', package.ordinal)
      ..set('major', package.major)
      ..set('minor', package.minor)
      ..set('patch', package.patch)
      ..set('build', package.build)
      ..set('preRelease', package.preRelease);

// Plan:
// We need to make sure that all dependencies are loaded before we can
// actually link them together. Also, we're going to need to know the
// source for dependencies, that's fine, we can assume the public server
// until we add support for private pub servers and then we'll know
// if it should differ. I think we're going to need a way to get all
// versions of a package by source and name so that we can determine
// which ones we actually need to link together. That code should probably
// go someplace else, not here. Maybe we define a cache of some kind
// and then we can say something like packageVersion.getDep(src, name,
// cache), where it would return Iterable<PackageVersion> that match its
// constraint on the given dep. Problem, what if it doesn't have that
// dep?

Iterable<Statement> packageDependenciesStatements(PackageVersion package) =>
    package.dependencies.map((dependency) => Statement(statement: '''
        MATCH (s:Source {url: {source}})
        <-[:HOSTED_ON]-(p:Package {name: {package}})
        -[:HAS_VERSION]->(v:Version {version: {version}})
        MERGE (d: OK THIS IS WHERE IT GETS TRICKY
    '''));
