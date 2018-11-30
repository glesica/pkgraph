import 'dart:async';
import 'dart:io';

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

import 'args.dart';
import 'config.dart';

final _logger = Logger('pkgraph.dart');

Future<void> main(List<String> args) async {
  Logger.root.onRecord.listen((record) {
    stderr.writeln(record);
  });

  final argResults = argParser.parse(args);
  final config = Config.fromArgResults(argResults);

  if (config.isHelp) {
    _printUsage(argParser.usage);
  }

  if (!config.isLocal && config.isSolved) {
    stderr.writeln('--solved flag requires --local\n');
    _printUsage(argParser.usage, 1);
  }

  // TODO: Remove after we handle special paths, this is just a quick hack
  if (config.isLocal) {
    config.arguments.forEach((packagePath) {
      if (packagePath.endsWith('.')) {
        throw ArgumentError.value(
            packagePath, 'package path', 'Cannot use "." or ".."');
      }
    });
  }

  // Extract and transform

  for (final packageNameOrPath in config.arguments) {
    await populatePackagesCache(
      packageNameOrPath,
      isLocalPackage: config.isLocal,
      source: config.source,
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
  if (config.isSolved) {
    for (final packagePath in config.arguments) {
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
