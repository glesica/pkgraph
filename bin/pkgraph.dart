import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/cypher/author.dart';
import 'package:pkgraph/src/cypher/package.dart';
import 'package:pkgraph/src/cypher/solved_dependencies.dart';
import 'package:pkgraph/src/database/database.dart';
import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/pub/cache.dart';
import 'package:pkgraph/src/pub/fetch.dart';
import 'package:pkgraph/src/pub/path_to_package_name.dart';

final _logger = Logger('pkgraph.dart');

Future<void> main(List<String> args) async {
  Logger.root.onRecord.listen((record) {
    stderr.writeln(record);
  });

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
  final argResults = argParser.parse(args);

  if (argResults['help']) {
    _printUsage(argParser.usage);
  }

  if (!argResults['local'] && argResults['solved']) {
    stderr.writeln('--solved flag requires --local\n');
    _printUsage(argParser.usage, 1);
  }

  // TODO: Remove after we handle special paths, this is just a quick hack
  if (argResults['local']) {
    argResults.rest.forEach((packagePath) {
      if (packagePath.endsWith('.')) {
        throw ArgumentError.value(
            packagePath, 'package path', 'Cannot use "." or ".."');
      }
    });
  }

  // Extract and transform

  for (final packageNameOrPath in argResults.rest) {
    await populatePackagesCache(
      packageNameOrPath,
      isLocalPackage: argResults['local'],
      source: argResults['source'],
    );
  }

  // Load

  final database = Database();
  final constraintsQuery = Query()
    ..add(authorConstraintStatement())
    ..add(sourceConstraintStatement());
  await database.commit(constraintsQuery);

  // Insert packages
  for (final packageVersion in defaultCache.all()) {
    _logger.info('loading versions for $packageVersion');
    final packageQuery = Query()..add(packageVersionStatement(packageVersion));
    await database.commit(packageQuery);
  }

  // Insert authors
  for (final packageVersion in defaultCache.all()) {
    _logger.info('loading authors for $packageVersion');
    final packageQuery = Query()
      ..addAll(packageAuthorStatements(packageVersion));
    await database.commit(packageQuery);
  }

  // Insert dependency relationships
  for (final packageVersion in defaultCache.all()) {
    _logger.info('loading dependencies for $packageVersion');
    final dependencyQuery = Query()
      ..addAll(packageDependenciesStatements(packageVersion));
    await database.commit(dependencyQuery);
  }

  // Insert solved dependency relationships if it was requested.
  if (argResults['solved']) {
    for (final packagePath in argResults.rest) {
      _logger.info('loading solved dependencies for $packagePath');

      final originPackageName = pathToPackageName(packagePath);
      final originPackageVersion = defaultCache
          .get(packageName: originPackageName, source: localSource)
          .first;

      // Make sure the local version of the package has been added
      // to the database so that we can add its solved relationships.
      final localPackageQuery = Query()
        ..add(packageVersionStatement(originPackageVersion));
      await database.commit(localPackageQuery);

      final solvedQuery = Query();
      for (final solvedDependency in fetchLocalSolvedPackages(packagePath)) {
        solvedQuery.add(solvedDependencyStatement(
          originPackageVersion,
          solvedDependency,
        ));
      }
      await database.commit(solvedQuery);
    }
  }

  exit(0);
}

void _printUsage(String usage, [int status = 0]) {
  assert(status != null);

  print(
    '''usage: pkgraph [options] <package names>

$usage

Note: the --solved flag requires the --local flag and that each
package path contains a correct pubspec.lock file in addition to
a pubspec.yaml file.

Examples:

Load the graph for the "foo" package
  pub run pkgraph foo

Load the graph for the "bar" package from a private pub server
  pub run pkgraph -s https://pub.mycompany.com bar

Load the graph for the "foo" and "bar" packages
  pub run pkgraph foo bar
      ''',
  );
  exit(status);
}
