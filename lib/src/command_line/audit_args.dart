import 'package:args/args.dart';

const defaultPackage = '.';

final argParser = ArgParser(usageLineLength: 80)
  ..addOption(
    'format',
    abbr: 'f',
    help: 'Output format (html, json, md, txt)',
    allowed: const ['html', 'json', 'md', 'txt'],
    defaultsTo: 'txt',
    valueHelp: 'FORMAT',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Display help',
    negatable: false,
  )
  ..addOption(
    'lock-file',
    abbr: 'l',
    help: 'File name of the lock file',
    defaultsTo: 'pubspec.lock',
    valueHelp: 'NAME',
  )
  ..addOption(
    'package',
    abbr: 'p',
    help: 'Path to package to be scanned',
    defaultsTo: defaultPackage,
    valueHelp: 'PATH',
  )
  ..addOption(
    'postamble',
    abbr: 'z',
    help: 'Text to include at the end of the report (html, md, txt)',
    defaultsTo: '',
    valueHelp: 'TEXT',
  )
  ..addOption(
    'preamble',
    abbr: 'a',
    help: 'Text to include at the beginning of the report (html, md, txt)',
    defaultsTo: '',
    valueHelp: 'TEXT',
  );
