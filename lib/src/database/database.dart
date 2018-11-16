import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:pkgraph/src/database/query.dart';

const commitEndpoint = '/db/data/transaction/commit';
const defaultHost = 'localhost';
const defaultPort = 7474;

/// A database configuration that allows queries to be sent through
/// the transactional Cypher API.
///
/// TODO: Support for authentication
class Database {
  final String host;
  final bool https;
  final int port;

  Database({
    this.host: defaultHost,
    this.https: false,
    this.port: defaultPort,
  });

  String get baseUrl => 'http://$host:$port';

  Map<String, String> get headers => {
        'Accept': 'application/json; charset=UTF-8',
        'Content-Type': 'application/json',
      };

  /// Open and immediately commit a transaction with the given query.
  ///
  /// TODO: Handle failure more sensibly
  Future<bool> commit(
    Query query, {
    String endpoint: commitEndpoint,
  }) async {
    final response = await http.post(
      '$baseUrl$endpoint',
      body: query.toJson(),
      headers: headers,
    );
    return response.statusCode == 200;
  }
}
