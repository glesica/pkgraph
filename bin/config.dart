import 'package:args/args.dart';
import 'package:meta/meta.dart';

class Config {
  final Iterable<String> arguments;

  final bool isHelp;

  final bool isLocal;

  final bool isSolved;

  final String neo4jPass;

  final Uri neo4jServer;

  final String neo4jUser;

  final String source;

  Config({
    @required this.arguments,
    @required this.isHelp,
    @required this.isLocal,
    @required this.isSolved,
    @required this.neo4jPass,
    @required this.neo4jServer,
    @required this.neo4jUser,
    @required this.source,
  });

  factory Config.fromArgResults(ArgResults results) {
    return Config(
    arguments: results.rest,
    isHelp: results['help'],
    isLocal: results['local'],
    isSolved: results['solved'],
    neo4jPass: results['neo4j-pass'],
    neo4jServer: Uri.parse(results['neo4j-server']),
    neo4jUser: results['neo4j-user'],
    source: results['source'],
  );
  }
}
