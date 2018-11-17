import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:logging/logging.dart';

import 'package:pkgraph/src/database/query.dart';

const commitEndpoint = '/db/data/transaction/commit';
const defaultHost = 'localhost';
const defaultPort = 7474;

final _logger = Logger('database.dart');

/// A database configuration that allows queries to be sent through
/// the transactional Cypher API.
///
/// TODO: Support for authentication
class Database {
  final String host;
  final bool https;
  final int port;

  Database({
    this.host = defaultHost,
    this.https = false,
    this.port = defaultPort,
  });

  String get baseUrl => '${https ? 'https' : 'http'}://$host:$port';

  /// Open and immediately commit a transaction with the given query.
  ///
  /// TODO: Handle failure more sensibly
  /// TODO: Should we re-use the HTTP client?
  Future<bool> commit(
    Query query, {
    String endpoint = commitEndpoint,
  }) async {
    final client = HttpClient();

    final uri = Uri.parse('$baseUrl$commitEndpoint');
    _logger.info('uri $uri');

    final request = await client.postUrl(uri);
    request.headers
      ..add('Accept', 'application/json; charset=utf-8')
      ..contentType = ContentType('application', 'json', charset: 'utf-8');
    request.write(json.encode(query.toJson()));

    final response = await request.close();
    _logger.info('status ${response.statusCode}');

    final responseBody =
        await response.transform(utf8.decoder).transform(json.decoder).join();
    _logger.info('$responseBody');

    return response.statusCode == 200;
  }
}
