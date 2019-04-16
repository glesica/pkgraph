import 'package:args/args.dart';

import 'package:pkgraph/src/constants.dart';

final argParser = ArgParser()
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Display help',
    negatable: false,
  )
  ..addFlag(
    'local',
    help: 'Treat package names as local paths',
    defaultsTo: false,
    negatable: false,
  )
  ..addOption(
    'neo4j-server',
    help: 'Neo4j server URL',
    defaultsTo: defaultNeo4jServer,
  )
  ..addOption(
    'neo4j-user',
    help: 'Neo4j username',
    defaultsTo: null,
  )
  ..addOption(
    'neo4j-pass',
    help: 'Neo4j password',
    defaultsTo: '',
  )
  ..addFlag(
    'solved',
    help: 'Augment graph with solved dependencies',
    defaultsTo: false,
    negatable: false,
  )
  ..addOption(
    'source',
    abbr: 's',
    help: 'Package source (pub server)',
    defaultsTo: defaultSource,
  );
