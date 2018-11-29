import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:pkgraph/src/constants.dart';
import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/database/results.dart';
import 'package:pkgraph/src/database/retry.dart';

const commitEndpoint = '/db/data/transaction/commit';

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
  Future<Results> commit(
    Query query, {
    String endpoint = commitEndpoint,
  }) async {
    final client = HttpClient();

    final uri = Uri.parse('$baseUrl$commitEndpoint');

    String requestPayload;
    HttpClientResponse response;
    String responsePayload;
    dynamic responseJson;
    await runWithRetry(
      operation: () async {
        final request = await client.postUrl(uri);
        request.headers
          ..add('Accept', 'application/json; charset=utf-8')
          ..contentType = ContentType('application', 'json', charset: 'utf-8');
        requestPayload = json.encode(query.toJson());
        _logger.fine('request payload:\n$requestPayload');
        request.write(requestPayload);

        // TODO: This is an experiment because sometimes close() throws
        response = await request.close();
        _logger.fine('response status code: ${response.statusCode}');
        responsePayload = await response.transform(utf8.decoder).join();
        _logger.fine('response payload:\n$responsePayload');

        responseJson = json.decode(responsePayload);
      },
      retries: 5,
    );

    final results = Results.fromJson(responseJson);

    if (results.hasErrors) {
      throw DbException(
        request: requestPayload,
        response: responsePayload,
        statusCode: response.statusCode,
        uri: uri,
      );
    }

    _logger.info('successful response from $uri');

    return results;
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
