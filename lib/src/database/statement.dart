import 'package:meta/meta.dart';

/// A single query that can be added to a request.
class Statement {
  /// Query parameters.
  final Map<String, dynamic> parameters = {};

  /// The actual query itself. It should contain parameters that match
  /// up with the parameters that have been set on the query or it will
  /// be rejected by the server.
  final String statement;

  Statement({@required this.statement});

  /// Retrieve a parameter value.
  dynamic operator [](String key) => parameters[key];

  /// Set a parameter value.
  void operator []=(String key, dynamic value) {
    parameters[key] = value;
  }

  void set(String key, dynamic value) => parameters[key] = value;

  Map<String, dynamic> toJson() {
    return {
      'statement': statement,
      'parameters': parameters,
    };
  }
}
