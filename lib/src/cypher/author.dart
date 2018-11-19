import 'package:pkgraph/src/database/statement.dart';
import 'package:pkgraph/src/models/package_version.dart';

/// Create a statement that will create a new constraint to make the
/// author name a unique key. This will prevent the creation of duplicate
/// authors and make queries that start at an author more efficient.
/// This statement only needs to be run once.
Statement authorConstraintStatement() => Statement(
    statement: 'CREATE CONSTRAINT ON (a:Author) ASSERT a.name IS UNIQUE;');

/// Create the necessary statements to link together a package version
/// with its authors. This query relies on the Source, Package, and
/// Version nodes to already exist and will create a new Author node
/// for each author associated with the package version and a new
/// relationship between each author and the Version node.
Iterable<Statement> packageAuthorStatements(PackageVersion package) =>
    package.authors.map((author) => Statement(statement: '''
        MATCH (s:Source {url: {source}})<-[:HOSTED_ON]-
              (p:Package {name: {package}})-[:HAS_VERSION]->
              (v:Version {version: {version}})<-[:HAS_VERSION]-(p)
        MERGE (v)-[:HAS_AUTHOR]->(a:Author {name: {author}})
    ''')
      ..set('source', package.source)
      ..set('package', package.name)
      ..set('version', package.version.toString())
      ..set('author', author));
