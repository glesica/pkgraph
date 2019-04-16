import 'dart:convert' show json;
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pkgraph/src/command_line/audit_args.dart';
import 'package:pkgraph/src/command_line/audit_config.dart';
import 'package:pkgraph/src/license/license_audit.dart';
import 'package:pkgraph/src/pub_api/load_lock_file.dart';

Future<void> main(List<String> args) async {
  Logger.root.onRecord.listen((record) {
    stderr.writeln(record);
  });

  final argResults = argParser.parse(args);
  final config = Config.fromArgResults(argResults);

  if (config.isHelp) {
    print('Usage: pkgraph:audit [options]\n');
    print('Create a software license report from a Dart package lock file.\n');
    print(argParser.usage);
    exit(0);
  }

  final jsonLockFile = loadLockFile(config.lockFilePath);
  final licenseAudit = LicenseAudit(
    sources: config.sources,
  )..addFromLockFile(jsonLockFile);

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
