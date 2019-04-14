import 'dart:io';
import 'dart:convert' show json;

import 'package:pkgraph/src/command_line/audit_args.dart';
import 'package:pkgraph/src/command_line/audit_config.dart';
import 'package:pkgraph/src/license/license_audit.dart';
import 'package:yaml/yaml.dart';

Future<void> main(List<String> args) async {
  final argResults = argParser.parse(args);
  final config = Config.fromArgResults(argResults);

  if (config.isHelp) {
    print('Usage: pkgraph:audit [options]\n');
    print('Create a software license report from a Dart package lock file.\n');
    print(argParser.usage);
    exit(0);
  }

  final jsonLockFile = loadLockFile(config.lockFilePath);
  final licenseAudit = LicenseAudit()..addFromLockFile(jsonLockFile);

  String output = '';
  if (config.preamble != '') {
    output += '${config.preamble}\n\n';
  }

  switch (config.outputFormat) {
    case OutputFormat.html:
      output += await licenseAudit.asHtml;
      break;
    case OutputFormat.json:
      output += json.encode(await licenseAudit.asJson);
      break;
    case OutputFormat.md:
      output += await licenseAudit.asMarkdown;
      break;
    case OutputFormat.txt:
      output += await licenseAudit.asText;
      break;
  }

  if (config.postamble != '') {
    output += '\n\n${config.postamble}';
  }

  print(output);
}

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
  return json.decode(json.encode(loadYaml(lockFileContent)));
}
