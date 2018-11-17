import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pkgraph/src/cypher/author.dart';

import 'package:pkgraph/src/cypher/package.dart';
import 'package:pkgraph/src/database/database.dart';
import 'package:pkgraph/src/database/query.dart';
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
  final constraintsSuccess = await database.commit(constraintsQuery);
  if (!constraintsSuccess) {
    exit(1);
  }

  final packageVersions = await fetchPackageVersions('state_machine');
  for (final packageVersion in packageVersions) {
    _logger.info('loading $packageVersion');
    final query = Query()
      ..add(packageVersionStatement(packageVersion))
      ..addAll(packageAuthorStatements(packageVersion));
    final success = await database.commit(query);
    if (!success) {
      exit(1);
    }
  }

  exit(0);
}
