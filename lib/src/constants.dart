import 'package:pub_semver/pub_semver.dart';

final dart1Versions = VersionConstraint.parse('^1.0.0');

final dart2Versions = VersionConstraint.parse('^2.0.0');

/// Default Neo4j server.
const defaultNeo4jServer = 'http://localhost:7474';

/// Default hosted package source.
const defaultSource = 'https://pub.dartlang.org';

/// The source we use for local package versions.
const localSource = 'local';
