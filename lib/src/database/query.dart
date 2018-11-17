import 'package:pkgraph/src/database/statement.dart';

class Query {
  final List<Statement> _statements = [];

  Iterable<Statement> get statements => _statements;

  void add(Statement statement) {
    _statements.add(statement);
  }

  void addAll(Iterable<Statement> statements) {
    _statements.addAll(statements);
  }

  Map<String, dynamic> toJson() {
    return {"statements": _statements.map((s) => s.toJson()).toList()};
  }
}
