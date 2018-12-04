import 'package:args/args.dart';
import 'package:meta/meta.dart';

class Config {
  final Iterable<String> arguments;

  final bool isHelp;

  final bool isLocal;

  final bool isSolved;

  final String neo4jHost;

  final bool neo4jHttps;

  final int neo4jPort;

  final String source;

  Config({
    @required this.arguments,
    @required this.isHelp,
    @required this.isLocal,
    @required this.isSolved,
    @required this.neo4jHost,
    @required this.neo4jHttps,
    @required this.neo4jPort,
    @required this.source,
  });

  factory Config.fromArgResults(ArgResults results) => Config(
    arguments: results.rest,
    isHelp: results['help'],
    isLocal: results['local'],
    isSolved: results['solved'],
    neo4jHost: results['neo4jHost'],
    neo4jHttps: results['neo4jHttps'],
    neo4jPort: int.parse(results['neo4jPort']),
    source: results['source'],
  );
}
