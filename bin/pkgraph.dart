import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pkgraph/src/cypher/author.dart';

import 'package:pkgraph/src/cypher/package.dart';
import 'package:pkgraph/src/database/database.dart';
import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/pub/cache.dart';
import 'package:pkgraph/src/pub/fetch.dart';

final _logger = Logger('pkgraph.dart');

Future<void> main(List<String> arguments) async {
  Logger.root.onRecord.listen((record) {
    stderr.writeln(record);
  });

  final database = Database();

  final constraintsQuery = Query()
    ..add(authorConstraintStatement())
    ..add(sourceConstraintStatement());
  await database.commit(constraintsQuery);

  await populatePackagesCache('state_machine');

  for (final packageVersion in defaultCache.all()) {
    _logger.info('loading $packageVersion');
    final packageQuery = Query()
      ..add(packageVersionStatement(packageVersion))
      ..addAll(packageAuthorStatements(packageVersion));
    await database.commit(packageQuery);
  }

  for (final packageVersion in defaultCache.all()) {
    _logger.info('loading dependencies for $packageVersion');
    final dependencyQuery = Query()
      ..addAll(packageDependenciesStatements(packageVersion));
    await database.commit(dependencyQuery);
  }

  exit(0);
}
