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
    'neo4j-host',
    help: 'Neo4j host',
    defaultsTo: defaultHost,
    callback: (value) {
      // TODO: Remove once we honor this
      if (value != defaultHost) {
        throw ArgumentError('neo4j-host is not yet implemented');
      }
    },
  )
  ..addFlag(
    'neo4j-https',
    help: 'Use HTTPS to connect to Neo4j',
    defaultsTo: false,
    callback: (value) {
      // TODO: Remove once we honor this
      if (value != false) {
        throw ArgumentError('neo4j-https is not yet implemented');
      }
    },
    negatable: false,
  )
  ..addOption(
    'neo4j-port',
    help: 'Neo4j port',
    defaultsTo: defaultPort.toString(),
    callback: (value) {
      final parsedValue = int.tryParse(value);
      if (parsedValue == null || parsedValue < 1) {
        throw ArgumentError.value(
          value,
          'neo4j-port',
          'A positive integer is required',
        );
      }
      // TODO: Remove once we honor this
      if (value != defaultPort.toString()) {
        throw ArgumentError('neo4j-port is not yet implemented');
      }
    },
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
