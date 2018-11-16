import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';

/// A Cypher query to create the necessary constraints for packages
/// and their sources.
Statement packageConstraintsStatement() => Statement(statement: '''
      CREATE CONSTRAINT ON (s:Source) ASSERT s.url IS UNIQUE
      CREATE CONSTRAINT ON (a:Author) ASSERT a.id IS UNIQUE''');

/// A cypher query to insert a package version, along with its source.
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
        MERGE (v)<-[:HAS_VERSION]-(p)-[:HOSTED_ON]->(s)''')
      ..set('package', package.name)
      ..set('source', package.source)
      ..set('version', package.version.toString())
      ..set('ordinal', package.ordinal)
      ..set('major', package.major)
      ..set('minor', package.minor)
      ..set('patch', package.patch)
      ..set('build', package.build)
      ..set('preRelease', package.preRelease);

Iterable<Statement> packageAuthorStatements(PackageVersion package) =>
    package.authors.map((author) => Statement(statement: '''
        MATCH (s:Source {url: {source}})
        <-[:HOSTED_ON]-(p:Package {name: {package}})
        -[:HAS_VERSION]->(v:Version {version: {version}})
        MERGE (a:Author {name: {author}})
        MERGE (v)-[:HAS_AUTHOR]->(a)''')
      ..set('source', package.source)
      ..set('package', package.name)
      ..set('version', package.version.toString())
      ..set('author', author));
