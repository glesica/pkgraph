import 'dart:convert' show json;
import 'dart:io';

import 'package:yaml/yaml.dart';

Map loadLockFile(String filePath) {
  String lockFileContent;
  try {
    lockFileContent = File(filePath).readAsStringSync();
  } on FileSystemException catch (_) {
    stderr.writeln('Failed to load "$filePath", does it exist?');
    exit(1);
  }

  // This is stupid but it's the simplest way to shed all
  // the YAML type nonsense while we wait for them to get
  // rid of it altogether.
  final lockFileJson = json.decode(json.encode(loadYaml(lockFileContent)));

  // Ensure that the description contains the package name
  // even for path or git dependencies.
  lockFileJson['packages'].forEach((packageName, jsonDependency) {
    jsonDependency['description']['name'] = packageName;
  });

  return lockFileJson;
}
