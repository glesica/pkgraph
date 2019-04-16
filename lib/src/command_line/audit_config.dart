import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

class Config {
  final bool isHelp;

  final String lockFilePath;

  final OutputFormat outputFormat;

  final String packagePath;

  final String postamble;

  final String preamble;

  final Iterable<String> sources;

  Config({
    @required this.isHelp,
    @required this.outputFormat,
    @required this.packagePath,
    @required postamble,
    @required preamble,
    @required this.sources,
  })  : lockFilePath = path.absolute(
          path.normalize(
            path.join(
              packagePath,
              'pubspec.lock',
            ),
          ),
        ),
        postamble = outputFormat == OutputFormat.json ? '' : postamble,
        preamble = outputFormat == OutputFormat.json ? '' : preamble;

  factory Config.fromArgResults(ArgResults results) => Config(
        isHelp: results['help'],
        outputFormat: stringToOutputFormat(results['format']),
        packagePath: results['package'],
        postamble: results['postamble'],
        preamble: results['preamble'],
        sources: results['sources'],
      );
}

enum OutputFormat {
  html,
  json,
  md,
  txt,
}

OutputFormat stringToOutputFormat(String format) {
  switch (format.toLowerCase()) {
    case 'html':
      return OutputFormat.html;
    case 'json':
      return OutputFormat.json;
    case 'md':
      return OutputFormat.md;
    case 'txt':
      return OutputFormat.txt;
    default:
      throw ArgumentError('Invalid output format: $format');
  }
}
