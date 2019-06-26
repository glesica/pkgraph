import 'dart:async';
import 'dart:convert' show json, utf8, base64;
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pkgraph/src/database/query.dart';
import 'package:pkgraph/src/database/retry.dart';

const commitEndpoint = '/db/data/transaction/commit';

final _logger = Logger('database.dart');

/// A database configuration that allows queries to be sent through
/// the transactional Cypher API.
class Database {
  final String password;
  final Uri server;
  final String username;

  Database({
    @required this.server,
    this.password = '',
    this.username,
  }) : assert(password != null);

  /// Open and immediately commit a transaction with the given query.
  ///
  /// TODO: Real response processing and error handling
  /// TODO: Should we re-use the HTTP client?
  Future<void> commit(
    Query query, {
    String endpoint = commitEndpoint,
  }) async {
    final client = HttpClient();

    final uri = server.resolve(commitEndpoint);

    String requestPayload;
    HttpClientResponse response;
    String responsePayload;
    dynamic responseJson;
    await runWithRetry(
      operation: () async {
        final request = await client.postUrl(uri);
        _setHeaders(request.headers);
        requestPayload = json.encode(query.toJson());
        _logger.fine('request payload:\n$requestPayload');
        request.write(requestPayload);

        response = await request.close();
        _logger.fine('response status code: ${response.statusCode}');
        responsePayload =
            await response.cast<List<int>>().transform(utf8.decoder).join();
        _logger.fine('response payload:\n$responsePayload');

        responseJson = json.decode(responsePayload);
      },
      retries: 5,
    );

    if (responseJson is! Map<String, dynamic> ||
        (responseJson['errors'] as List).isNotEmpty) {
      throw DbException(
        request: requestPayload,
        response: responsePayload,
        statusCode: response.statusCode,
        uri: uri,
      );
    }
  }

  void _setHeaders(HttpHeaders headers) {
    headers
      ..add('Accept', 'application/json; charset=utf-8')
      ..contentType = ContentType('application', 'json', charset: 'utf-8');

    if (username != null) {
      final bytes = utf8.encode('$username:$password');
      final token = base64.encode(bytes);
      headers.add('Authorization', 'Basic $token');
    }
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
