import 'dart:io';
import 'dart:convert' show json;

import 'package:pkgraph/src/license/license_audit.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  final lockFile = File('pubspec.lock').readAsStringSync();

  final jsonValue = json.decode(json.encode(loadYaml(lockFile)));

  final licenseAudit = LicenseAudit();
  licenseAudit.addFromLockFile(jsonValue);
  print(await licenseAudit.asMarkdown);
}
