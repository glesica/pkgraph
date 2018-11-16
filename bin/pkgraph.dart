import 'dart:async';
import 'dart:io';

import 'package:pkgraph/src/cypher/package.dart';
import 'package:pkgraph/src/database/database.dart';
import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/pub/fetch.dart';

List<String> workivaPackages = [
  'dart_dev',
//  'dart_to_js_script_rewriter',
//  'transformer_utils',
//  'fluri',
//  'over_react',
//  'platform_detect',
//  'r_tree',
//  'state_machine',
//  'w_common',
//  'w_flux',
//  'w_module',
//  'w_transport',
];

Future<void> main(List<String> arguments) async {
  final packageVersions = await fetchPackageVersions('state_machine');
  final database = Database();
  for (final packageVersion in packageVersions) {
    final query = Query()
      ..add(packageConstraintsStatement())
      ..add(packageVersionStatement(packageVersion))
      ..addAll(packageAuthorStatements(packageVersion));
    final success = await database.commit(query);
    if (!success) {
      exit(1);
    }
  }

  exit(0);
}
