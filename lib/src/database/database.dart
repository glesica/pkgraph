import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/database/retry.dart';

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
  /// TODO: Real response processing and error handling
  /// TODO: Should we re-use the HTTP client?
  Future<void> commit(
    Query query, {
    String endpoint = commitEndpoint,
  }) async {
    final client = HttpClient();

    final uri = Uri.parse('$baseUrl$commitEndpoint');
    _logger.info('using database at $uri');

    HttpClientRequest request;
    String requestPayload;
    await runWithRetry(
      operation: () async {
        request = await client.postUrl(uri);
        request.headers
          ..add('Accept', 'application/json; charset=utf-8')
          ..contentType = ContentType('application', 'json', charset: 'utf-8');
        requestPayload = json.encode(query.toJson());
        _logger.fine('request payload:\n$requestPayload');
        request.write(requestPayload);
      },
      retries: 5,
    );

    final response = await request.close();
    _logger.info('response status code: ${response.statusCode}');
    final responsePayload = await response.transform(utf8.decoder).join();
    _logger.fine('response payload:\n$responsePayload');
    final responseJson = json.decode(responsePayload);

    if (responseJson is! Map<String, dynamic> ||
        (responseJson['errors'] as List).isNotEmpty) {
      throw DbException(
        request: requestPayload,
        response: responsePayload,
        statusCode: response.statusCode,
        uri: uri,
      );
    }

    _logger.info('successful response from $uri');
  }
}

class DbException implements Exception {
  final String request;

  final String response;

  final int statusCode;

  final Uri uri;

  DbException({
    @required this.response,
    @required this.request,
    @required this.statusCode,
    @required this.uri,
  });

  @override
  String toString() =>
      'DbException ($statusCode from $uri)\n\nrequest:\n$request\n\nresponse:\n$response';
}
